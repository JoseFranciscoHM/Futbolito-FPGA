library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Wavetable is
   generic(
      SAMPLE_RATE	:  natural := 48 -- in KHz
   );
	port(	clock : in std_logic;
		reset : IN std_logic;
		waveform_type : in std_logic := '0';
		freq : in std_logic_vector(15 downto 0);
		wave : out signed(15 downto 0)
		);
end entity;

architecture modulo_64 of Wavetable is
	constant WAVETABLE_SIZE : natural := 64;
	constant base_factor : natural := (WAVETABLE_SIZE * (2**12)) / (SAMPLE_RATE * 1000);
	signal pointer : unsigned(17 downto 0);
	signal step : unsigned(17 downto 0);

	type wave_table is array (0 to 63) of signed(15 downto 0);
	constant Sine: wave_table := --Sine wave
     (x"0000", x"0645", x"0C7C", x"1294", x"187D", x"1E2B", x"238E", x"2899",
		x"2D41", x"3179", x"3536", x"3871", x"3B20", x"3D3E", x"3EC5", x"3FB1", 
		x"4000", x"3FB1", x"3EC5", x"3D3E", x"3B20", x"3871", x"3536", x"3179", 
		x"2D41", x"2899", x"238E", x"1E2B", x"187D", x"1294", x"0C7C", x"0645", 
		x"0000", x"F9BB", x"F384", x"ED6C", x"E783", x"E1D5", x"DC72", x"D767", 
		x"D2BF", x"CE87", x"CACA", x"C78F", x"C4E0", x"C2C2", x"C13B", x"C04F", 
		x"C000", x"C04F", x"C13B", x"C2C2", x"C4E0", x"C78F", x"CACA", x"CE87", 
		x"D2BF", x"D767", x"DC72", x"E1D5", x"E783", x"ED6C", x"F384", x"F9BB"
		);
	constant Square: wave_table := --Square wave
     (x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", 
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000",
		x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", x"0000", 
		x"1FFF", x"1FFF", x"1FFF", x"1FFF", x"1FFF", x"1FFF", x"1FFF", x"1FFF", 
		x"1FFF", x"1FFF", x"1FFF", x"1FFF", x"1FFF", x"1FFF", x"1FFF", x"1FFF",
		x"1FFF", x"1FFF", x"1FFF", x"1FFF", x"1FFF", x"1FFF", x"1FFF", x"1FFF",
		x"1FFF", x"1FFF", x"1FFF", x"1FFF", x"1FFF", x"1FFF", x"1FFF", x"1FFF"
		);
begin	
	assert (SAMPLE_RATE = 8 or SAMPLE_RATE = 32 or
				SAMPLE_RATE = 48 or SAMPLE_RATE = 96)
      	report "The selected sample rate was not supported."
	severity error;

	step <= resize(unsigned("00" & freq) * base_factor, 18);

	-------------------------------------------------------
	--Wavetable Synthesizer
	-------------------------------------------------------
	Wave_Synth: process(clock, reset) is
	begin
		if(reset = '1') then
			pointer <= to_unsigned(0, 18);
		elsif(clock'event and clock = '0') then
			pointer <= pointer + unsigned(step);	
			
			if(waveform_type = '0') then
			   wave <= sine(to_integer(pointer(17 downto 12)));
			else
			   wave <= square(to_integer(pointer(17 downto 12)));
			end if;
		end if;
	end process;
end modulo_64;
