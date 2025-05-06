--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
	component ALU is
    Port (
        i_A :   in std_logic_vector (7 downto 0);
        i_B :   in std_logic_vector (7 downto 0);
        i_op    :   in std_logic_vector (2 downto 0);
        o_result   :   out std_logic_vector (7 downto 0);
        o_flags     :   out std_logic_vector (3 downto 0)
    );
    end component ALU;
    
    component clock_divider is 
    generic ( constant k_DIV : natural := 2	);
	port ( 	i_clk    : in std_logic;		   
			i_reset  : in std_logic;		   
			o_clk    : out std_logic --slower
	); 
	end component clock_divider;
	
	component TDM4 is
    generic ( constant k_WIDTH : natural  := 4); -- 4 bit input/output
    Port (
        i_clk		: in  STD_LOGIC;
        i_reset		: in  STD_LOGIC; -- asynchronous
        i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0); -- dig
		o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- active anode
	);
	end component TDM4;

    --convert 8b bin to decimal w/ neg
    component twos_comp is
	Port (
	    i_bin: in std_logic_vector(7 downto 0);
        o_sign: out std_logic;
        o_hund: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
    );
    end component twos_comp;
    
    component sevenseg_decoder is
    Port (
        i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
        o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
    );
    end component sevenseg_decoder;
    
    component controller_fsm is
    Port (
        i_adv   :   in std_logic;
        i_reset :   in std_logic;
        o_cycle :   out std_logic_vector (3 downto 0)       
    );
    end component controller_fsm;
    
    signal w_A, w_B, w_results, w_val, w_neg_display    :   std_logic_vector (7 downto 0);
    signal w_op :   std_logic_vector (2 downto 0);
    signal w_tdm, w_an    :   std_logic_vector (3 downto 0);
    signal w_flags : std_logic_vector (3 downto 0);
    signal w_cycle  :   std_logic_vector (3 downto 0);
    signal f_Q, f_Q_next    :   std_logic_vector (3 downto 0);
    
    signal w_neg   :   std_logic;
    signal w_hund : std_logic_vector (3 downto 0);
    signal w_tens : std_logic_vector (3 downto 0);
    signal w_ones : std_logic_vector (3 downto 0);
    signal w_sevSegSign   :  std_logic_vector (3 downto 0);

    signal w_clk_tdm    :   std_logic;
    
begin
	-- PORT MAPS ----------------------------------------
    ALU_inst:ALU
    port map (
        i_A => w_A,
        i_B => w_B,
        i_op => w_op,
        o_result => w_results,
        o_flags => w_flags
    );
    
    clk_TDM_inst    :   clock_divider
    generic map ( k_DIV => 100000 ) -- 2hz
    port map (
        i_clk => clk,
        i_reset => btnU,
        o_clk => w_clk_tdm
    );
    
    TDM_inst    :   TDM4
    port map (
        i_clk => w_clk_tdm,
        i_reset => btnU,
        i_D3 => w_sevSegSign,
        i_D2 => w_hund,
        i_D1 => w_tens,
        i_D0 => w_ones,
        o_data => w_tdm,
        o_sel => w_an
    );
    
    twosComp_inst : twos_comp
    port map (
        i_bin => w_val,
        o_sign => w_neg,
        o_hund => w_hund,
        o_tens => w_tens,
        o_ones => w_ones
    );
    
    sevenSeg_inst :   sevenseg_decoder 
    port map (
        i_Hex => w_tdm,
        o_seg_n => seg
	);
	
	controller_inst    :   controller_fsm
	port map (
	   i_adv => btnC,
	   i_reset => btnU,
	   o_cycle => w_cycle
    );
   
	
	-- CONCURRENT STATEMENTS ----------------------------
	an <= "1111" when (w_cycle = "0001") else -- clear
	       w_an;
	       
	w_op <= sw(2 downto 0);
	       
	-- display baed on state       
	w_val <= w_A when (w_cycle = "1000") else
	         w_B when (w_cycle = "0100") else
	         w_results when (w_cycle = "0010") else
	         (others => '0'); --reset
	         
	w_sevSegSign <= x"F" when (w_neg = '1') else x"E";
	                
	w_op <= sw(2 downto 0);
	
	--state
	led(3 downto 0) <= w_cycle;
	--led(3) <= w_cycle(3);
	--led(2) <= w_cycle(1);
	--led(1) <= w_cycle(2);
	--led(0) <= w_cycle(0);
	--NZCV ALU flags
	led(15 downto 12) <= w_flags when w_cycle = "0010" else "0000";
	
	-- not used
	led(11 downto 4) <= (others => '0');
	
		reg_process: process(clk)
	begin
	
	   if (rising_edge(clk)) then 
            if (w_cycle = "0001") then
                w_A <= sw (7 downto 0);
            elsif (w_cycle = "1000") then
                w_B <= sw (7 downto 0);
            end if;
        end if;
        
	end process reg_process;

end top_basys3_arch;