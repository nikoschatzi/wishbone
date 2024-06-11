library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity watchdog is
	generic(
		width		    : integer:=32
	);
	port(
		watchdog_clk : in std_logic;
		en		       : in std_logic;
		reset		    : in std_logic;
		start_value	 : in std_logic_vector(width-1 downto 0);
	
		count		    : out std_logic_vector(width-1 downto 0);
		count_done	 : out std_logic
	);
	
end watchdog;

architecture archi of watchdog is

--attribute syn_radhardlevel of archi:architecture is "none";

signal watchdog_value	   : std_logic_vector(width-1 downto 0):=(others=>'0');
constant zeroes	         : std_logic_vector(width-1 downto 0):=(others=>'0');
signal one	               : std_logic_vector(width-1 downto 0);

begin

	decount: process
	begin
	
		if reset = '1' then		
			watchdog_value   <= start_value;		
		elsif en = '1' and watchdog_value > zeroes then 
			watchdog_value	<= watchdog_value - "1";
		end if;
		
		wait until watchdog_clk='1';
	
	end process;


	count	<= watchdog_value;

	one	<= zeroes + "1";

	redundant: process
	begin
		if reset = '1' then
			count_done	<= '0';
		elsif en ='1' and watchdog_value = one then	
            count_done	<= '1';
		elsif watchdog_value = zeroes then
            count_done	<= '1';
		else
			count_done	<= '0';
		end if;
      wait until watchdog_clk = '1';
	end process;

end archi;
