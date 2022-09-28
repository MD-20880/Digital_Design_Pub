library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.common_pack.all;

-- INDENDED BEHAVIOR(Recog_process):
-- Before receive anything from RX, IDLE
-- PATTERN RECOGNIZE
-- If match the pattern, output letter from "patternResult"，Hold current state until recev ready.





entity PatternRecog is
    port(
    clk:		  in std_logic;
    reset:	    in std_logic;
    rxnow:	    in std_logic;
    rxData:	    in std_logic_vector (7 downto 0);
    txdone:	    in std_logic;
    ready:      in std_logic;


    patternResult: out std_logic_vector(7 downto 0);
    numwords_bcd:   out BCD_ARRAY_TYPE(2 downto 0);
    cmd_start:      out STD_LOGIC
    );
end PatternRecog;


architecture pRcog of PatternRecog is
    type state_type is (
        IDLE,
        RCVA,RCVP,RCVL,
        RCVAN,
        RCVANN,
        RCVANNN,
        WAITING_ECHO,
        WAITING_CMD,
        ENDING
    );
    signal nextState: state_type;
    signal RcogState :  state_type := IDLE;
    signal Button :  STD_LOGIC_VECTOR(7 downto 0);








begin
    Rcog_nextState:process(RcogState,txDone,rxnow,ready)
    begin
        case RcogState is
        when IDLE =>
            if rxnow = '1' then
                if rxData(4 downto 0) = "00001" then --A 
                    nextState <= RCVA;
                elsif rxData(4 downto 0) = "10000" then --P
                    nextState <= RCVP;
                elsif rxData(4 downto 0) = "01100" then --L
                    nextState <= RCVL;     
                else
                    nextState<= IDLE;
                end if;
            end if;
        when RCVA =>
        if rising_edge(rxnow) then
            if rxData(7 downto 4) = "0011" then 
                if rxData(3) = '0' or rxData(3 downto 0) = "1001" then
                    nextState <= RCVAN;
                else
                    nextState <= IDLE;
                end if;
            else
                nextState<= IDLE;
            end if;
        end if;
        when RCVAN =>
        if rising_edge(rxnow) then
           if rxData(7 downto 4) = "0011" then --A 
                if rxData(3) = '0' or rxData(3 downto 0) = "1001" then
                    nextState <= RCVANN;
                else
                    nextState <= IDLE;
                end if;
            else
                nextState<= IDLE;
            end if;
        end if;
        when RCVANN =>
        if rising_edge(rxnow) then
            if rxData(7 downto 4) = "0011" then --A 
                if rxData(3) = '0' or rxData(3 downto 0) = "1001" then
                    nextState <= RCVANNN;
                else
                    nextState <= IDLE;
                end if;
            else
                nextState<= IDLE;
            end if;
        end if;
        when RCVANNN =>
            nextState <= WAITING_ECHO;

        when RCVP =>
            nextState <= WAITING_ECHO;

        when RCVL =>
            nextState <= WAITING_ECHO;
            
        when WAITING_ECHO=>
            if rising_edge(txDone) then
              nextState <= WAITING_CMD;
            else 
              nextState <= WAITING_ECHO;
            end if;
        when WAITING_CMD =>
          if rising_edge(ready) then
                nextState <= ENDING;
            else
                nextState <= WAITING_CMD;
            end if;
        when ENDING =>
            nextState <= IDLE;
            
        end case;
    end process;


    stateRegister:process(clk,reset)
    begin
        if rising_edge (clk) then
            if (reset = '1') then
             RcogState <= IDLE;
            else
             RcogState <= nextState;
            end if;
        end if;
    end process;



    --Send byte when in SENDING State
    Pattern_proc:process(clk)
    begin
        if rising_edge(clk) then
            cmd_start <= '0';
            case RcogState is
                when IDLE => 
                    cmd_start <= '0';
                when RCVA =>
                numWords_bcd(2)<= rxData(3 downto 0);
                when RCVAN =>
                numWords_bcd(1)<= rxData(3 downto 0);
                when RCVANN => 
                numWords_bcd(0)<= rxData(3 downto 0);
                when RCVANNN =>                
                  patternResult <= "01000001";                
                when RCVP =>              
                  patternResult <= "01010000";                               
                when RCVL =>              
                  patternResult <= "01001100";                
                when WAITING_ECHO =>
                when WAITING_CMD =>
                  cmd_start <= '1';  
                  
                when ENDING =>
                cmd_start <= '0'; 
                numwords_bcd <= ("0000","0000","0000");
            end case;
          end if;
        end process;
  end pRcog;
    

        
