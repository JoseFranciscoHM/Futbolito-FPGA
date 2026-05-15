

-- ----------------------------------------------------------------------------
--
-- These routines are used to help SOPC Builder generate VHDL code.
--
-- ----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package altera_vhdl_support_lib is

  attribute IS_SIGNED : BOOLEAN ;
  attribute SYNTHESIS_RETURN : STRING ;


  FUNCTION  and_reduce(arg : STD_LOGIC_VECTOR) RETURN STD_LOGIC;
  -- Result subtype: STD_LOGIC.
  -- Result: Result of and'ing all of the bits of the vector.

  FUNCTION nand_reduce(arg : STD_LOGIC_VECTOR) RETURN STD_LOGIC;
  -- Result subtype: STD_LOGIC.
  -- Result: Result of nand'ing all of the bits of the vector.

  FUNCTION   or_reduce(arg : STD_LOGIC_VECTOR) RETURN STD_LOGIC;
  -- Result subtype: STD_LOGIC.
  -- Result: Result of or'ing all of the bits of the vector.

  FUNCTION  nor_reduce(arg : STD_LOGIC_VECTOR) RETURN STD_LOGIC;
  -- Result subtype: STD_LOGIC.
  -- Result: Result of nor'ing all of the bits of the vector.

  FUNCTION  xor_reduce(arg : STD_LOGIC_VECTOR) RETURN STD_LOGIC;
  -- Result subtype: STD_LOGIC.
  -- Result: Result of xor'ing all of the bits of the vector.

  FUNCTION xnor_reduce(arg : STD_LOGIC_VECTOR) RETURN STD_LOGIC;
  -- Result subtype: STD_LOGIC.
  -- Result: Result of xnor'ing all of the bits of the vector.

--  FUNCTION A_SRL(arg : STD_LOGIC_VECTOR;shift : INTEGER) RETURN STD_LOGIC_VECTOR;
  -- Result subtype: STD_LOGIC.
  -- Result: Result of xnor'ing all of the bits of the vector.

--  FUNCTION A_SLL(arg : STD_LOGIC_VECTOR; shift : INTEGER) RETURN STD_LOGIC_VECTOR;
  -- Result subtype: STD_LOGIC.
  -- Result: Result of xnor'ing all of the bits of the vector.

  FUNCTION A_SRL(arg: std_logic_vector; shift: integer) RETURN std_logic_vector;
  FUNCTION A_SLL(arg: std_logic_vector; shift: integer) RETURN std_logic_vector;

  FUNCTION A_TOSTDLOGICVECTOR(a: std_logic) RETURN std_logic_vector;

  FUNCTION A_WE_StdLogic  (select_arg: boolean; then_arg: STD_LOGIC ; else_arg:STD_LOGIC) RETURN STD_LOGIC;
  FUNCTION A_WE_StdUlogic (select_arg: boolean; then_arg: STD_ULOGIC; else_arg:STD_ULOGIC) RETURN STD_ULOGIC;
  FUNCTION A_WE_StdLogicVector(select_arg: boolean; then_arg: STD_LOGIC_VECTOR; else_arg:STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR;
  FUNCTION A_WE_StdUlogicVector(select_arg: boolean; then_arg: STD_ULOGIC_VECTOR; else_arg:STD_ULOGIC_VECTOR) RETURN STD_ULOGIC_VECTOR;

  FUNCTION Vector_To_Std_Logic(vector: STD_LOGIC_VECTOR) return Std_Logic;

  function TO_STD_LOGIC(arg : BOOLEAN) return STD_LOGIC;
  -- Result subtype: STD_LOGIC
  -- Result: Converts a BOOLEAN to a STD_LOGIC..
  
  FUNCTION a_rep(arg : STD_LOGIC; repeat : INTEGER) RETURN STD_LOGIC_VECTOR ;
  FUNCTION a_rep_vector(arg : STD_LOGIC_VECTOR; repeat : INTEGER) RETURN STD_LOGIC_VECTOR ;
  function a_min(L, R: INTEGER) return INTEGER ;
  FUNCTION a_ext (arg : STD_LOGIC_VECTOR; size : INTEGER) RETURN STD_LOGIC_VECTOR ;

  
end altera_vhdl_support_lib;


package body altera_vhdl_support_lib is

  --
  -- Reducing logical functions.
  --

  FUNCTION and_reduce(arg: STD_LOGIC_VECTOR) RETURN STD_LOGIC IS
    VARIABLE result: STD_LOGIC;
    -- Exemplar synthesis directive attributes for this function
    ATTRIBUTE synthesis_RETURN OF result:VARIABLE IS "REDUCE_AND" ;
  BEGIN
    result := '1';
    FOR i IN arg'RANGE LOOP
      result := result AND arg(i);
    END LOOP;
    RETURN result;
  END;

  FUNCTION nand_reduce(arg: STD_LOGIC_VECTOR) RETURN STD_LOGIC IS
    VARIABLE result: STD_LOGIC;
    ATTRIBUTE synthesis_RETURN OF result:VARIABLE IS "REDUCE_NAND" ;
  BEGIN
      result := NOT and_reduce(arg);
      RETURN result;
  END;

  FUNCTION or_reduce(arg: STD_LOGIC_VECTOR) RETURN STD_LOGIC IS
    VARIABLE result: STD_LOGIC;
    -- Exemplar synthesis directive attributes for this function
    ATTRIBUTE synthesis_return OF result:VARIABLE IS "REDUCE_OR" ;
  BEGIN
    result := '0';
    FOR i IN arg'RANGE LOOP
      result := result OR arg(i);
    END LOOP;
    RETURN result;
  END;

  FUNCTION nor_reduce(arg: STD_LOGIC_VECTOR) RETURN STD_LOGIC IS
    VARIABLE result: STD_LOGIC;
    ATTRIBUTE synthesis_RETURN OF result:VARIABLE IS "REDUCE_NOR" ;
  BEGIN
    result := NOT or_reduce(arg);
    RETURN result;
  END;

  FUNCTION xor_reduce(arg: STD_LOGIC_VECTOR) RETURN STD_LOGIC IS
    VARIABLE result: STD_LOGIC;
    -- Exemplar synthesis directive attributes for this function
    ATTRIBUTE synthesis_return OF result:VARIABLE IS "REDUCE_XOR" ;
  BEGIN
    result := '0';
    FOR i IN arg'RANGE LOOP
      result := result XOR arg(i);
    END LOOP;
    RETURN result;
  END;

  FUNCTION xnor_reduce(arg: STD_LOGIC_VECTOR) RETURN STD_LOGIC IS
    VARIABLE result: STD_LOGIC;
    ATTRIBUTE synthesis_RETURN OF result:VARIABLE IS "REDUCE_XNOR" ;
  BEGIN
    result := NOT xor_reduce(arg);
    RETURN result;
  END;

  function TO_STD_LOGIC(arg : BOOLEAN) return STD_LOGIC is
  begin
    if(arg = true) then
        return('1');
    else
        return('0');
    end if;
  end;


  FUNCTION A_SRL(arg : STD_LOGIC_VECTOR; shift : INTEGER) RETURN STD_LOGIC_VECTOR IS
    VARIABLE result : STD_LOGIC_VECTOR(arg'LEFT DOWNTO 0) := (arg'RANGE => '0');
  BEGIN 
    IF ((shift <= arg'LEFT) AND (shift >= 0)) THEN
      IF (shift = 0) THEN
        result := arg;
      ELSE
        result(arg'LEFT - shift DOWNTO 0) := arg(arg'LEFT DOWNTO shift);
      END IF;
    END IF;

    RETURN(result);   
  END;

  FUNCTION A_SLL(arg : STD_LOGIC_VECTOR; shift : INTEGER) RETURN STD_LOGIC_VECTOR IS
    VARIABLE result : STD_LOGIC_VECTOR(arg'LEFT DOWNTO 0) := (arg'RANGE => '0');
  BEGIN 
    IF ((shift <= arg'LEFT) AND (shift >= 0)) THEN
      IF (shift = 0) THEN
        result := arg;
      ELSE
        result(arg'LEFT DOWNTO shift) := arg(arg'LEFT - shift DOWNTO 0);
      END IF;
    END IF;

    RETURN(result);   
  END;



  FUNCTION A_TOSTDLOGICVECTOR(a: std_logic) RETURN std_logic_vector IS
  BEGIN
    IF a = '1'     THEN
      return "1";
    ELSE 
      return "0";
    END IF;
  END;

  FUNCTION A_WE_StdLogic  (select_arg: boolean; then_arg: STD_LOGIC ; else_arg:STD_LOGIC) RETURN STD_LOGIC IS
  BEGIN
      IF (select_arg) THEN
	return (then_arg);
      ELSE
  	return (else_arg);
      END IF;
  END;

  FUNCTION A_WE_StdUlogic (select_arg: boolean; then_arg: STD_ULOGIC; else_arg:STD_ULOGIC) RETURN STD_ULOGIC IS
  BEGIN
      IF (select_arg) THEN
	return (then_arg);
      ELSE
  	return (else_arg);
      END IF;
  END;

  FUNCTION A_WE_StdLogicVector(select_arg: boolean; then_arg: STD_LOGIC_VECTOR; else_arg:STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
  BEGIN
      IF (select_arg) THEN
	return (then_arg);
      ELSE
  	return (else_arg);
      END IF;
  END;

  FUNCTION A_WE_StdUlogicVector(select_arg: boolean; then_arg: STD_ULOGIC_VECTOR; else_arg:STD_ULOGIC_VECTOR) RETURN STD_ULOGIC_VECTOR IS
  BEGIN
      IF (select_arg) THEN
	return (then_arg);
      ELSE
  	return (else_arg);
      END IF;
  END;

  FUNCTION Vector_To_Std_Logic(vector: STD_LOGIC_VECTOR)
  return Std_Logic IS
  BEGIN
      return (vector(vector'right));
  END;


  FUNCTION a_rep(arg : STD_LOGIC; repeat : INTEGER) RETURN STD_LOGIC_VECTOR IS
    VARIABLE result : STD_LOGIC_VECTOR(repeat-1 DOWNTO 0) := (others => '0'); 
    VARIABLE i : integer := 0;
  BEGIN 
    FOR i IN 0 TO (repeat-1) LOOP 
      result(i) := arg;
    end LOOP;
     
     RETURN(result);   
  END;

  FUNCTION a_rep_vector(arg : STD_LOGIC_VECTOR; repeat : INTEGER) RETURN STD_LOGIC_VECTOR IS
    VARIABLE arg_copy : STD_LOGIC_VECTOR ((arg'length - 1)DOWNTO 0) :=  arg ;
    VARIABLE result : STD_LOGIC_VECTOR(((repeat * (arg_copy'LEFT+1))-1) DOWNTO 0) := (others => '0');
    VARIABLE i : integer := 0;  
  BEGIN 
    FOR i IN 0 TO (repeat-1) LOOP 
      result((((arg_copy'left + 1) * i) + arg_copy'left) downto ((arg_copy'left + 1) * i)) := arg_copy(arg_copy'LEFT DOWNTO 0);
    end LOOP;
    
    RETURN(result);   
  END;

  -- a_min : return the minimum of two integers;
  function a_min(L, R: INTEGER) return INTEGER is
  begin
      if L < R then
          return L;
      else
          return R;
      end if;
  end;

  -- a_ext is the Altera version of the EXT function.  It is used to both
  -- zero-extend a signal to a new length, and to extract a signal of 'size'
  -- length from a larger signal.
  FUNCTION a_ext (arg : STD_LOGIC_VECTOR; size : INTEGER) RETURN STD_LOGIC_VECTOR IS
    VARIABLE arg_copy : STD_LOGIC_VECTOR ((arg'length - 1)DOWNTO 0) :=  arg ;
    VARIABLE result : STD_LOGIC_VECTOR((size-1) DOWNTO 0) := (others => '0');
    VARIABLE i : integer := 0;  
    VARIABLE bits_to_copy : integer := 0;
    VARIABLE arg_length : integer := arg'length ;
    VARIABLE LSB_bit : integer := 0;
  BEGIN 
    bits_to_copy := a_min(arg_length, size);
    FOR i IN 0 TO (bits_to_copy - 1) LOOP 
      result(i) := arg_copy(i);
    end LOOP;
    
    RETURN(result);   
  END;

end altera_vhdl_support_lib;
