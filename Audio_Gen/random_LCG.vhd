library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity random_LCG is
	port(	
		clock	: in 	std_logic;
		reset	: in 	std_logic;
		rand	: buffer std_logic_vector(31 downto 0);
		seed	: in	std_logic_vector(31 downto 0) := x"01000001"
		);
end;

architecture LCG of random_LCG is
	constant a : natural := 1103515245;
	constant b : natural := 12345;
begin
	Psuedo_random: process(clock, reset)
	begin
		if(reset = '1') then			
			rand <= seed; --hardware initial seed
		elsif(clock'event AND clock = '1') then
			rand <= std_logic_vector(resize(unsigned(rand) * a, 32) + b);
		end if;
	end process;
end LCG;
