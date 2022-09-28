library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.common_pack.all;

-- INDENDED BEHAVIOR(P_process):
-- before enable, stay at the state IDLE
-- when receved signal enp for at least one clock cycle, set nextState SENDING
-- at SENDING, enable dataOut and dataSend. set nextState Ready
-- at READY, enable ready and disable dataSend. set nextState IDLE.




entity AProc is
    port(
        ena:            in STD_LOGIC; -- ASSERTION : when enp = '1' , dataResult is asserted to be ready.
        sysclk:         in STD_LOGIC;
        reset:          in STD_LOGIC;

        dataResultForStorage :     out CHAR_ARRAY_TYPE(0 to 6);
        maxIndexForStorage :       out BCD_ARRAY_TYPE(2 downto 0);

        
        
        --Ports connected to Data Processor
        BCD_NUM:        in BCD_ARRAY_TYPE(2 downto 0);
        start:          out STD_LOGIC; -- Notify DataProcessor 
        numWords:       out BCD_ARRAY_TYPE(2 downto 0);
        dataReady:      in STD_LOGIC;
        inputByte:      in STD_LOGIC_VECTOR(7 downto 0);
        maxIndex:       in BCD_ARRAY_TYPE(2 downto 0);
        dataResult:     in CHAR_ARRAY_TYPE(0 to 6);
        seqDone:        in STD_LOGIC;
        
        --Data output
        dataOut:        out STD_LOGIC_VECTOR(7 downto 0);  --Output data.
        -- Connected to Output unit.
        dataSend:       out STD_LOGIC;-- Is data Send(txnow).
        -- Connected to Output unit. 
        ready:          out STD_LOGIC;-- Notify CmdProc work done.
        -- Send Event to CmdProc.
        
        txdone:         in STD_LOGIC

    );
end AProc;


architecture aCom of AProc is
    type state_type is (IDLE,SEND,GET,SREADY,RSREADY,MID,EX);
    type logical_type is (TRUE, FALSE);
    signal nextState: state_type;
    signal aState :  state_type := IDLE;
    --signal reset : integer;
    signal BCDTemp : BCD_ARRAY_TYPE(2 downto 0); -- Store the input numbers in BCD
    signal DataTemp : STD_LOGIC_VECTOR(7 downto 0);

    signal Flag : integer := 0; -- for the last round



begin
    a_nextState:process(ena, aState, txdone,dataReady,seqDone)
    begin
        case aState is
        when IDLE =>
            if ena = '1' then
                nextState <= SEND;
            else
                nextState <= IDLE;
            end if;
        when SEND =>
            -- get prepared from Rx
            BCDTemp <= BCD_NUM; -- Access to BCD_NUM
            numWords <= BCDTemp;
            nextState <= GET;
        
        when GET =>
            if dataReady = '1' then
                -- get data from data processor
                DataTemp <= inputByte;
                nextState <= SREADY;
            else
                nextState <= GET;
            end if;
        when SREADY =>
            -- output  data to txsending
            dataOut <= DataTemp;
            nextState <= RSREADY;
            
        when RSREADY =>
        -- if this is the last piece of data, store dataResult and maxIndex?then go for the last round
           if Flag = 1 AND rising_edge(txdone) then
                nextState <= EX;-- last round, go to the final cycle
            elsif seqDone = '1' then
                dataResultForStorage <= dataResult;
                maxIndexForStorage <= maxIndex;
                Flag <= 1; -- signal for last round
                nextState <= MID;
            elsif rising_edge(txdone) then -- Tx finished 1/7 of data, continue in loop
                nextState <= MID;
            else
                nextState <= RSREADY;
            end if;

        -- state for continue the loop
        when MID =>
            nextState <= SEND;

        -- state for finish
        when EX =>
            Flag <= 0; -- reset
            nextState <= IDLE;
        end case;
    end process;


    
    -- for changing the state
    stateRegister:process(sysclk,reset)
    begin
        if rising_edge (sysclk) then
            if (reset = '1') then
                aState <= IDLE;
            else
                aState <= nextState;
            end if;
        end if;
    end process;


    -- IDLE , Ready = 1
    -- ENA , Ready = 0
    -- Ready back to 1 when it's all done.
    -- all sync is done
    --TODO:
    -- check is it valid to skip stages that do nothing with sysclk signal(e.g. RSREADY is not covered in get_proc)
    get_proc:process(sysclk)
    begin
        if rising_edge(sysclk) then
            dataSend <= '0';
            start <= '0';
            case aState is
                when IDLE =>
                    ready <= '0';
                when SEND =>
                    start <= '1';
                    
                when GET =>
                when SREADY => 
                    dataSend <= '1';
                when RSREADY =>
                    
                when MID =>
                    start <= '0';
                    dataSend <= '0';
                when EX =>
                    --Flag <= 0; -- reset
                    --This Line Cause Bug 
                    --copy it into line 113
                    ready <= '1';
                    start <= '0';
                    dataSend <= '0';
            end case;
            end if;
        end process;
    end aCom;