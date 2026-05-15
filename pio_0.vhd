--Copyright (C) 1991-2004 Altera Corporation
--Any megafunction design, and related net list (encrypted or decrypted),
--support information, device programming or simulation file, and any other
--associated documentation or information provided by Altera or a partner
--under Altera's Megafunction Partnership Program may be used only to
--program PLD devices (but not masked PLD devices) from Altera.  Any other
--use of such megafunction design, net list, support information, device
--programming or simulation file, or any other related documentation or
--information is prohibited for any other purpose, including, but not
--limited to modification, reverse engineering, de-compiling, or use with
--any other silicon devices, unless such use is explicitly licensed under
--a separate agreement with Altera or a megafunction partner.  Title to
--the intellectual property, including patents, copyrights, trademarks,
--trade secrets, or maskworks, embodied in any such megafunction design,
--net list, support information, device programming or simulation file, or
--any other related documentation or information provided by Altera or a
--megafunction partner, remains with Altera, the megafunction partner, or
--their respective licensors.  No other licenses, including any licenses
--needed under any third party's intellectual property, are provided herein.
--Copying or modifying any file, or portion thereof, to which this notice
--is attached violates this copyright.

library altera_vhdl_support;
use altera_vhdl_support.altera_vhdl_support_lib.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity pio_0 is 
        port (
              -- inputs:
                 signal address : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
                 signal chipselect : IN STD_LOGIC;
                 signal clk : IN STD_LOGIC;
                 signal reset_n : IN STD_LOGIC;
                 signal write_n : IN STD_LOGIC;
                 signal writedata : IN STD_LOGIC_VECTOR (7 DOWNTO 0);

              -- outputs:
                 signal bidir_port : INOUT STD_LOGIC_VECTOR (7 DOWNTO 0);
                 signal readdata : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
              );
end entity pio_0;


architecture europa of pio_0 is
                signal clk_en :  STD_LOGIC;
                signal data_dir :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal data_in :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal data_out :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal read_mux_out :  STD_LOGIC_VECTOR (7 DOWNTO 0);

begin

  clk_en <= '1';
  read_mux_out <= ((A_REP(to_std_logic(((address = "00"))), 8) AND data_in)) OR ((A_REP(to_std_logic(((address = "01"))), 8) AND data_dir));
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      readdata <= "00000000";
    elsif clk'event and clk = '1' then
      if std_logic'(clk_en) = '1' then 
        readdata <= read_mux_out;
      end if;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      data_out <= "00000000";
    elsif clk'event and clk = '1' then
      if std_logic'(((chipselect AND NOT write_n) AND to_std_logic(((address = "00"))))) = '1' then 
        data_out <= writedata(7 DOWNTO 0);
      end if;
    end if;

  end process;

  bidir_port(0) <= A_WE_StdLogic((std_logic'(data_dir(0)) = '1'), data_out(0), 'Z');
  bidir_port(1) <= A_WE_StdLogic((std_logic'(data_dir(1)) = '1'), data_out(1), 'Z');
  bidir_port(2) <= A_WE_StdLogic((std_logic'(data_dir(2)) = '1'), data_out(2), 'Z');
  bidir_port(3) <= A_WE_StdLogic((std_logic'(data_dir(3)) = '1'), data_out(3), 'Z');
  bidir_port(4) <= A_WE_StdLogic((std_logic'(data_dir(4)) = '1'), data_out(4), 'Z');
  bidir_port(5) <= A_WE_StdLogic((std_logic'(data_dir(5)) = '1'), data_out(5), 'Z');
  bidir_port(6) <= A_WE_StdLogic((std_logic'(data_dir(6)) = '1'), data_out(6), 'Z');
  bidir_port(7) <= A_WE_StdLogic((std_logic'(data_dir(7)) = '1'), data_out(7), 'Z');
  data_in <= bidir_port;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      data_dir <= "00000000";
    elsif clk'event and clk = '1' then
      if std_logic'(((chipselect AND NOT write_n) AND to_std_logic(((address = "01"))))) = '1' then 
        data_dir <= writedata(7 DOWNTO 0);
      end if;
    end if;

  end process;


end europa;

