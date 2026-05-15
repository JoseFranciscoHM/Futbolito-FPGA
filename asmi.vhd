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

--Register map:
--addr      register      type
--0         read data     r
--1         write data    w
--2         status        r/w
--3         control       r/w
--4         reserved
--5         slave-enable  r/w
--6         end-of-packet-value r/w
--INPUT_CLOCK: 50000000
--ISMASTER: 1
--DATABITS: 8
--TARGETCLOCK: 20000000
--NUMSLAVES: 1
--CPOL: 0
--CPHA: 0
--LSBFIRST: 0
--EXTRADELAY: 1
--TARGETSSDELAY: 0.0001

entity asmi_sub is 
        port (
              -- inputs:
                 signal MISO : IN STD_LOGIC;
                 signal asmi_select : IN STD_LOGIC;
                 signal clk : IN STD_LOGIC;
                 signal data_from_cpu : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
                 signal mem_addr : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
                 signal read_n : IN STD_LOGIC;
                 signal reset_n : IN STD_LOGIC;
                 signal write_n : IN STD_LOGIC;

              -- outputs:
                 signal MOSI : OUT STD_LOGIC;
                 signal SCLK : OUT STD_LOGIC;
                 signal SS_n : OUT STD_LOGIC;
                 signal data_to_cpu : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
                 signal dataavailable : OUT STD_LOGIC;
                 signal endofpacket : OUT STD_LOGIC;
                 signal irq : OUT STD_LOGIC;
                 signal readyfordata : OUT STD_LOGIC
              );
end entity asmi_sub;


architecture europa of asmi_sub is
                signal E :  STD_LOGIC;
                signal EOP :  STD_LOGIC;
                signal MISO_reg :  STD_LOGIC;
                signal ROE :  STD_LOGIC;
                signal RRDY :  STD_LOGIC;
                signal SCLK_reg :  STD_LOGIC;
                signal SSO_reg :  STD_LOGIC;
                signal TMT :  STD_LOGIC;
                signal TOE :  STD_LOGIC;
                signal TRDY :  STD_LOGIC;
                signal asmi_control :  STD_LOGIC_VECTOR (10 DOWNTO 0);
                signal asmi_slave_select_holding_reg :  STD_LOGIC_VECTOR (15 DOWNTO 0);
                signal asmi_slave_select_reg :  STD_LOGIC_VECTOR (15 DOWNTO 0);
                signal asmi_status :  STD_LOGIC_VECTOR (10 DOWNTO 0);
                signal control_wr_strobe :  STD_LOGIC;
                signal data_rd_strobe :  STD_LOGIC;
                signal data_wr_strobe :  STD_LOGIC;
                signal delayCounter :  STD_LOGIC_VECTOR (11 DOWNTO 0);
                signal enableSS :  STD_LOGIC;
                signal endofpacketvalue_reg :  STD_LOGIC_VECTOR (15 DOWNTO 0);
                signal endofpacketvalue_wr_strobe :  STD_LOGIC;
                signal iEOP_reg :  STD_LOGIC;
                signal iE_reg :  STD_LOGIC;
                signal iROE_reg :  STD_LOGIC;
                signal iRRDY_reg :  STD_LOGIC;
                signal iTMT_reg :  STD_LOGIC;
                signal iTOE_reg :  STD_LOGIC;
                signal iTRDY_reg :  STD_LOGIC;
                signal irq_reg :  STD_LOGIC;
                signal p1_data_rd_strobe :  STD_LOGIC;
                signal p1_data_to_cpu :  STD_LOGIC_VECTOR (15 DOWNTO 0);
                signal p1_data_wr_strobe :  STD_LOGIC;
                signal p1_rd_strobe :  STD_LOGIC;
                signal p1_slowcount :  STD_LOGIC_VECTOR (1 DOWNTO 0);
                signal p1_wr_strobe :  STD_LOGIC;
                signal rd_strobe :  STD_LOGIC;
                signal rx_holding_reg :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal shift_reg :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal slaveselect_wr_strobe :  STD_LOGIC;
                signal slowclock :  STD_LOGIC;
                signal slowcount :  STD_LOGIC_VECTOR (1 DOWNTO 0);
                signal state :  STD_LOGIC_VECTOR (4 DOWNTO 0);
                signal status_wr_strobe :  STD_LOGIC;
                signal transmitting :  STD_LOGIC;
                signal tx_holding_primed :  STD_LOGIC;
                signal tx_holding_reg :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal wr_strobe :  STD_LOGIC;
                signal write_shift_reg :  STD_LOGIC;
                signal write_tx_holding :  STD_LOGIC;

begin

  p1_rd_strobe <= (NOT rd_strobe AND asmi_select) AND NOT read_n;
  -- Read is a two-cycle event.
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      rd_strobe <= '0';
    elsif clk'event and clk = '1' then
      if true then 
        rd_strobe <= p1_rd_strobe;
      end if;
    end if;

  end process;

  p1_data_rd_strobe <= p1_rd_strobe AND to_std_logic(((mem_addr = "000")));
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      data_rd_strobe <= '0';
    elsif clk'event and clk = '1' then
      if true then 
        data_rd_strobe <= p1_data_rd_strobe;
      end if;
    end if;

  end process;

  p1_wr_strobe <= (NOT wr_strobe AND asmi_select) AND NOT write_n;
  -- Write is a two-cycle event.
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      wr_strobe <= '0';
    elsif clk'event and clk = '1' then
      if true then 
        wr_strobe <= p1_wr_strobe;
      end if;
    end if;

  end process;

  p1_data_wr_strobe <= p1_wr_strobe AND to_std_logic(((mem_addr = "001")));
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      data_wr_strobe <= '0';
    elsif clk'event and clk = '1' then
      if true then 
        data_wr_strobe <= p1_data_wr_strobe;
      end if;
    end if;

  end process;

  control_wr_strobe <= wr_strobe AND to_std_logic(((mem_addr = "011")));
  status_wr_strobe <= wr_strobe AND to_std_logic(((mem_addr = "010")));
  slaveselect_wr_strobe <= wr_strobe AND to_std_logic(((mem_addr = "101")));
  endofpacketvalue_wr_strobe <= wr_strobe AND to_std_logic(((mem_addr = "110")));
  TMT <= NOT transmitting AND NOT tx_holding_primed;
  E <= ROE OR TOE;
  asmi_status <= "0" & (Std_Logic_Vector'(A_ToStdLogicVector(EOP) & A_ToStdLogicVector(E) & A_ToStdLogicVector(RRDY) & A_ToStdLogicVector(TRDY) & A_ToStdLogicVector(TMT) & A_ToStdLogicVector(TOE) & A_ToStdLogicVector(ROE) & "000"));
  -- Streaming data ready for pickup.
  dataavailable <= RRDY;
  -- Ready to accept streaming data.
  readyfordata <= TRDY;
  -- Endofpacket condition detected.
  endofpacket <= EOP;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      iEOP_reg <= '0';
      iE_reg <= '0';
      iRRDY_reg <= '0';
      iTRDY_reg <= '0';
      iTMT_reg <= '0';
      iTOE_reg <= '0';
      iROE_reg <= '0';
      SSO_reg <= '0';
    elsif clk'event and clk = '1' then
      if std_logic'(control_wr_strobe) = '1' then 
        iEOP_reg <= data_from_cpu(9);
        iE_reg <= data_from_cpu(8);
        iRRDY_reg <= data_from_cpu(7);
        iTRDY_reg <= data_from_cpu(6);
        iTMT_reg <= data_from_cpu(5);
        iTOE_reg <= data_from_cpu(4);
        iROE_reg <= data_from_cpu(3);
        SSO_reg <= data_from_cpu(10);
      end if;
    end if;

  end process;

  asmi_control <= Std_Logic_Vector'(A_ToStdLogicVector(SSO_reg) & A_ToStdLogicVector(iEOP_reg) & A_ToStdLogicVector(iE_reg) & A_ToStdLogicVector(iRRDY_reg) & A_ToStdLogicVector(iTRDY_reg) & A_ToStdLogicVector('0') & A_ToStdLogicVector(iTOE_reg) & A_ToStdLogicVector(iROE_reg) & "000");
  -- IRQ output.
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      irq_reg <= '0';
    elsif clk'event and clk = '1' then
      if true then 
        irq_reg <= ((((((EOP AND iEOP_reg)) OR ((((TOE OR ROE)) AND iE_reg))) OR ((RRDY AND iRRDY_reg))) OR ((TRDY AND iTRDY_reg))) OR ((TOE AND iTOE_reg))) OR ((ROE AND iROE_reg));
      end if;
    end if;

  end process;

  irq <= irq_reg;
  -- Slave select register.
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      asmi_slave_select_reg <= "0000000000000001";
    elsif clk'event and clk = '1' then
      if std_logic'(write_shift_reg) = '1' then 
        asmi_slave_select_reg <= asmi_slave_select_holding_reg;
      end if;
    end if;

  end process;

  -- Slave select holding register.
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      asmi_slave_select_holding_reg <= "0000000000000001";
    elsif clk'event and clk = '1' then
      if std_logic'(slaveselect_wr_strobe) = '1' then 
        asmi_slave_select_holding_reg <= data_from_cpu;
      end if;
    end if;

  end process;

  -- slowclock is active once every 2 system clock pulses.
  slowclock <= to_std_logic((slowcount = "01"));
  p1_slowcount <= A_EXT ((((("0" & (A_REP(((transmitting AND NOT(slowclock))) , 2))) AND ((("0" & (slowcount)) + "001")))) OR ("0" & (((A_REP((NOT ((transmitting AND NOT(slowclock)))) , 2) AND "00"))))), 2);
  -- Divide counter for SPI clock.
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      slowcount <= "00";
    elsif clk'event and clk = '1' then
      if true then 
        slowcount <= p1_slowcount;
      end if;
    end if;

  end process;

  -- End-of-packet value register.
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      endofpacketvalue_reg <= "0000000000000000";
    elsif clk'event and clk = '1' then
      if std_logic'(endofpacketvalue_wr_strobe) = '1' then 
        endofpacketvalue_reg <= data_from_cpu;
      end if;
    end if;

  end process;

  p1_data_to_cpu <= A_WE_StdLogicVector(((mem_addr = "010")), ("00000" & (asmi_status)), A_WE_StdLogicVector(((mem_addr = "011")), ("00000" & (asmi_control)), A_WE_StdLogicVector(((mem_addr = "110")), endofpacketvalue_reg, A_WE_StdLogicVector(((mem_addr = "101")), asmi_slave_select_reg, ("00000000" & (rx_holding_reg))))));
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      data_to_cpu <= "0000000000000000";
    elsif clk'event and clk = '1' then
      -- Data to cpu.
      data_to_cpu <= p1_data_to_cpu;
    end if;

  end process;

  -- Extra-delay counter.
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      delayCounter <= "100111000011";
    elsif clk'event and clk = '1' then
      if std_logic'(((NOT data_wr_strobe AND NOT TRDY) AND NOT transmitting)) = '1' then 
        delayCounter <= "100111000011";
      end if;
      if std_logic'(((transmitting AND slowclock) AND to_std_logic(((delayCounter /= "000000000000"))))) = '1' then 
        delayCounter <= A_EXT ((("0" & (delayCounter)) - "0000000000001"), 12);
      end if;
    end if;

  end process;

  -- 'state' counts from 0 to 17.
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      state <= "00000";
    elsif clk'event and clk = '1' then
      if std_logic'(((transmitting AND slowclock) AND to_std_logic(((delayCounter = "000000000000"))))) = '1' then 
        if state = "10001" then 
          state <= "00000";
        else
          state <= A_EXT ((("0" & (state)) + "000001"), 5);
        end if;
      end if;
    end if;

  end process;

  enableSS <= transmitting AND to_std_logic(((delayCounter /= "100111000011")));
  MOSI <= shift_reg(7);
  SS_n <= Vector_To_Std_Logic(A_WE_StdLogicVector((std_logic'(((enableSS OR SSO_reg))) = '1'), NOT asmi_slave_select_reg, "0000000000000001"));
  SCLK <= SCLK_reg;
  -- As long as there's an empty spot somewhere,
  --it's safe to write data.
  TRDY <= NOT ((transmitting AND tx_holding_primed));
  -- Enable write to tx_holding_register.
  write_tx_holding <= data_wr_strobe AND TRDY;
  -- Enable write to shift register.
  write_shift_reg <= tx_holding_primed AND NOT transmitting;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      shift_reg <= "00000000";
      rx_holding_reg <= "00000000";
      EOP <= '0';
      RRDY <= '0';
      ROE <= '0';
      TOE <= '0';
      tx_holding_reg <= "00000000";
      tx_holding_primed <= '0';
      transmitting <= '0';
      SCLK_reg <= '0';
      MISO_reg <= '0';
    elsif clk'event and clk = '1' then
      if std_logic'(write_tx_holding) = '1' then 
        tx_holding_reg <= data_from_cpu (7 DOWNTO 0);
        tx_holding_primed <= '1';
      end if;
      if std_logic'((data_wr_strobe AND NOT TRDY)) = '1' then 
        -- You wrote when I wasn't ready.
        TOE <= '1';
      end if;
      -- EOP must be updated by the last (2nd) cycle of access.
      if std_logic'((((p1_data_rd_strobe AND to_std_logic(((("00000000" & (rx_holding_reg)) = endofpacketvalue_reg))))) OR ((p1_data_wr_strobe AND to_std_logic(((("00000000" & (data_from_cpu(7 DOWNTO 0))) = endofpacketvalue_reg))))))) = '1' then 
        EOP <= '1';
      end if;
      if std_logic'(write_shift_reg) = '1' then 
        shift_reg <= tx_holding_reg;
        transmitting <= '1';
      end if;
      if std_logic'((write_shift_reg AND NOT write_tx_holding)) = '1' then 
        -- Clear tx_holding_primed
        tx_holding_primed <= '0';
      end if;
      if std_logic'(data_rd_strobe) = '1' then 
        -- On data read, clear the RRDY bit.
        RRDY <= '0';
      end if;
      if std_logic'(status_wr_strobe) = '1' then 
        -- On status write, clear all status bits (ignore the data).
        EOP <= '0';
        RRDY <= '0';
        ROE <= '0';
        TOE <= '0';
      end if;
      if std_logic'((slowclock AND to_std_logic(((delayCounter = "000000000000"))))) = '1' then 
        if state = "10001" then 
          transmitting <= '0';
          RRDY <= '1';
          rx_holding_reg <= shift_reg;
          SCLK_reg <= '0';
          if std_logic'(RRDY) = '1' then 
            ROE <= '1';
          end if;
        elsif state /= "00000" then 
          if std_logic'(transmitting) = '1' then 
            SCLK_reg <= NOT SCLK_reg;
          end if;
        end if;
        if std_logic'(((SCLK_reg XOR '0') XOR '0')) = '1' then 
          if true then 
            shift_reg <= Std_Logic_Vector'(shift_reg(6 DOWNTO 0) & A_ToStdLogicVector(MISO_reg));
          end if;
        else
          MISO_reg <= MISO;
        end if;
      end if;
    end if;

  end process;


end europa;


--exemplar translate_off

library altera_vhdl_support;
use altera_vhdl_support.altera_vhdl_support_lib.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity tornado_asmi_atom is 
        port (
              -- inputs:
                 signal dclkin : IN STD_LOGIC;
                 signal oe : IN STD_LOGIC;
                 signal scein : IN STD_LOGIC;
                 signal sdoin : IN STD_LOGIC;

              -- outputs:
                 signal data0out : OUT STD_LOGIC
              );
end entity tornado_asmi_atom;


architecture europa of tornado_asmi_atom is
              signal internal_data0out :  STD_LOGIC;

begin

    internal_data0out <= ((sdoin OR scein) OR dclkin) OR oe;
  --vhdl renameroo for output signals
  data0out <= internal_data0out;
end europa;

--exemplar translate_on


--synthesis read_comments_as_HDL on
--library altera_vhdl_support;
--use altera_vhdl_support.altera_vhdl_support_lib.all;
--
--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;
--
--entity tornado_asmi_atom is 
--        port (
--              
--                 signal dclkin : IN STD_LOGIC;
--                 signal oe : IN STD_LOGIC;
--                 signal scein : IN STD_LOGIC;
--                 signal sdoin : IN STD_LOGIC;
--
--              
--                 signal data0out : OUT STD_LOGIC
--              );
--end entity tornado_asmi_atom;
--
--
--architecture europa of tornado_asmi_atom is
--  component tornado_spiblock is
--PORT (
--    signal data0out : OUT STD_LOGIC;
--        signal dclkin : IN STD_LOGIC;
--        signal oe : IN STD_LOGIC;
--        signal scein : IN STD_LOGIC;
--        signal sdoin : IN STD_LOGIC
--      );
--  end component tornado_spiblock;
--                signal internal_data0out :  STD_LOGIC;
--
--begin
--
--  the_tornado_spiblock : tornado_spiblock
--    port map(
--            data0out => internal_data0out,
--            dclkin => dclkin,
--            oe => oe,
--            scein => scein,
--            sdoin => sdoin
--    );
--
--  
--  data0out <= internal_data0out;
--end europa;
--
--synthesis read_comments_as_HDL off

library altera_vhdl_support;
use altera_vhdl_support.altera_vhdl_support_lib.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity asmi is 
        port (
              -- inputs:
                 signal asmi_select : IN STD_LOGIC;
                 signal clk : IN STD_LOGIC;
                 signal data_from_cpu : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
                 signal mem_addr : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
                 signal read_n : IN STD_LOGIC;
                 signal reset_n : IN STD_LOGIC;
                 signal write_n : IN STD_LOGIC;

              -- outputs:
                 signal data_to_cpu : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
                 signal dataavailable : OUT STD_LOGIC;
                 signal endofpacket : OUT STD_LOGIC;
                 signal irq : OUT STD_LOGIC;
                 signal readyfordata : OUT STD_LOGIC
              );
end entity asmi;


architecture europa of asmi is
component asmi_sub is 
           port (
                 -- inputs:
                    signal MISO : IN STD_LOGIC;
                    signal asmi_select : IN STD_LOGIC;
                    signal clk : IN STD_LOGIC;
                    signal data_from_cpu : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
                    signal mem_addr : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
                    signal read_n : IN STD_LOGIC;
                    signal reset_n : IN STD_LOGIC;
                    signal write_n : IN STD_LOGIC;

                 -- outputs:
                    signal MOSI : OUT STD_LOGIC;
                    signal SCLK : OUT STD_LOGIC;
                    signal SS_n : OUT STD_LOGIC;
                    signal data_to_cpu : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
                    signal dataavailable : OUT STD_LOGIC;
                    signal endofpacket : OUT STD_LOGIC;
                    signal irq : OUT STD_LOGIC;
                    signal readyfordata : OUT STD_LOGIC
                 );
end component asmi_sub;

component tornado_asmi_atom is 
           port (
                 -- inputs:
                    signal dclkin : IN STD_LOGIC;
                    signal oe : IN STD_LOGIC;
                    signal scein : IN STD_LOGIC;
                    signal sdoin : IN STD_LOGIC;

                 -- outputs:
                    signal data0out : OUT STD_LOGIC
                 );
end component tornado_asmi_atom;

                signal MISO :  STD_LOGIC;
                signal MOSI :  STD_LOGIC;
                signal SCLK :  STD_LOGIC;
                signal SS_n :  STD_LOGIC;
                signal internal_data_to_cpu :  STD_LOGIC_VECTOR (15 DOWNTO 0);
                signal internal_dataavailable :  STD_LOGIC;
                signal internal_endofpacket :  STD_LOGIC;
                signal internal_irq :  STD_LOGIC;
                signal internal_readyfordata :  STD_LOGIC;

begin

  the_asmi_sub : asmi_sub
    port map(
      MOSI => MOSI,
      SCLK => SCLK,
      SS_n => SS_n,
      data_to_cpu => internal_data_to_cpu,
      dataavailable => internal_dataavailable,
      endofpacket => internal_endofpacket,
      irq => internal_irq,
      readyfordata => internal_readyfordata,
      MISO => MISO,
      asmi_select => asmi_select,
      clk => clk,
      data_from_cpu => data_from_cpu,
      mem_addr => mem_addr,
      read_n => read_n,
      reset_n => reset_n,
      write_n => write_n
    );


  the_tornado_asmi_atom : tornado_asmi_atom
    port map(
      data0out => MISO,
      dclkin => SCLK,
      oe => '0',
      scein => SS_n,
      sdoin => MOSI
    );


  --vhdl renameroo for output signals
  data_to_cpu <= internal_data_to_cpu;
  --vhdl renameroo for output signals
  dataavailable <= internal_dataavailable;
  --vhdl renameroo for output signals
  endofpacket <= internal_endofpacket;
  --vhdl renameroo for output signals
  irq <= internal_irq;
  --vhdl renameroo for output signals
  readyfordata <= internal_readyfordata;

end europa;

