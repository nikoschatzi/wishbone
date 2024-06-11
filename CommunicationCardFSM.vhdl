-- include libraries
library IEEE;
USE ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
--library work;

------------------------------------- Entity decleration -----------------------------------------
entity CommunicationCardFSM is
port (
	clk   :  in std_logic;   --pin17
	reset :  in std_logic;   --pin144
	
	--NANOFIP signals 
	RSTON : in std_logic;    -- pin51 acknowledge that reset signal was received by nanoFIP 
	VAR1_RDY : in std_logic; -- pin52 - I read data
	VAR2_RDY : in std_logic; -- pinXX - BROADCAST VARIABLE NOT USED
	VAR3_RDY : in std_logic; -- pin53 - I write data
	ERRFLAG : in std_logic;  -- pin55 groups errors
	
	P3_LENGTH :  out std_logic_vector (2 downto 0):= "101"; -- pins 58-59-60 use '101' for 124 bytes , 2V5 pins needed - I use power supply 
	RSTIN : out std_logic ;  -- pin4 active low reset of NanoFIP and fieldrive 
	NOSTAT : out std_logic;  -- pin137 when '1' nanoFIP status is disabled - last FIP byte	
	VAR1_ACC : out std_logic; -- pin63 - I read data
	VAR2_ACC : out std_logic; -- pin132 - BROADCAST VARIABLE NOT USED -- set to 0, otherwise ERRFLAG goes high
	VAR3_ACC : out std_logic; -- pin64 - I write data
	
	--NANOFIP → Wishbone signals
	ACK_I :  in  std_logic; -- pin57
	DAT_I :  out  std_logic_vector (7 downto 0); -- pin24,25,99,100,28,30,31,101
	
	wclk_out  :	out std_logic; -- pin129 -- Wishbone clock
	
	ADR   :  out std_logic_vector (9 downto 0):= (others=>'0'); -- pin 112,113,114,115,97,119,120,121,122,125,129
	DAT_O :  in std_logic_vector (7 downto 0):= "00000000"; -- pin 40,41,42,43,44,45,47,65
	WE_O  :  out std_logic := '0'; -- pin 69
	STB_O :  out std_logic := '0'; -- pin 8 
	CYC_O :  out std_logic := '0'; -- pin 143 
	RST_O :  out std_logic := '0'; -- pin 141 -- wishbone reset, **currently not used by me
	
	--Crate signals --Mother board--	
	SCHB :  out std_logic_vector (7 downto 0) := "00000000";
	MUX_A :  in std_logic_vector (7 downto 0) := "00000000";
	--MUX_B :  in std_logic_vector (7 downto 0) := "00000000";
	--MUX_C :  in std_logic_vector (7 downto 0) := "00000000";
	--MUX_D :  in std_logic_vector (7 downto 0) := "00000000";
	--MUX_E :  in std_logic_vector (7 downto 0) := "00000000";
	--MUX_F :  in std_logic_vector (7 downto 0) := "00000000";
	--MUX_G :  in std_logic_vector (7 downto 0) := "00000000";
	--MUX_H :  in std_logic_vector (7 downto 0) := "00000000";
	
	--Testing signals - data visualization 	
	Top_B0: out std_logic_vector(7 downto 0)  := (others=>'0'); -- 1 byte for testing --virtual pin
	Top_B1: out std_logic_vector(7 downto 0)  := (others=>'0'); -- 1 byte for testing --virtual pin
	Top_B2: out std_logic_vector(7 downto 0)  := (others=>'0'); -- 1 byte for testing --virtual pin
	Top_B3: out std_logic_vector(7 downto 0)  := (others=>'0'); -- 1 byte for testing --virtual pin
	Top_B4: out std_logic_vector(7 downto 0)  := (others=>'0'); -- 1 byte for testing --virtual pin
	Top_B5: out std_logic_vector(7 downto 0)  := (others=>'0'); -- 1 byte for testing --virtual pin
	Top_B6: out std_logic_vector(7 downto 0)  := (others=>'0'); -- 1 byte for testing --virtual pin
	Top_B7: out std_logic_vector(7 downto 0)  := (others=>'0'); -- 1 byte for testing --virtual pin
	
	Bottom_B0: out std_logic_vector(7 downto 0)  := (others=>'0'); -- 1 byte for testing --virtual pin
	Bottom_B1: out std_logic_vector(7 downto 0)  := (others=>'0'); -- 1 byte for testing --virtual pin
	Bottom_B2: out std_logic_vector(7 downto 0)  := (others=>'0'); -- 1 byte for testing --virtual pin
	Bottom_B3: out std_logic_vector(7 downto 0)  := (others=>'0'); -- 1 byte for testing --virtual pin
	Bottom_B4: out std_logic_vector(7 downto 0)  := (others=>'0'); -- 1 byte for testing --virtual pin	
	Bottom_B5: out std_logic_vector(7 downto 0)  := (others=>'0'); -- 1 byte for testing --virtual pin
	Bottom_B6: out std_logic_vector(7 downto 0)  := (others=>'0'); -- 1 byte for testing --virtual pin
	Bottom_B7: out std_logic_vector(7 downto 0)  := (others=>'0'); -- 1 byte for testing --virtual pin
	
	--Testing signals 
	crate_clk_out :  out std_logic; --virtual pin
	--	sampling_clk : out std_logic;   --virtual pin
	LED1  :	out std_logic;  -- pin3
	LED2  :	out std_logic;  -- pin7
	LED3  :	out std_logic;  -- pin9
	
	watch_out : out std_logic_vector (31 downto 0); --testing only
	watch_out_v3 : out std_logic_vector (31 downto 0)); --testing only
	--read_byte : out std_logic_vector (7 downto 0)); --testing only --virtual pin out is being used to probe using Quartus oscilloscope tool 
		
end entity;

--------------------------------------- Architecture ------------------------------------------------
Architecture RTL of CommunicationCardFSM is      --register level transfer

component watchdog --*REMEMBER TO SET WISHBONE CLOCK IN PORT MAP DECLERATION ON BOTTOM*
	generic(
		width				: integer:=32
	);
	port(
		watchdog_clk	: in std_logic;
		en				: in std_logic;
		reset			: in std_logic;
		start_value		: in std_logic_vector(width-1 downto 0);
		
		count			: out std_logic_vector(width-1 downto 0);
		count_done		: out std_logic
	);
end component;

--Watchdog
constant watchdog_length: integer := 32;
constant watchdog_start_value : std_logic_vector(watchdog_length-1 downto 0) := "00000001110010011100001110000000"; -- set decimal 30.000.000 for 50 Mhz clock and 600 ms timeout

signal watchdog_enable_v1 : std_logic;
signal watchdog_reset_v1 : std_logic;
signal watchdog_value_v1 : std_logic_vector(watchdog_length-1 downto 0);
signal watchdog_done_v1 : std_logic;

signal watchdog_enable_v3 : std_logic;
signal watchdog_reset_v3 : std_logic;
signal watchdog_value_v3 : std_logic_vector(watchdog_length-1 downto 0);
signal watchdog_done_v3 : std_logic;

-- Clock
signal wishbone_divide, counter : std_logic_vector(15 downto 0) := (others=>'0');
signal crate_divide, counter2 : std_logic_vector(7 downto 0) := (others=>'0');
signal w_div, crate_div : std_logic_vector(15 downto 0) := (others=>'0');
signal wclk, crate_clk :  std_logic;

-- Crate
signal read_write_flag :  std_logic := '0';
signal new_data : std_logic := '0';

-- FSM
signal var1_state: std_logic_vector(1 downto 0);
signal var3_state: std_logic_vector(1 downto 0);
signal crate_state: std_logic_vector(3 downto 0);
signal update_state: std_logic_vector(3 downto 0);

--WIshbone FSM seq + comb states 
signal w_state: std_logic_vector(4 downto 0);
signal w_next_state : std_logic_vector(4 downto 0);
 
constant IDLE : std_logic_vector(4 downto 0) := "00000";
constant w_reset : std_logic_vector(4 downto 0) := "01111"; 
constant w_reset_ack : std_logic_vector(4 downto 0) := "11111"; 

constant read_init : std_logic_vector(4 downto 0) := "00001";
constant read_start : std_logic_vector(4 downto 0) := "00010";
constant read_wait_ack : std_logic_vector(4 downto 0) := "00011"; 
constant read_address : std_logic_vector(4 downto 0) := "00100"; 
constant read_stb : std_logic_vector(4 downto 0) := "00101"; 
constant read_end : std_logic_vector(4 downto 0) := "00110"; 

constant write_init : std_logic_vector(4 downto 0) := "10001";
constant write_start : std_logic_vector(4 downto 0) := "10010";
constant write_wait_ack : std_logic_vector(4 downto 0) := "10011"; 
constant write_address : std_logic_vector(4 downto 0) := "10100"; 
constant write_stb : std_logic_vector(4 downto 0) := "10101"; 
constant write_end : std_logic_vector(4 downto 0) := "10110"; 

--NanoFIP 
signal SCHB_sig : std_logic_vector (7 downto 0);
signal ADR_sig : std_logic_vector (9 downto 0);
signal var1_was : std_logic;
signal var3_was : std_logic;
signal wishbone_flag_ON : std_logic := '0';

type data_array is array(0 to 123) of std_logic_vector(7 downto 0);
signal data_memory : data_array;
signal data_buffer : data_array;
signal nanofip_var1 : data_array; -- testing only - I read data from nanofip
--signal nanofip_var3 : data_array; -- testing only - I write data to nanofip 
signal read_byte_sig : data_array; -- testing only

signal ack_counter : std_logic_vector (7 downto 0); --if no ack for many cycles move on
--signal reset_ack_not_received : std_logic; 

signal internal_reset : std_logic;
 
signal flag_v1 : std_logic; -- is high during accessing var1
signal flag_v3 : std_logic; -- is high during accessing var3
signal done_v1 : std_logic; -- is high only for 1 cycle, after all addresses of v1 have been read
signal done_v3 : std_logic; -- is high only for 1 cycle, after all addresses of v3 have been written

signal var1_ready : std_logic;
signal var3_ready : std_logic;

--**Check again these**
signal t_counter : natural := 0;
--signal reset_confirm_counter : natural := 0;

BEGIN 

--Output signals which are needed as inputs 
SCHB <= SCHB_sig;
ADR <= ADR_sig;

watch_out <= watchdog_value_v1; -- testing only --virtual output pin 
watch_out_v3 <= watchdog_value_v3;

-------------------- Wishbone clock --------------------
-- clk is 50 MHz --
-- use 50000000 for 1Hz 
-- use 5 for 10 MHz like microfip
-- use 50 for 1 MHz

wishbone_divide <= std_logic_vector(to_unsigned(integer(10000),wishbone_divide'length)); 
w_div <= std_logic_vector(to_unsigned(integer(5000),wishbone_divide'length)); 
--w_div <= (wishbone_divide(6 downto 0) & '0'); -- right shift operation to divide by 2 

process(clk, wclk)
begin
    if( rising_edge(clk) ) then
        if(counter < w_div - "00000001") then -- right shift operation to divide by 2 
            counter <= counter + '1';
            wclk <= '0';
        elsif(counter < wishbone_divide - "00000001") then
            counter <= counter + '1';
            wclk <= '1';
        else
            counter <= (others=>'0');
				wclk <= '0';
        end if;
    end if;
	 
	 wclk_out <= wclk;
	 
end process;

--------------------- Crate clock ---------------------
-- use 334.8 for 149.342 kHz 

crate_divide <= std_logic_vector(to_unsigned(integer(1200),crate_divide'length)); 
crate_div <= std_logic_vector(to_unsigned(integer(600),crate_div'length));
--crate_div <= (crate_divide & '0'); -- right shift operation to divide by 2  

process(clk, crate_clk)
begin
    if( rising_edge(clk) ) then
        if(counter2 < crate_div - "00000001") then -- right shift operation to divide by 2 
            counter2 <= counter2 + '1';
            crate_clk <= '0';
        elsif(counter2 < crate_divide - "00000001") then
            counter2 <= counter2 + '1';
            crate_clk <= '1';
        else
            counter2 <= (others=>'0');
				crate_clk <= '0';
        end if;
    end if;
	 
	 crate_clk_out <= crate_clk;
	 
end process;

--------------------------------------- NanoFIP constant signals-----------------------------------------
process(clk)

begin

   if rising_edge(clk) then 
		P3_LENGTH <= "101";  
		NOSTAT <= '1';   -- set to '1' for testing - Julien doesn't use status bit   
		 
		for i in 0 to 123 loop

		--	nanofip_var3(i) <= "00000001" + std_logic_vector(to_unsigned(i, nanofip_var3(i)'length)); --testing only
			
		end loop;
	end if;
	
end process;

--------------------------------- Wishbone Finite State Machine --------------------------------**ADD RESET WHEN NO VAR READY ACTIVITY**

process(wclk)
begin

	if rising_edge(wclk) THEN
		var3_was <= VAR3_RDY;
		var1_was <= VAR1_RDY;		
	end if;

end process;

--------------------------------- RESET FSM ----------------------------
process

begin

	if reset = '0' or ERRFLAG = '1' or watchdog_done_v1 = '1' or watchdog_done_v3 = '1' then
	
	   internal_reset <= '1';
	
	else
	
	   internal_reset <= '0';
	
	end if;
	
	wait until wclk ='1';
		
	
end process;

--------------------------------------------------VAR1 ready FSM------------------------------------------------------------
process

	begin
	
	if internal_reset = '1' then
	
	   watchdog_reset_v1 <= '1';
		watchdog_enable_v1 <= '1';
		var1_state <= "00";
	
	else
	
		case var1_state is
				
					-- Detect var1 ready rising 
					when "00" =>
						
						watchdog_enable_v1 <= '1';
						
					
						if VAR1_RDY = '1' and var1_was = '0' then
							watchdog_reset_v1 <= '1';
							var1_ready <= '1';
							var1_state <= "01";
						else
						   watchdog_reset_v1 <= '0';
							var1_ready <= '0';
							var1_state <= "00";
						end if;
					
					-- Waiting to read var1  
					when "01" =>
					
					   watchdog_reset_v1 <= '0';
						
						if flag_v1 = '1' then		
							var1_ready <= '0';
							var1_state <= "00";
						elsif var1_ready = '0' then -- this condition should never be true, avoid being stuck at this state
							var1_state <= "00";
						else
							var1_state <= "01";
						end if;
						
					when others =>
					
					   	var1_state <= "00";

		end CASE; 
	end IF; 
	
	wait until wclk ='1';
	
end PROCESS;

--------------------------------------------------VAR3 ready FSM------------------------------------------------------------
process

	begin
	
	if internal_reset = '1' then
	
	   watchdog_reset_v3 <= '1';
		watchdog_enable_v3 <= '1';
		var3_state <= "00";
	
	else
	
		case var3_state is
				
					-- Detect var1 ready rising 
					when "00" =>
					
						watchdog_enable_v3 <= '1';
					
						if VAR3_RDY = '1' and var3_was = '0' then
							watchdog_reset_v3 <= '1';
							var3_ready <= '1';  -- raise flag after detecting rising edge 
							var3_state <= "01";
						else
						   watchdog_reset_v3 <= '0';
							var3_ready <= '0';
							var3_state <= "00";
						end if;
					
					-- Waiting to read var3  
					when "01" =>
					
						watchdog_reset_v3 <= '0';
					
						if flag_v3 = '1' then
							var3_ready <= '0';
							var3_state <= "00";
						elsif var3_ready = '0' then -- this condition should never be true, avoid being stuck at this state
							var3_state <= "00";
						else
							var3_state <= "01";
						end if;
						
					when others =>
					
						   var3_state <= "00";

		end CASE; 
	end IF;

   wait until wclk ='1';
	
end PROCESS;


--process(clk, reset)
  
	--  begin
	  
	  -- Reset NanoFIP if reset button is pressed or error flag is raised 
	 --  if reset = '0' or ERRFLAG = '1' or reset_ack_not_received = '1' then  
		
	--	   RSTIN <= '0';  -- Reset NanoFIP and fieldrive → active low, then wait 8 cycles for confirmation from RSTON signal
		--	RST_O <= '1';	
			
	--		counter_enable <= '1';
	--		reset_confirm_counter <= 0;
	--		reset_ack_not_received <= '0';
		
	--	elsif rising_edge(clk) then 
		
		--	if counter_enable = '1' THEN
		--		reset_confirm_counter <= reset_confirm_counter + 1;
		--	end if;
					
		--	if RSTON = '0' then			
			--			w_state <= "00000";
		--	if reset_confirm_counter = 4 then
		--			RSTIN <= '1';
		--			counter_enable <= '0';
		--	end if;
			--		elsif reset_confirm_counter >= 50 then
			--			reset_ack_not_received <= '1'; -- reset again if not ack, up to 50 cycles 
			--		else
			--			w_state <= "01111"; -- wait until confirmation, up to 50 cycles 
				--	end if;
	--	end if;
					
--end process;

	
	-- **to be checked again - to be improved** 
		   -- If falling edge on var ready signals make sure that you do not access them, set IDLE state 
	--		if (VAR1_RDY = '0' and var1_was = '1' and flag_v1 = '1') or (VAR3_RDY = '0' and var3_was = '1' and flag_v3 = '1') then 
	--			VAR1_ACC <= '0';
	--			VAR2_ACC <= '0';
	--			VAR3_ACC <= '0';
	--			STB_O <= '0';
	--			CYC_O <= '0';
	--			flag_v1 <= '0';
	--			flag_v3 <= '0';
	--			done_v1 <= '0'; --**check again**
	--			done_v3 <= '1'; --**check again**
	--			w_state <= "00000";
	--		end if;

process
  
	begin
	
	if internal_reset = '1' then --or reset_ack_not_received = '1' then 
		
		--w_state <= w_reset; -- State waiting for reset confirmation 
		RSTIN <= '0';  -- Reset NanoFIP and fieldrive → active low
		RST_O <= '0';  -- Wishbone reset 

		VAR1_ACC <= '0';
		VAR2_ACC <= '0';
		VAR3_ACC <= '0';
		STB_O <= '0';
		CYC_O <= '0';
		DAT_I <= (others=>'0');
	
		flag_v1 <= '0';
		flag_v3 <= '0';

		t_counter <= 0; --**check this**

--		reset_confirm_counter <= 0;
--		reset_ack_not_received <= '0';

		done_v1 <= '0';
		done_v3 <= '0';
		ack_counter <= (others=>'0');
		
		LED1 <= '0'; --Testing only 
		LED2 <= '1'; --Testing only 
		LED3 <= '1'; --Testing only 

		w_state <= w_reset_ack; -- Set reset confirmation state		
			
	--elsif rising_edge(wclk) then
	else
	case w_state is
		
	-- Reset confirmation state	
	when w_reset_ack => 	   
						
		RSTIN <= '1'; -- FPGA reset output, active low 
		
		LED1 <= '1'; --Testing only 
		LED2 <= '1'; --Testing only 
		LED3 <= '1'; --Testing only 
		
		w_state <= IDLE;

--		reset_confirm_counter <= reset_confirm_counter + 1;

--		if RSTON = '1' then			
--			w_state <= IDLE;
--		elsif reset_confirm_counter >= 50 then
--			reset_ack_not_received <= '1'; -- reset again if not ack, up to 50 cycles 
--		else
--			w_state <= w_reset; -- wait until confirmation, up to 50 cycles 
		--	w_state <= IDLE;
		--end if;

----------------------------- IDLE state -------------------------- 
	when IDLE => 
				
		VAR1_ACC <= '0';
		VAR2_ACC <= '0';
		VAR3_ACC <= '0';
		STB_O <= '0';
		CYC_O <= '0';
		RST_O <= '0';
		RSTIN <= '1';
		DAT_I <= (others =>'0');
		
		done_v1 <= '0';
		done_v3 <= '0';
		flag_v1 <= '0';
		flag_v3 <= '0';
--		reset_ack_not_received <= '0';

		t_counter <= 0; --**check this**
		
		LED1 <= '0'; --Testing only 
		LED2 <= '0'; --Testing only 
		LED3 <= '0'; --Testing only 

  -- If rising edge of variable1 ready, start read data states 	
		if var1_ready = '1' and VAR1_RDY = '1' and done_v3 = '0' then 	-- done_v1 = '0' is needed in order to stay for at least one clock in IDLE before accessing the other variable, otherwise rare errors 

			done_v1 <= '0';
			flag_v1 <= '1';
			
			ADR_sig(9 downto 7) <= "000"; -- var1
			ADR_sig(6 downto 0) <= "0000010"; -- byte1 memory address
		   
		   WE_O <= '0';	
			
			t_counter <= 0; --**check this**
			
			wishbone_flag_ON <= '1';
			
			w_state <= read_init; --init state
			
		-- If rising edge of variable3 ready, start write data states  					
		elsif var3_ready = '1' and VAR3_RDY = '1' and done_v1 = '0' then -- done_v1 = '0' is needed in order to stay for at least one clock in IDLE before accessing the other variable, otherwise rare errors 

			done_v3 <= '0';						
			flag_v3 <= '1';
			
			ADR_sig(9 downto 7) <= "010"; -- var3 
			ADR_sig(6 downto 0) <= "0000010"; -- byte1 memory address
			
			WE_O <= '1';

			t_counter <= 0; --**check this**
			
			wishbone_flag_ON <= '1';
			
			w_state <= write_init; -- init state

		else 
		
			w_state <= IDLE;
			
		end if;
	
-----------------------------------------------------WRITE FSM STATES-----------------------------------------------------	

----------------- Write init state -----------------
	when write_init => 
					
		CYC_O <= '1';
		WE_O <= '1'; -- write data 
		
		VAR1_ACC <= '0';
		VAR2_ACC <= '0';
		VAR3_ACC <= '1';

		w_state <= write_start; 

----------------- Write start state -----------------
	when write_start => 
				
		CYC_O <= '1'; -- cycle start, multiple read/write commands
		STB_O <= '1'; -- start of phase 1 until ack is high			
		DAT_I <= read_byte_sig(0);
--		DAT_I <= nanofip_var3(0); --byte0
		ADR_sig(9 downto 7) <= "010"; -- var3 
		ADR_sig(6 downto 0) <= "0000010"; -- byte1 memory address

		w_state <= write_wait_ack; 
						
-------------- Wait for write ACK state --------------
	when write_wait_ack => 
				
		ack_counter <= ack_counter + '1';

		if ACK_I = '0' and ack_counter < "00110010" then 
		
			w_state <= write_wait_ack; --wait until ack
			
		else --if ack is high
		
			STB_O <= '0'; --end of phase 1						
			t_counter <= t_counter + 1;
			
			w_state <= write_address; -- when ack is received change memory address
			
		end if;
				
---------------- Write address state -----------------
	when write_address => 
				
		if ADR_sig(6 downto 0) < "1111101" then 
		
			ADR_sig(9 downto 7) <= "010";
			ADR_sig(6 downto 0) <= ADR_sig(6 downto 0) + '1'; --variable3 address 2 --addressing from 2 up to 126-- 
			DAT_I <= read_byte_sig(t_counter);
		--	DAT_I <= nanofip_var3(t_counter); 
			ack_counter <= (others =>'0');
			
			w_state <= write_stb; -- go to STB state 
			
		else 
		
			t_counter <= 0;
			ack_counter <= (others =>'0');
			
			done_v3 <= '1';
			
			w_state <= write_end; -- all memory addresses have been write, go to end state 
			
		end if;				
	
------------------ Write STB state ------------------	
	when write_stb =>
					
		STB_O <= '1';				
		w_state <= write_wait_ack;
	
------- END OF WISHBONE VAR3 ACCESS-- Write END -----
	when write_end =>

		STB_O <= '0';
		VAR1_ACC <= '0';
		VAR2_ACC <= '0';
		VAR3_ACC <= '0';
		CYC_O <= '0';
		
		flag_v3 <= '0';
		
		wishbone_flag_ON <= '0';

		w_state <= IDLE;

		
---------------------------------------------------- READ FSM STATES ----------------------------------------------------	
					
----------------- Read init state -----------------
	when read_init => 
					
		CYC_O <= '1';
		WE_O <= '0'; -- read data 

		VAR1_ACC <= '1';
		VAR2_ACC <= '0';
		VAR3_ACC <= '0';

		w_state <= read_start; 
					
------------------ Read start state -----------------
	when read_start => 
								
		CYC_O <= '1'; -- cycle start -> multiple read/write commands
		STB_O <= '1'; -- start of phase 1 until ack is high
		ADR_sig(9 downto 7) <= "000"; -- var1
		ADR_sig(6 downto 0) <= "0000010"; -- byte1 memory address
		
		w_state <= read_wait_ack; -- wait for ack state 
				  	
--------------- Read wait for ACK state -------------
	when read_wait_ack => 
				
		ack_counter <= ack_counter + '1';

		if ACK_I = '0' and ack_counter < "00110010" then 
		
			w_state <= read_wait_ack; 
			
		else --if ack is high
		
			read_byte_sig(t_counter) <= DAT_O;
			STB_O <= '0'; -- end of read cycle						
			t_counter <= t_counter + 1;
			
			w_state <= read_address;
			
		end if;
							
--------------------- Read address state ----------------
	when read_address =>
				
		if t_counter <= 123 then 
			ADR_sig(6 downto 0) <= ADR_sig(6 downto 0) + '1'; --variable3 address 2 --addressing from 2 up to 126--  
			ack_counter <= (others =>'0');
			
			w_state <= read_stb;
			
		else 
		
			t_counter <= 0;
			ack_counter <= (others =>'0');
			
			done_v1 <= '1';
			
			w_state <= read_end;
			
		end if;
		
---------------------- Read STB -------------------------
	when read_stb =>
					
		STB_O <= '1';				
		w_state <= read_wait_ack;
													
------------ END OF WISHBONE VAR1 ACCESS - Read ----------
	when read_end =>

		STB_O <= '0';
		VAR1_ACC <= '0';
		VAR3_ACC <= '0';
		CYC_O <= '0';
		
		flag_v1 <= '0';
		
		wishbone_flag_ON <= '0';

		w_state <= IDLE;
								
	when others =>	
				
		w_state <= IDLE;

	end case;
	
	end if;

	wait until wclk ='1';
	
end process;


----------------------------------- Update Buffer FSM ----------------------------------
process
  
	   begin 
	  
	   -- upon reset, set the state to A →
	   if internal_reset = '1' then   
			update_state <= "0000";
	 
		else  
	
			CASE update_state IS

				WHEN "0000" => --  when idle
				
					if wishbone_flag_ON = '0' and new_data = '1' then
						data_buffer <= data_memory;
						update_state <= "0001"; -- 
					else
						update_state <= "0000"; -- idle
					end if;
					
				WHEN "0001" =>-- after data copied, still new data flag is '1' because crate clock is much slower than wishbone clock
					if new_data = '0' then
						update_state <= "0000"; -- idle
					else
						update_state <= "0001";
					end if;
					
				WHEN others =>
						update_state <= "0000"; -- idle
				end case;
					
		 END IF; 
		 
		 wait until wclk ='1';
		 
end PROCESS;

--------------------------------- Crate Sequential Statements --------------------------------
process
  
	   begin 
	  
	   -- upon reset, set SCHB to 0
	   if internal_reset = '1' then 
	   
			SCHB_sig <= (others => '0');
	 
		else
		
				if SCHB_sig >= "01110111" then
					new_data <= '1';
					SCHB_sig <= (others => '0');
				else
					new_data <= '0';
					SCHB_sig <= SCHB_sig + '1';
				end if;
						 
				 -- THIS IS ONLY FOR TESTING --
				 if SCHB_sig(3) = '0' then  -- 0 is for upper channel
					if SCHB_sig(2 downto 0) = "000" then
						Top_B0 <= MUX_A;
					elsif SCHB_sig(2 downto 0) = "001" then
						Top_B1 <= MUX_A;
					elsif SCHB_sig(2 downto 0) = "010" then
						Top_B2 <= MUX_A;
					elsif SCHB_sig(2 downto 0) = "011" then
						Top_B3 <= MUX_A;
					elsif SCHB_sig(2 downto 0) = "100" then
						Top_B4 <= MUX_A;
					elsif SCHB_sig(2 downto 0) = "101" then
						Top_B5 <= MUX_A;
					elsif SCHB_sig(2 downto 0) = "110" then
						Top_B6<= MUX_A;
					elsif SCHB_sig(2 downto 0) = "111" then
						Top_B7 <= MUX_A;	
					end if;
				else --if upper_lower_channel = '1' then --1 is for lower channel
					if SCHB_sig(2 downto 0) = "000" then
						Bottom_B0 <= MUX_A;
					elsif SCHB_sig(2 downto 0) = "001" then
						Bottom_B1 <= MUX_A;
					elsif SCHB_sig(2 downto 0) = "010" then
						Bottom_B2 <= MUX_A;
					elsif SCHB_sig(2 downto 0) = "011" then
						Bottom_B3 <= MUX_A;
					elsif SCHB_sig(2 downto 0) = "100" then
						Bottom_B4 <= MUX_A;
					elsif SCHB_sig(2 downto 0) = "101" then
						Bottom_B5 <= MUX_A;
					elsif SCHB_sig(2 downto 0) = "110" then
						Bottom_B6 <= MUX_A;
					elsif SCHB_sig(2 downto 0) = "111" then
						Bottom_B7 <= MUX_A;	
					end if;					
				end if;
				-- THIS WAS ONLY FOR TESTING --
					
					
					--Store data to memory 
					if SCHB_sig(6 downto 0) < "0010000" then
						data_memory(to_integer(unsigned(SCHB_sig(6 downto 0)))) <= MUX_A;
					elsif SCHB_sig(6 downto 0) < "0100000" then
--						data_memory(to_integer(unsigned(SCHB_sig(6 downto 0)))) <= MUX_B;
				   elsif SCHB_sig(6 downto 0) < "0110000" then
--						data_memory(to_integer(unsigned(SCHB_sig(6 downto 0)))) <= MUX_C;
					elsif SCHB_sig(6 downto 0) < "1000000" then
--						data_memory(to_integer(unsigned(SCHB_sig(6 downto 0)))) <= MUX_D;
					elsif SCHB_sig(6 downto 0) < "1010000" then
--						data_memory(to_integer(unsigned(SCHB_sig(6 downto 0)))) <= MUX_E;
					elsif SCHB_sig(6 downto 0) < "1100000" then
--						data_memory(to_integer(unsigned(SCHB_sig(6 downto 0)))) <= MUX_F;
					elsif SCHB_sig(6 downto 0) < "1110000" then
--						data_memory(to_integer(unsigned(SCHB_sig(6 downto 0)))) <= MUX_G;
					elsif SCHB_sig(6 downto 0) < "1111000" then
--						data_memory(to_integer(unsigned(SCHB_sig(6 downto 0)))) <= MUX_H;
					end if;
					
		 end if; 
		 
		 wait until wclk ='1';
		 
end PROCESS;

watchdog_counter_v1: watchdog
generic map(
	width				=> 32
)
port map(
	watchdog_clk		=> wclk, -- **set wishbone clock** 
	en					   => watchdog_enable_v1,
	reset				   => watchdog_reset_v1,
	start_value			=> watchdog_start_value,

	count				   => watchdog_value_v1,
	count_done			=> watchdog_done_v1
);

watchdog_counter_v3: watchdog
generic map(
	width				=> 32
)
port map(
	watchdog_clk		=> wclk, -- **set wishbone clock** 
	en					   => watchdog_enable_v3,
	reset				   => watchdog_reset_v3,
	start_value			=> watchdog_start_value,

	count				   => watchdog_value_v3,
	count_done			=> watchdog_done_v3
);

END RTL;
----------------------------------------- END --------------------------------------------------
