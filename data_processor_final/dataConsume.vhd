library ieee;
use ieee.std_logic_1164.all;
use work.all;
use common_pack.all;

use ieee.numeric_std.all;
use common_pack2.all;

use ieee.std_logic_signed.">"; -- overload the < operator for std_logic_vectors
use ieee.std_logic_signed."="; -- overload the = operator for std_logic_vectors


-- intended behavior:
-- 1. starts itself when start = 1 and numWords is between 0-999
-- 2. bcd_to_decimal converts numWords to integer, then port maps into Tcount
-- for counter_data_processor
-- 3. sends request to dataGen and detects (datavalid) return using delay_ctrlIn
-- 4. ctrlIn translates to ctrlIn_valid in counter and increments by one
-- 5. sends data to casper and counterIncrement goes high for 1 clock cycle
-- 6. wait for start signal to go high again, then sends another request (repeat step 2)

entity dataConsume is 
	port (
		clk: in std_logic;
		reset: in std_logic;
		ctrlIn: in std_logic; -- producer signals data valid
		start: in std_logic; -- data retrieval should start taking place
		numWords_bcd: in BCD_ARRAY_TYPE (2 downto 0); -- number of words needed to be retrieved (BCD)
		data: in std_logic_vector (7 downto 0); -- data in from dataGenerator
		ctrlOut: out std_logic; -- consumer signals data required
		dataReady: out std_logic; -- high if data in != 0
		byte: out std_logic_vector (7 downto 0); --default value should be dataIn
		seqDone: out std_logic; -- goes high for 1 cycle if EVERYTHING is ready
		maxIndex: out BCD_ARRAY_TYPE(2 downto 0);
    dataResults: out CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1)
		);

end entity dataConsume;

architecture behavioral of dataConsume is 


-- include bcd_2_dec converter component
  component bcd_to_decimal is
    port (
    bcd_in: in BCD_ARRAY_TYPE (2 downto 0);
    dec_out: out integer range 0 to 999
    );
  end component bcd_to_decimal;

  for CONV: bcd_to_decimal use entity WORK.bcd_2_dec(Behavioral);


-- casper's part ------------------------------------------
   component comparator is
    	port (
  	  data1: in std_logic_vector(7 downto 0);
  		data2: in std_logic_vector(7 downto 0);
  		grtThan: out std_logic;
  		equal: out std_logic
    	);
  end component;
  
  for comp: comparator use entity WORK.comparator(twos_comp);
  
  -- 2 registers for storing data
  SIGNAL result_reg, cur_reg: CHAR_ARRAY_TYPE (6 downto 0) := (X"00",X"00",X"00",X"00",X"00",X"00",X"00");

  
  -- counter for casper
  SIGNAL count2: Integer := 0; -- need to deal with it in comb_out, used for appending dataResults
  
  -- index for maximum data value
  SIGNAL countResult: Integer := 0;
  
  -- current running count (?)
  SIGNAL countCurr: Integer := -1;
  
  
  -- SIGNAL convert_en: std_logic; probably don't need this
  SIGNAL bcd_array: BCD_ARRAY_TYPE(2 downto 0);
  
  -- append enable
  SIGNAL append_en: std_logic;
  
  -- replace enable
  SIGNAL replace_en: std_logic;
  
  -- compare greater than logic
  SIGNAL grtThan: std_logic;
  
  -- compare equal logic
  SIGNAL equal: std_logic;
-----------------------------------------------------------------  
  
    
	-- Build enumerated state types
	type State_Type is (INIT, consumerReq, peakDetect, pending); -- changes here
	 
	
	-- numWords but in decimal format
	signal numWords_dec: integer range 0 to 999;

	-- register to hold current state 
	signal curState, nextState : State_Type;
	
	-- current running count
  signal count: integer range 0 to 999:= 0;

	-- enCount for enable, countReach is a local(internal) variable of countDone
  signal countDone: std_logic:= '0';

	-- total count: default set to numWords
	signal Tcount: integer range 0 to 999;
	
	-- reset for when jumping back to INIT / fell into unkonwn state
	signal localReset: bit;
	
	-- ctrlIn delayed by 1 clock cycle (for transition detecting purpose)
	signal ctrlIn_delayed: std_logic;

	-- ctrl transition detected (used to signal dataReady)
	signal ctrlIn_detected: std_logic;

	-- Register ctrl Out
	signal ctrlOut_reg: std_logic:= '0';
	
	-- process Done
	signal procDone: std_logic:= '0'; 
	
begin
  
-- casper's part ---------------------------------------------- 
shift : process(clk)
begin
  if rising_edge(clk) then
    if ctrlIn_detected = '1' then
      for i in 6 downto 1 loop 
          cur_reg(i) <= cur_reg(i-1); -- SHIFT ALL BITS UP 1
      end loop;
      cur_reg(3) <= data;  
      countCurr <= countCurr + 1;
    end if;
  end if;
  
  if localReset = '1' then
      cur_reg <= (X"00",X"00",X"00",X"00",X"00",X"00",X"00");
      countCurr <= -1;
  end if;
end process;


replace : process(clk, curState)
begin
  if curState = peakDetect then
    if rising_edge(clk) then
      if replace_en = '1' then
        result_reg(6 downto 0) <= cur_reg(6 downto 0);
        countResult <= countCurr;
        procDone <= '1';       
      elsif append_en = '1' then
        if count2 < 4 then
          result_reg(3 - count2) <= cur_reg(3);
          procDone <= '1';
        end if;
      end if;
    end if;
  end if;
  
  if localReset = '1' then
      result_reg <= (X"00",X"00",X"00",X"00",X"00",X"00",X"00");
      countResult <= 0;
  end if;
end process;


bcd_converter: process(ctrlin_detected)
  variable temp: unsigned(8 downto 0); -- 9 bits because the maximum number it can be is 511
  variable temp2: std_logic_vector(11 downto 0);
begin
  if ctrlin_detected='1' then  
    temp := to_unsigned(countResult, 9);
    temp2 := std_logic_vector(to_bcd(temp));  
    bcd_array(2) <= temp2(11 downto 8);
    bcd_array(1) <= temp2(7 downto 4);
    bcd_array(0) <= temp2(3 downto 0);
  else null;
  end if;
end process;

  
	-- next state logic
	combi_nextState: process(curState, ctrlIn_detected, start, procDone)

		BEGIN
			CASE curState IS

	      			WHEN INIT =>
	            			IF start = '1' THEN 
	              				nextState <= consumerReq;
	            			ELSE
	              				nextState <= INIT; 
	            			END IF;
	              
	         WHEN consumerReq =>
	            			IF ctrlIn_detected ='1' THEN
	              				nextState <= peakDetect;
	            			ELSE
	              				nextState <= consumerReq;
	            			END IF;

	         WHEN peakDetect =>
	               IF procDone = '1' then
	                 nextState <= pending;
	               else 
	                 nextState <= peakDetect;
	                end if;	               
	               
	         WHEN pending =>      
	               if start = '1' then
	                 nextState <= consumerReq;
	               else
	                 nextState <= INIT;
	               end if;	              			           
	        	END CASE;
	     END PROCESS; 
		
	
	main_Counter: process(clk, reset, ctrlIn_detected, count)
    begin
    
    -- assign default value
    countDone <= '0';
    
    -- global reset
    if (reset = '1')then
      count <= 0;
    elsif(clk'event AND clk='1') then
    
    -- allow counting only if ctrlIn_reg is high
      if (ctrlIn_detected='1') then
        count <= count + 1;
       
      else
        count <= count;
       
      end if;   
    end if; 
    
    -- if total count is reached, move to "Done" state and send countReached
    if count = Tcount then
      countDone <= '1';     
    else 
      Null;      
    end if;
         
    -- local reset
    if localReset = '1' then
      count <= 0;    
    end if;
      
  end process main_Counter;
        
  
  -- asynchronous combination out logic
  combi_Out: process (countDone, curState, grtThan, equal)
    variable temp2: CHAR_ARRAY_TYPE (0 to 6);
    BEGIN
      
      replace_en <= '0';
      append_en <= '0';
      seqDone <= '0';
      seqDone <= '0';
      localReset<='0';
      --conditions needed to be met
      if (countDone = '1') AND (curState = pending) then
        temp2(0) := result_reg(0);
        temp2(1) := result_reg(1);
        temp2(2) := result_reg(2);
        temp2(3) := result_reg(3);
        temp2(4) := result_reg(4);
        temp2(5) := result_reg(5);
        temp2(6) := result_reg(6); 
        dataResults <= temp2;
        maxIndex <= bcd_array;
        seqDone <= '1';
        localReset<='1';
      elsif (curState = peakDetect) and (grtThan = '1' or equal = '1') then
          replace_en <= '1';
          count2 <= 0;
      elsif (curState = peakDetect) then
          append_en <= '1';
          if count2 < 4 then
            count2 <= count2 + 1;
          end if;      
      elsif curState = pending then
        dataReady <= '1';
        byte <= data;           
      end if;
                                  
  end process combi_Out;
  -----------------------------------------------------
	-----------------------------------------------------		
  
  
  -- runs at consumerReq
  phase_1_handshake: process (curState)
   begin 
        if (curState = consumerReq) then
          ctrlOut_reg <= not ctrlOut_reg;
        end if;
    
  end process phase_1_handshake;
  ctrlOut <= ctrlOut_reg;
  -----------------------------------------------------
	-----------------------------------------------------		


  -- runs at clock cycle (state change)
	seq_state: PROCESS (clk, reset)
		BEGIN
	        IF reset = '1' THEN
	          curState <= INIT;
	        ELSIF clk'event AND clk='1' THEN
	          curState <= nextState;
	        END IF;
	END PROCESS; -- seq
 -----------------------------------------------------
 -----------------------------------------------------
 
 
  phase_2_handshake: PROCESS(clk)
	  BEGIN
	    
	    IF clk'event AND clk='1' THEN
	       ctrlIn_delayed <= ctrlIn;
	         
	    END IF;
	
	END PROCESS phase_2_handshake;
	ctrlIn_detected <= ctrlIn_delayed xor ctrlIn; 
 -----------------------------------------------------
 -----------------------------------------------------
 
 
 CONV: bcd_to_decimal port map (
   bcd_in => numWords_bcd,
   dec_out => Tcount
 );
 
 comp: comparator port map (
   data1 => cur_reg(3),
   data2 => result_reg(3),
   grtThan => grtThan,
   equal => equal
 );
 
END;


	