library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package common_pack2 is
                          
  function to_bcd (in_binary : unsigned(8 downto 0) ) return unsigned;

end package common_pack2;

package body common_pack2 is

  function to_bcd ( in_binary : unsigned(8 downto 0) ) return unsigned is
 
              
        variable bint : unsigned(8 downto 0) := in_binary;
        variable bcd : unsigned(11 downto 0) := (others => '0');
        variable temp : integer :=0;
        variable i : integer:=0;
        

        begin
        for i in 0 to 8 loop  
          bcd(11 downto 1) := bcd(10 downto 0); 
          bcd(0) := bint(8);
          bint(8 downto 1) := bint(7 downto 0);
          bint(0) :='0';


          if(i < 8 and bcd(3 downto 0) > "0100") then 
            bcd(3 downto 0) := bcd(3 downto 0) + "0011";
          end if;

          if(i < 8 and bcd(7 downto 4) > "0100") then 
            bcd(7 downto 4) := bcd(7 downto 4) + "0011";
          end if;

          if(i < 8 and bcd(11 downto 8) > "0100") then 
            bcd(11 downto 8) := bcd(11 downto 8) + "0011";
          end if;

        end loop;
    return bcd;
    end to_bcd;

end package body common_pack2;