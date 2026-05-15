library ieee;
use ieee.std_logic_1164.all;

entity random_LFSR is
	port(	
		clock	: in 	std_logic;
		reset	: in 	std_logic;
		rand	: buffer std_logic_vector(31 downto 0);
		seed	: in	std_logic_vector(31 downto 0) := x"01000001"
		);
end;

architecture LFSR of random_LFSR is
begin
	Psuedo_random: process(clock, reset)
	begin
		if(reset = '1') then			
		   rand <= seed; --hardware initial seed
		elsif(clock'event AND clock = '1') then
		   rand <= rand(30 downto 0) & 
			(rand(31) xor rand(30) xor rand(28) xor rand (0));
		end if;
	end process;
end LFSR;
