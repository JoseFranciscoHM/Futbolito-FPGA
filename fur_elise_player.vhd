library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fur_elise_player is
    port (
        clk      : in  std_logic; -- 50 MHz
        reset    : in  std_logic;
        audio_out: out std_logic
    );
end fur_elise_player;

architecture arch of fur_elise_player is
    constant CLK_FREQ : integer := 50000000;
    constant WHOLENOTE_MS : integer := 3000;

    -- Frecuencias (Hz)
    constant NOTE_B4  : integer := 494;
    constant NOTE_C4  : integer := 262;
    constant NOTE_E4  : integer := 330;
    constant NOTE_GS4 : integer := 415;
    constant NOTE_A4  : integer := 440;
    constant NOTE_C5  : integer := 523;
    constant NOTE_D5  : integer := 587;
    constant NOTE_DS5 : integer := 622;
    constant NOTE_E5  : integer := 659;
    constant NOTE_G4  : integer := 392;
    constant NOTE_F4  : integer := 349;
    constant NOTE_F5  : integer := 698;
    constant NOTE_E6  : integer := 1319;
    constant REST     : integer := 0;

    type int_array is array (0 to 39) of integer;
    
    constant MELODY_NOTES : int_array := (
        NOTE_E5, NOTE_DS5, NOTE_E5, NOTE_DS5, NOTE_E5, NOTE_B4, NOTE_D5, NOTE_C5, 
        NOTE_A4, NOTE_C4, NOTE_E4, NOTE_A4, 
        NOTE_B4, NOTE_E4, NOTE_GS4, NOTE_B4, 
        NOTE_C5, REST, NOTE_E4, NOTE_E5, NOTE_DS5, 
        NOTE_E5, NOTE_DS5, NOTE_E5, NOTE_B4, NOTE_D5, NOTE_C5, 
        NOTE_A4, NOTE_C4, NOTE_E4, NOTE_A4, 
        NOTE_B4, NOTE_E4, NOTE_C5, NOTE_B4, 
        NOTE_A4, REST, NOTE_E5, NOTE_DS5, NOTE_E5 
    );

    constant MELODY_DIV : int_array := (
        16, 16, 16, 16, 16, 16, 16, 16, 
        -8, 16, 16, 16, 
        -8, 16, 16, 16, 
        8, 16, 16, 16, 16, 
        16, 16, 16, 16, 16, 16,
        -8, 16, 16, 16,
        -8, 16, 16, 16,
        4, 8, 16, 16, 16
    );

    signal note_index : integer range 0 to 39 := 0;
    signal timer_ticks : unsigned(31 downto 0) := (others => '0');
    signal duration_ticks : unsigned(31 downto 0) := (others => '0');
    
    signal freq_counter : unsigned(31 downto 0) := (others => '0');
    signal freq_limit   : unsigned(31 downto 0) := (others => '0');
    signal square_wave  : std_logic := '0';

begin

    process(clk, reset)
        variable current_div : integer;
        variable duration_ms : integer;
        variable current_freq : integer;
    begin
        if reset = '1' then
            note_index <= 0;
            timer_ticks <= (others => '0');
            freq_limit <= (others => '0');
            duration_ticks <= to_unsigned(1000000, 32); -- Pequeño delay inicial
        elsif rising_edge(clk) then
            
            -- Lógica de temporización de notas
            if timer_ticks >= duration_ticks then
                timer_ticks <= (others => '0');
                
                -- Siguiente nota
                if note_index = 39 then
                    note_index <= 0;
                else
                    note_index <= note_index + 1;
                end if;

                -- Calcular nueva duración
                current_div := MELODY_DIV(note_index);
                if current_div > 0 then
                    duration_ms := WHOLENOTE_MS / current_div;
                else
                    duration_ms := (WHOLENOTE_MS * 3) / (abs(current_div) * 2);
                end if;
                duration_ticks <= to_unsigned( (CLK_FREQ / 1000) * duration_ms, 32);

            else
                timer_ticks <= timer_ticks + 1;
            end if;

            -- Generador de tono
            current_freq := MELODY_NOTES(note_index);
            
            -- Silencio del 10% al final de la nota
            if (current_freq = 0) or (timer_ticks > (duration_ticks * 9 / 10)) then
                freq_limit <= (others => '0');
            else
                freq_limit <= to_unsigned(CLK_FREQ / (2 * current_freq), 32);
            end if;

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
