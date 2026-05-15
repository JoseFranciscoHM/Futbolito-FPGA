library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dfplayer_ctrl is
    port (
        clk      : in  std_logic; -- 50 MHz
        reset_n  : in  std_logic;
        play_req : in  std_logic; -- Pulso para iniciar envío
        cmd      : in  std_logic_vector(7 downto 0); -- Comando DFPlayer
        param_h  : in  std_logic_vector(7 downto 0); -- Parámetro Alto
        param_l  : in  std_logic_vector(7 downto 0); -- Parámetro Bajo
        uart_tx  : out std_logic
    );
end dfplayer_ctrl;

architecture arch of dfplayer_ctrl is
    constant CLK_FREQ  : integer := 50000000;
    constant BAUD_RATE : integer := 9600;
    constant BIT_TIME  : integer := CLK_FREQ / BAUD_RATE;

    type state_type is (IDLE, START_BYTE, SEND_BYTE, STOP_BIT, DELAY);
    signal state : state_type := IDLE;

    -- Trama DFPlayer: 7E FF 06 03 00 00 XX FE YY EF
    -- XX = Track, YY = Checksum (FE YY)
    type packet_type is array (0 to 9) of std_logic_vector(7 downto 0);
    signal packet : packet_type;
    
    signal byte_idx : integer range 0 to 9 := 0;
    signal bit_idx  : integer range 0 to 7 := 0;
    signal counter  : integer range 0 to BIT_TIME * 101 := 0;
    signal current_byte : std_logic_vector(7 downto 0);

begin

    process(clk, reset_n)
        variable sum : unsigned(15 downto 0);
        variable checksum : unsigned(15 downto 0);
    begin
        if reset_n = '0' then
            state <= IDLE;
            uart_tx <= '1';
            byte_idx <= 0;
            counter <= 0;
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    uart_tx <= '1';
                    if play_req = '1' then
                        -- Preparar paquete
                        packet(0) <= x"7E"; -- Start
                        packet(1) <= x"FF"; -- Version
                        packet(2) <= x"06"; -- Length
                        packet(3) <= cmd;   -- Command
                        packet(4) <= x"00"; -- Feedback
                        packet(5) <= param_h; -- Parameter High
                        packet(6) <= param_l; -- Parameter Low
                        
                        -- Checksum = 0 - (Sum of bytes 1 to 6)
                        -- IMPORTANTE: Usar los valores de entrada directamente,
                        -- NO los signals packet() que aun no se han actualizado
                        sum := resize(unsigned(std_logic_vector'(x"FF")), 16) +
                               resize(unsigned(std_logic_vector'(x"06")), 16) +
                               resize(unsigned(cmd), 16) +
                               resize(unsigned(std_logic_vector'(x"00")), 16) +
                               resize(unsigned(param_h), 16) +
                               resize(unsigned(param_l), 16);
                        checksum := unsigned(not std_logic_vector(sum)) + 1;
                        
                        packet(7) <= std_logic_vector(checksum(15 downto 8));
                        packet(8) <= std_logic_vector(checksum(7 downto 0));
                        packet(9) <= x"EF"; -- End
                        
                        byte_idx <= 0;
                        state <= START_BYTE;
                        counter <= 0;
                    end if;

                when START_BYTE =>
                    uart_tx <= '0'; -- Start bit
                    if counter = BIT_TIME - 1 then
                        counter <= 0;
                        current_byte <= packet(byte_idx);
                        bit_idx <= 0;
                        state <= SEND_BYTE;
                    else
                        counter <= counter + 1;
                    end if;

                when SEND_BYTE =>
                    uart_tx <= current_byte(bit_idx);
                    if counter = BIT_TIME - 1 then
                        counter <= 0;
                        if bit_idx = 7 then
                            state <= STOP_BIT;
                        else
                            bit_idx <= bit_idx + 1;
                        end if;
                    else
                        counter <= counter + 1;
                    end if;

                when STOP_BIT =>
                    uart_tx <= '1'; -- Stop bit
                    if counter = BIT_TIME - 1 then
                        counter <= 0;
                        if byte_idx = 9 then
                            state <= DELAY;
                        else
                            byte_idx <= byte_idx + 1;
                            state <= START_BYTE;
                        end if;
                    else
                        counter <= counter + 1;
                    end if;
                
                when DELAY =>
                    uart_tx <= '1';
                    if counter = BIT_TIME * 100 then -- Pequeña pausa entre comandos
                        state <= IDLE;
                    else
                        counter <= counter + 1;
                    end if;
            end case;
        end if;
    end process;

end arch;
