library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Mario_Theme is
    generic(
        SAMPLE_RATE : natural := 48 -- in KHz
    );
    port(
        clock : in std_logic; -- Audio clock (e.g. 48kHz)
        reset : in std_logic;
        freq  : out std_logic_vector(15 downto 0)
    );
end entity;

architecture behavior of Mario_Theme is
    -- Frequencies in Hz
    constant E5 : unsigned(15 downto 0) := to_unsigned(659, 16);
    constant C5 : unsigned(15 downto 0) := to_unsigned(523, 16);
    constant G5 : unsigned(15 downto 0) := to_unsigned(784, 16);
    constant G4 : unsigned(15 downto 0) := to_unsigned(392, 16);
    constant REST : unsigned(15 downto 0) := to_unsigned(0, 16);

    type note_array is array (0 to 11) of unsigned(15 downto 0);
    constant MELODY : note_array := (
        E5, E5, REST, E5, REST, C5, E5, REST, G5, REST, G4, REST
    );

    -- Duration of each note in samples
    -- 48000 / 8 = 6000 samples for 1/8 note at 120 BPM? 
    -- Let's say 150ms per step. 0.15 * 48000 = 7200 samples.
    constant STEP_DURATION : natural := 24000; 

    signal sample_cnt : natural range 0 to STEP_DURATION := 0;
    signal note_index : natural range 0 to 11 := 0;

begin
    process(clock, reset)
    begin
        if reset = '1' then
            sample_cnt <= 0;
            note_index <= 0;
            freq <= (others => '0');
        elsif rising_edge(clock) then
            if sample_cnt < STEP_DURATION then
                sample_cnt <= sample_cnt + 1;
            else
                sample_cnt <= 0;
                if note_index < 11 then
                    note_index <= note_index + 1;
                else
                    note_index <= 0;
                end if;
            end if;
            freq <= std_logic_vector(MELODY(note_index));
        end if;
    end process;

end architecture;
