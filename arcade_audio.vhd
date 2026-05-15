library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity arcade_audio is
    port (
        clk      : in  std_logic; -- 50 MHz
        reset    : in  std_logic;
        audio_out: out std_logic
    );
end arcade_audio;

architecture arch of arcade_audio is
    constant CLK_FREQ : integer := 50000000;
    
    -- Frecuencias (Hz)
    constant NOTE_E5 : integer := 659;
    constant NOTE_C5 : integer := 523;
    constant NOTE_G5 : integer := 784;
    constant NOTE_G4 : integer := 392;
    constant NOTE_REST : integer := 0;

    type note_array is array (0 to 11) of integer;
    constant MELODY : note_array := (
        NOTE_E5, NOTE_E5, NOTE_REST, NOTE_E5, NOTE_REST, NOTE_C5, 
        NOTE_E5, NOTE_REST, NOTE_G5, NOTE_REST, NOTE_G4, NOTE_REST
    );

    signal note_index : integer range 0 to 11 := 0;
    signal note_timer : integer range 0 to CLK_FREQ/4 := 0; -- 250ms por nota
    
    signal freq_counter : integer := 0;
    signal freq_limit   : integer := 0;
    signal square_wave  : std_logic := '0';

begin

    process(clk, reset)
    begin
        if reset = '1' then
            note_index <= 0;
            note_timer <= 0;
            freq_limit <= 0;
        elsif rising_edge(clk) then
            -- Temporizador de notas (cambia cada 150ms aprox)
            if note_timer = CLK_FREQ/8 then 
                note_timer <= 0;
                if note_index = 11 then
                    note_index <= 0;
                else
                    note_index <= note_index + 1;
                end if;
            else
                note_timer <= note_timer + 1;
            end if;

            -- Convertir frecuencia de nota a límite de contador
            -- limite = CLK_FREQ / (2 * freq)
            if MELODY(note_index) = 0 then
                freq_limit <= 0;
            else
                freq_limit <= CLK_FREQ / (2 * MELODY(note_index));
            end if;

            -- Generador de onda cuadrada
            if freq_limit = 0 then
                square_wave <= '0';
                freq_counter <= 0;
            else
                if freq_counter >= freq_limit then
                    freq_counter <= 0;
                    square_wave <= not square_wave;
                else
                    freq_counter <= freq_counter + 1;
                end if;
            end if;
        end if;
    end process;

    audio_out <= square_wave;

end arch;
