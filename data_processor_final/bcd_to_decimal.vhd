library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.std_logic_unsigned.ALL;
use work.common_pack.ALL;

--this module is for converting a 3 digit BCD number into decimal number. 
--the range of the input in decimal is 0 to 999.


entity bcd_2_dec is
    
Port ( bcd_in : in BCD_ARRAY_TYPE (2 downto 0);
           dec_out : out integer range 0 to 999);

end entity bcd_2_dec;

architecture Behavioral of bcd_2_dec is

	signal bcd_in_0: std_logic_vector (3 downto 0);
	signal bcd_in_10: std_logic_vector (3 downto 0);
	signal bcd_in_100: std_logic_vector (3 downto 0);
begin

	bcd_in_0 <= bcd_in (0) ;
	bcd_in_10 <= bcd_in (1) ;
	bcd_in_100 <= bcd_in (2);
	
		
	dec_out <= conv_integer(unsigned(bcd_in_0))  --multiply by 1
                 	+ conv_integer(unsigned(bcd_in_10))*10 --multiply by 10
                 	+ conv_integer(unsigned(bcd_in_100))*100 AFTER 5 ns; --multiply by 100
            
end Behavioral;
