----------------------------------------------------------------------------------
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: Basic CPU
-- Module Name: controller_fsm - FSM
-- Project Name: Lab 5 
-- Target Devices: 
-- Tool Versions: 
-- Description: controller fsm for basic cpu
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
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

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is
    signal current_state, next_state : std_logic_vector(3 downto 0);

begin
    process(i_adv,i_reset)
    begin
        if i_reset = '1' then
            current_state<="0001";
        elsif rising_edge(i_adv)
        then
            current_State <= next_state;
            
        end if;
    end process;
    
    process(current_state)
    begin
        case current_State is
            when "1000" => next_state <= "0100";
            when "0100" => next_state <= "0010";
            when "0010" => next_state <= "0001";
            when "0001" => next_state <= "1000";
            when others => next_state <= "0001";
        end case;
        
    end process;
    
    o_cycle <= current_state;
    
end FSM;
