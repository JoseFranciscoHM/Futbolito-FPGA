library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity background_music is
    port (
        clk      : in  std_logic; -- 50 MHz
        reset    : in  std_logic;
        audio_out: out std_logic
    );
end background_music;

architecture arch of background_music is
    constant CLK_FREQ : integer := 50000000;
    constant WHOLENOTE_MS : integer := 2400; -- (60000 * 4) / 100 (tempo 100)

    -- Definición de Notas
    constant NOTE_C4  : integer := 262;
    constant NOTE_D4  : integer := 294;
    constant NOTE_E4  : integer := 330;
    constant NOTE_F4  : integer := 349;
    constant NOTE_FS4 : integer := 370;
    constant NOTE_G4  : integer := 392;
    constant NOTE_GS4 : integer := 415;
    constant NOTE_A4  : integer := 440;
    constant NOTE_AS4 : integer := 466;
    constant NOTE_B4  : integer := 494;
    constant NOTE_C5  : integer := 523;
    constant NOTE_CS5 : integer := 554;
    constant NOTE_D5  : integer := 587;
    constant NOTE_DS5 : integer := 622;
    constant NOTE_E5  : integer := 659;
    constant NOTE_F5  : integer := 698;
    constant NOTE_FS5 : integer := 740;
    constant NOTE_G5  : integer := 784;
    constant NOTE_GS5 : integer := 831;
    constant NOTE_A5  : integer := 880;
    constant NOTE_AS5 : integer := 932;
    constant NOTE_B5  : integer := 988;
    constant REST     : integer := 0;

    type int_array is array (0 to 117) of integer;
    
    constant MELODY_NOTES : int_array := (
        NOTE_C5, NOTE_G4, NOTE_AS4, NOTE_A4, NOTE_G4, NOTE_C4, NOTE_C4, NOTE_G4, NOTE_G4, NOTE_G4,
        NOTE_C5, NOTE_G4, NOTE_AS4, NOTE_A4, NOTE_G4,
        NOTE_C5, NOTE_G4, NOTE_AS4, NOTE_A4, NOTE_G4, NOTE_C4, NOTE_C4, NOTE_G4, NOTE_G4, NOTE_G4,
        NOTE_F4, NOTE_E4, NOTE_D4, NOTE_C4, NOTE_C4,
        NOTE_C5, NOTE_G4, NOTE_AS4, NOTE_A4, NOTE_G4, NOTE_C4, NOTE_C4, NOTE_G4, NOTE_G4, NOTE_G4,
        NOTE_C5, NOTE_G4, NOTE_AS4, NOTE_A4, NOTE_G4,
        NOTE_C5, NOTE_G4, NOTE_AS4, NOTE_A4, NOTE_G4, NOTE_C4, NOTE_C4, NOTE_G4, NOTE_G4, NOTE_G4,
        NOTE_F4, NOTE_E4, NOTE_D4, NOTE_C4, NOTE_C4, NOTE_D5, NOTE_D5, NOTE_D5, NOTE_D5, NOTE_D5,
        NOTE_D5, NOTE_D5, NOTE_D5, NOTE_C5, NOTE_E5, NOTE_C5, NOTE_C5, NOTE_E5, NOTE_E5, NOTE_C5,
        NOTE_F5, NOTE_D5, NOTE_D5, NOTE_E5, NOTE_C5, NOTE_D5, NOTE_E5, NOTE_D5, NOTE_C5, NOTE_F5,
        NOTE_F5, NOTE_A5, NOTE_G5, NOTE_G5, NOTE_C5, NOTE_C5, NOTE_C5, NOTE_C5, NOTE_F5, NOTE_E5,
        NOTE_D5, NOTE_C5, NOTE_C5, NOTE_C5, NOTE_C5, NOTE_C5, NOTE_F5, NOTE_F5, NOTE_A5, NOTE_G5,
        NOTE_G5, NOTE_C5, NOTE_C5, NOTE_C5, NOTE_C5, NOTE_F5, NOTE_E5, NOTE_D5, NOTE_C5, NOTE_G4, 
        NOTE_AS4, NOTE_A4, NOTE_G4
    );

    constant MELODY_DIV : int_array := (
        4, 8, 4, 8, 16, 8, 16, 16, 8, 16,
        4, 8, 4, 8, 2,
        4, 8, 4, 8, 16, 8, 16, 16, 8, 16,
        8, 8, 8, 8, 2,
        4, 8, 4, 8, 16, 8, 16, 16, 8, 16,
        4, 8, 4, 8, 2,
        4, 8, 4, 8, 16, 8, 16, 16, 8, 16,
        8, 8, 8, 8, 16, 8, 8, 16, 16, 8,
        16, 16, 8, 16, 8, -8, 8, 16, 16, 8,
        16, 8, 8, 8, -8, 8, 16, 16, 8, 16,
        8, 8, 8, -8, 8, 16, 16, 8, 16, 16, 
        8, 16, 8, -8, 8, 16, 16, 8, 16, 16, 
        8, 16, 8, 4, 8, 4, 8, 16, 8, 16, 
        4, 8, 2
    );

    signal note_index : integer range 0 to 117 := 0;
    signal timer_ticks : unsigned(31 downto 0) := (others => '0');
    signal duration_ticks : unsigned(31 downto 0) := (others => '0');
    signal freq_counter : unsigned(31 downto 0) := (others => '0');
    signal freq_limit   : unsigned(31 downto 0) := (others => '0');
    signal square_wave  : std_logic := '0';

begin

    process(clk, reset)
        variable current_div : integer;
        variable duration_ms : integer;
    begin
        if reset = '1' then
            note_index <= 0;
            timer_ticks <= (others => '0');
            duration_ticks <= to_unsigned(CLK_FREQ/100, 32);
        elsif rising_edge(clk) then
            if timer_ticks >= duration_ticks then
                timer_ticks <= (others => '0');
                if note_index = 117 then note_index <= 0; else note_index <= note_index + 1; end if;
                
                current_div := MELODY_DIV(note_index);
                if current_div > 0 then
                    duration_ms := WHOLENOTE_MS / current_div;
                else
                    duration_ms := (WHOLENOTE_MS * 3) / (abs(current_div) * 2);
                end if;
                duration_ticks <= to_unsigned((CLK_FREQ/1000) * duration_ms, 32);
            else
                timer_ticks <= timer_ticks + 1;
            end if;

            if (MELODY_NOTES(note_index) = 0) or (timer_ticks > (duration_ticks * 9 / 10)) then
                freq_limit <= (others => '0');
            else
                freq_limit <= to_unsigned(CLK_FREQ / (2 * MELODY_NOTES(note_index)), 32);
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
