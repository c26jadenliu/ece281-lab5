----------------------------------------------------------------------------------
-- Company: US Air Force Academy
-- Engineer: Jaden Liu
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: Basic CPU
-- Module Name: ALU - Behavioral
-- Project Name: Lab 5
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- Doc Statement: Received help from C2C Ian Miles and referenced his code for ALU and top level file, making
-- changes to meet project description as necessary.
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

	signal w_result   :   std_logic_vector (7 downto 0);
	signal w_carry : std_logic;
	signal w_zero : std_logic;
	signal w_neg : std_logic;
	signal extended : std_logic_vector(8 downto 0);
    signal w_overflow :std_logic;
    
begin
    
    with i_op select
    --add, sub, and, or, according to provided opcodes
        w_result <= std_logic_vector(signed(i_A) + signed (i_B)) when "000",
                    std_logic_vector(signed(i_B) - signed(i_B)) when "001",
                    i_A and i_B when "010",
                    i_A or i_B when "011",
                    (others=>'0') when others;
    
    --deal with carry for add/sub
    with i_op select
        extended <= std_logic_vector(resize(signed(i_A), 9)+resize(signed(i_B),9)) when "000",
                    std_logic_vector(resize(signed(i_A), 9)-resize(signed(i_B),9)) when "001",
                    (others => '0') when others;
	-- flags
	w_zero <= '1' when (w_result = "00000000") else '0'; -- zero flag 
	w_carry <= extended(8) when (i_op = "000" or i_op = "001") else '0'; 
	w_neg <= w_result(7);
	
	
	w_overflow <=
	
	   '1' when i_op = "000" and (i_A(7) = i_B(7)) and (w_result(7) /= i_A(7)) else
	   '1' when i_op = "001" and (i_A(7) /= i_B(7)) and (w_result(7) /= i_A(7)) else
	   '0';
	o_flags <= w_neg & w_zero & w_carry & w_overflow;
	
	o_result <= w_result;
		
	
end Behavioral;
