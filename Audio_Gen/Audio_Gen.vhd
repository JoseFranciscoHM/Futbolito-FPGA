library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Audio_Gen is
	port(	
		CLOCK_50 : in std_logic;
		SW : in std_logic_vector(17 downto 0);
		KEY : in std_logic_vector(3 downto 0);
		I2C_SCLK : out std_logic;
		I2C_SDAT : inout std_logic;
		AUD_XCK : buffer std_logic;
		AUD_BCLK : inout std_logic;
		AUD_ADCLRCK : out std_logic;
		AUD_ADCDAT : in std_logic;
		AUD_DACLRCK : buffer std_logic;
		AUD_DACDAT : out std_logic
		);
end;

architecture Audio_Test of Audio_Gen is
	signal Lin, Rout : signed(15 downto 0);
	signal wave1, wave2, wave_sum : signed(15 downto 0);
	signal freq1, freq2 : std_logic_vector(15 downto 0);
	signal mario_freq : std_logic_vector(15 downto 0);
	signal mario_wave : signed(15 downto 0);
	signal rand_LFSR, rand_LCG : std_logic_vector(31 downto 0);

begin
	-- Frequency calculation: Base 200Hz + (Switch Value * 8)
	-- If switches are 0, use defaults (440Hz and 267Hz)
	freq1 <= "0000000110111000" when SW(15 downto 8) = "00000000" else 
	         std_logic_vector(to_unsigned(200 + to_integer(unsigned(SW(15 downto 8))) * 8, 16));
	
	freq2 <= "0000000100001011" when SW(7 downto 0) = "00000000" else 
	         std_logic_vector(to_unsigned(200 + to_integer(unsigned(SW(7 downto 0))) * 8, 16));

	wave_sum <= resize(wave1 / 2, 16) + resize(wave2 / 2, 16);

	Rout <= 	mario_wave when SW(17) = '1' else
				wave_sum   when SW(16) = '1' else
				wave1;
Line_Echo: -- Keep this for now just in case
	Lin <= Rout; 

	Waveform_Synth_1: entity work.Wavetable
	generic map (
		SAMPLE_RATE => 48 --in KHz
		)
	port map(	
		clock => AUD_DACLRCK,
		reset => not key(0),
		waveform_type => '0', -- Sine
		freq => freq1,
		wave => wave1
		);

	Waveform_Synth_2: entity work.Wavetable
	generic map (
		SAMPLE_RATE => 48 --in KHz
		)
	port map(	
		clock => AUD_DACLRCK,
		reset => not key(0),
		waveform_type => '0', -- Sine
		freq => freq2,
		wave => wave2
		);

	Mario_Theme_Inst: entity work.Mario_Theme
	generic map (
		SAMPLE_RATE => 48
		)
	port map(
		clock => AUD_DACLRCK,
		reset => not key(0),
		freq  => mario_freq
		);

	Mario_Synth: entity work.Wavetable
	generic map (
		SAMPLE_RATE => 48
		)
	port map(
		clock => AUD_DACLRCK,
		reset => not key(0),
		waveform_type => '1', -- Square (Louder)
		freq => mario_freq,
		wave => mario_wave
		);
		
	White_Noise_LFSR: entity work.random_LFSR port map
		(	clock => AUD_DACLRCK,
			reset => not key(0),
			rand	=> rand_LFSR,
			seed	=> x"0000" & SW(15 downto 0)
		);

	White_Noise_LCG: entity work.random_LCG port map
		(	clock => AUD_DACLRCK,
			reset => not key(0),
			rand	=> rand_LCG,
			seed	=> x"0000" & SW(15 downto 0)
		);
		
	Audio_interface: entity work.Audio
	Generic map (
		SAMPLE_RATE => 48 --in KHz
		)
	Port map (
		clock => clock_50,
		reset => not key(0),
		AUD_XCK => AUD_XCK,
		I2C_SCLK => I2C_SCLK,
      I2C_SDAT => I2C_SDAT,
		AUD_BCLK => AUD_BCLK,
		AUD_DACLRCK => AUD_DACLRCK,
		AUD_ADCLRCK => AUD_ADCLRCK,
		AUD_ADCDAT => AUD_ADCDAT,
		AUD_DACDAT => AUD_DACDAT,
		Lin => open,
		Rout => Rout,
		Lout => Rout
		);
end architecture Audio_Test;
