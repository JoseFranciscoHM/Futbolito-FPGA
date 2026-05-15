library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity goal_sfx_player is
    port (
        clk       : in  std_logic; -- 50 MHz
        reset     : in  std_logic;
        trigger   : in  std_logic; -- Pulso para iniciar el sonido
        audio_out : out std_logic;
        busy      : out std_logic  -- '1' mientras el sonido se está reproduciendo
    );
end goal_sfx_player;

architecture arch of goal_sfx_player is
    constant CLK_FREQ : integer := 50000000;
    
    signal timer       : unsigned(31 downto 0) := (others => '0');
    signal freq_limit  : unsigned(31 downto 0) := (others => '0');
    signal freq_counter: unsigned(31 downto 0) := (others => '0');
    signal square_wave : std_logic := '0';
    
    signal active      : std_logic := '0';
    signal current_pitch: integer := 440;

begin

    process(clk, reset)
    begin
        if reset = '1' then
            active <= '0';
            timer <= (others => '0');
            busy <= '0';
        elsif rising_edge(clk) then
            
            if trigger = '1' and active = '0' then
                active <= '1';
                timer <= (others => '0');
                current_pitch <= 400; -- Frecuencia inicial
            end if;

            if active = '1' then
                busy <= '1';
                timer <= timer + 1;
                
                -- Efecto de sonido: Subir frecuencia cada 2ms
                if timer(16 downto 0) = (16 downto 0 => '0') then 
                    current_pitch <= current_pitch + 20;
                end if;

                -- Duración del efecto: ~1.5 segundos
                if timer > (CLK_FREQ * 15 / 10) then
                    active <= '0';
                end if;
                
                -- Generador de onda cuadrada
                freq_limit <= to_unsigned(CLK_FREQ / (2 * current_pitch), 32);
            else
                busy <= '0';
                freq_limit <= (others => '0');
            end if;

            -- Generación de la onda
            if freq_limit = 0 then
                square_wave <= '0';
                freq_counter <= (others => '0');
            else
                if freq_counter >= freq_limit then
                    freq_counter <= (others => '0');
                    square_wave <= not square_wave;
                else
                    freq_counter <= freq_counter + 1;
                end if;
            end if;
        end if;
    end process;

    audio_out <= square_wave;

end arch;
