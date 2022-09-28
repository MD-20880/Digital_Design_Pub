library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.common_pack.all;

--CmdProc is the synthesization of all component.


--INTENDED BEHAVIORS(CmdProc):
--before any input from RX ,Stay IDLE
--When rxnow = '1', set nextState RECOG;
--When RECOG, set rxdone = '1', recognize input character and set nestState to corresponding state. ECHO OUTPUT RESULT
--When STATES, set rxdone = '0' for each clock cycle, set ready = '0' and stay at this state. When ready  = '1' set nextState IDLE.


--Processes :
-- CmdProc: Main process, manage other processes.
-- pRcog : Pattern Recognize Process, Receive and recognize pattern from RX Unit. Send recognized numbers to BCD_NUM SIGNAL
-- converter: Output proxy, receive Data and output data in different formats according to requirement.
-- output_sel: Select output to converter according to current working component.
-- A_Process: Process handle command A
-- P_Process: Process handle command P
-- L_Process: Process handle command L
-- ECHO: Process Echo every input from RX Unit( when IDLE )



--Standards:
--1. If any process want to use Tx_Sending process, it must finish start/end cycle inside the process.
--2. Each process need to set ready = '1' after they complete their task for 1 clock cycle.
--3. When reset, Each component must response to it immediately.

entity cmdProc is
    port (
      clk:		    in std_logic;
      reset:	    in std_logic;
      rxnow:	    in std_logic;
      rxData:	    in std_logic_vector (7 downto 0);
      txData:	    out std_logic_vector (7 downto 0);
      rxdone:	    out std_logic;
      ovErr:	    in std_logic;
      framErr:	    in std_logic;
      txnow:	    out std_logic;
      txdone:	    in std_logic;
      start:        out std_logic;
      numWords_bcd: out BCD_ARRAY_TYPE(2 downto 0);
      dataReady:    in std_logic;
      byte:         in std_logic_vector(7 downto 0);
      maxIndex:     in BCD_ARRAY_TYPE(2 downto 0);
      dataResults:  in CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
      seqDone:      in std_logic
    );
  end cmdProc;
  


architecture cmdRX of cmdProc is

    ----------------- COMPONENTS-------------------------------
    component AProc is
        port(
        ena:            in STD_LOGIC;
        sysclk:         in STD_LOGIC;
        reset:          in STD_LOGIC;

        dataResultForStorage :     out CHAR_ARRAY_TYPE(0 to 6);
        maxIndexForStorage :       out BCD_ARRAY_TYPE(2 downto 0);

        BCD_NUM:        in BCD_ARRAY_TYPE(2 downto 0);
        start:          out STD_LOGIC; 
        numWords:       out BCD_ARRAY_TYPE(2 downto 0);
        dataReady:      in STD_LOGIC;
        inputByte:      in STD_LOGIC_VECTOR(7 downto 0);
        maxIndex:       in BCD_ARRAY_TYPE(2 downto 0);
        dataResult:     in CHAR_ARRAY_TYPE(0 to 6);
        seqDone:        in STD_LOGIC;
        
        dataOut:        out STD_LOGIC_VECTOR(7 downto 0); 
        dataSend:       out STD_LOGIC;
        ready:          out STD_LOGIC;
        
        txdone:         in STD_LOGIC

    );
    end component;

    component pProc is 
        port(
        enp:            in STD_LOGIC; 
        sysclk:         in STD_LOGIC;
        reset:          in STD_LOGIC;
        txdone:         in STD_LOGIC;

        dataResult:     in STD_LOGIC_VECTOR(7 downto 0);
        dataOut:        out STD_LOGIC_VECTOR(7 downto 0);
        dataSend:       out STD_LOGIC;
        ready:          out STD_LOGIC
        );
        end component;

     component lProc is 
        port(
        enl:            in STD_LOGIC;
        sysclk:         in STD_LOGIC;
        reset:          in STD_LOGIC;
        txdone:         in STD_LOGIC;

        dataResult:     in CHAR_ARRAY_TYPE(0 to 6); 
        dataOut:        out STD_LOGIC_VECTOR(7 downto 0); 
        dataSend:       out STD_LOGIC;
        ready:          out STD_LOGIC
        );
        end component;


    component PatternRecog is
    port(
        clk:		in std_logic;
        reset:	    in std_logic;
        rxnow:	    in std_logic;
        rxData:	    in std_logic_vector (7 downto 0);
        txdone:	    in std_logic;
        ready:      in std_logic;


        patternResult: out std_logic_vector(7 downto 0);
        numwords_bcd:   out BCD_ARRAY_TYPE(2 downto 0);
        cmd_start:      out STD_LOGIC
    );
    end component;



    
    component selector is
        port(
        ena,enp,enl:    in STD_LOGIC;
        reset:          in STD_LOGIC;
        ready_in:          in STD_LOGIC;

        
        A_OUT,P_OUT,L_OUT,CMD_OUT: in STD_LOGIC_VECTOR(7 downto 0);
        A_DATA_SEND,P_DATA_SEND,L_DATA_SEND,CMD_DATA_SEND: in STD_LOGIC;
        A_READY,P_READY,L_READY,CMD_READY: in STD_LOGIC;

        dataOut:        out STD_LOGIC_VECTOR(7 downto 0);  
        dataSend:       out STD_LOGIC;
        convert:        out STD_LOGIC;
        
        ready:          out STD_LOGIC
    );
    end component;

    component outConvert is
        port(
            convert_sig:        in STD_LOGIC; 
            sysclk:         in STD_LOGIC;
            reset:          in STD_LOGIC;   
            txdone:         in STD_LOGIC; 
            convertNow_sig:      in STD_LOGIC; -- original txnow
    

            dataResult:     in STD_LOGIC_VECTOR(7 downto 0); 
            dataOut:        out STD_LOGIC_VECTOR(7 downto 0);
            dataSend:       out STD_LOGIC:='0';

            convertdone_sig:    out STD_LOGIC-- original txdone
        );
    end component;


    component echo is
        port(
            sysclk:         in STD_LOGIC;
            reset:          in STD_LOGIC;
            txdone:         in STD_LOGIC;
            --Ports connected to Rx
            rxdone:         out STD_LOGIC;
            rxData:          in STD_LOGIC_VECTOR(7 downto 0);
            rxnow:            in STD_LOGIC;
            --Data output
            dataOut:        out STD_LOGIC_VECTOR(7 downto 0);  --Output data.
            -- Connected to Output unit.
            dataSend:       out STD_LOGIC-- Is data Send.
            -- Connected to Output unit. 
        );
    end component;
    -----------------END COMPONENTS--------------------------

    ----------------SIGNALS-----------------------------------
    
    --State Related Signals
    type state_type is (IDLE,RECOG,WAITING);
    signal currentState, nextState: state_type; 
    signal isIDLE: STD_LOGIC;

    --Receive pattern from pRcog Unit 
    signal PATTERN_IN:STD_LOGIC_VECTOR(7 downto 0);
    signal CMD_START: STD_LOGIC;

    --Enabling Signals
    signal ENA,ENL,ENP:std_logic := '0' ;        --Acitivate corresponiding Process.

    --Signals as storage
    signal DATA_RESULT: CHAR_ARRAY_TYPE(0 to 6);-- Store 7 bytes peak from Data Processor and sotre it.
    signal MAX_INDEX: BCD_ARRAY_TYPE(2 downto 0);-- Store the Peak retured from Data Processor.
    signal BCD_NUM:BCD_ARRAY_TYPE(2 downto 0); -- Store the input numbers in BCD
    
    --Ready Signals
    signal READY: std_logic; -- this signal goes low once an operation has begun and remains low until it has completed and another ooperation is ready,set high for one cycle when work done.
    signal A_READY,P_READY,L_READY,CMD_READY:std_logic := '1';

    --Output Signals
    signal A_OUT,P_OUT,L_OUT,CMD_OUT: std_logic_vector(7 downto 0);
    signal A_DATA_SEND,P_DATA_SEND,L_DATA_SEND,CMD_DATA_SEND:std_logic:='0';
    
    --Converter related Signals
    signal convert, convertdone,convertNow: STD_LOGIC;
    signal convertData: std_logic_vector(7 downto 0);

    -------------------END SIGNALS------------------------------
    

    begin
    --State logic
    cmd_nextState:process(currentState,ENA,ENP,ENL,READY,CMD_START)
      variable ezASCII : std_logic_vector(4 downto 0);
    begin
        case currentState is
        When IDLE =>
            IF rising_edge(CMD_START) then
                nextState <= RECOG;
            else
                nextState <= IDLE;
            end if;
        When RECOG =>
               ezASCII := PATTERN_IN(4 downto 0);
                if ezASCII = "00001" then --A delete capital
                    nextState <= WAITING;
                elsif ezASCII = "10000" then --P
                    nextState <= WAITING;
                elsif ezASCII = "01100" then --L
                    nextState <= WAITING;
                else
                    nextState <= IDLE;
                end if;                
        When WAITING =>
            IF READY = '0' then
                nextState <= WAITING;
            else
                nextState <= IDLE;
            end if; 
        end case;
    end process;

    --Sycronize state with clock.
    stateRegister:process(clk,reset)
    begin
        if rising_edge (clk) then
			if (reset = '1') then
				currentState <= IDLE;
			else
				currentState <= nextState;
			end if;	
		end if;
    end process;

    cmd_output:process(clk,reset,READY)
      variable ezASCII : std_logic_vector(4 downto 0);
    begin
        case currentState is
            when IDLE =>
                isIDLE <= '1';
            when RECOG =>
                isIDLE <= '0';
                ezASCII := PATTERN_IN(4 downto 0);
                if ezASCII = "00001" then --A 
                    ENA <= '1';
                elsif ezASCII = "10000" then --P
                    ENP <= '1';
                elsif ezASCII = "01100" then --L
                    ENL <= '1';     
                else
                    ENA <= '0';
                    ENP <= '0';
                    ENL <= '0';
                end if;

            when WAITING =>
            ENA <= '0';
            ENP <= '0';
            ENL <= '0';
        end case;
    end process;




    -----PATTERN RECOG COMPONENT ----------
    pRcog: PatternRecog port map(clk => clk,
        reset => reset,
        rxnow => rxnow,
        rxData => rxData,
        txdone => convertdone,
        ready => ready,
        patternResult => PATTERN_IN,
        numwords_bcd => BCD_NUM,
        cmd_start => CMD_START
    );
    

            

    
    ------A PROC---------------------------
    A_proc : AProc port map(
        ena => ena,
        sysclk => clk,
        reset => reset,
        dataResultForStorage => DATA_RESULT,
        maxIndexForStorage => MAX_INDEX,
        BCD_NUM => BCD_NUM,
        start => start,
        numWords => numwords_bcd,
        dataReady => dataReady,
        inputByte => byte,
        maxIndex => maxIndex,
        dataResult => dataResults,
        seqDone => seqDone,
        dataOut => A_OUT,
        dataSend => A_DATA_SEND,
        ready => A_READY,
        txdone => convertdone
    );


   --------------P PROC----------------
    p_proc : pProc port map(ENP => enp,
        sysclk => clk,
        reset => reset,
        txdone => convertdone,
        dataResult =>  DATA_RESULT(3),
        dataOut => P_OUT,
        dataSend => P_DATA_SEND,
        ready => P_READY
        );


    -------------L PROC----------------
    l_proc : lProc port map(ENL => enl,
        sysclk => clk,
        reset => reset,
        txdone => convertdone,
        dataResult => DATA_RESULT,
        dataOut => L_OUT,
        dataSend => L_DATA_SEND,
        ready => L_READY
        );


   ------------OUTPUT SELECTOR----------------
    output_sel : selector port map(
        ena => ENA,
        enp => ENP,
        enl => ENL,
        reset => reset,
        ready_in => isIDLE,
        A_OUT => A_OUT,
        P_OUT => P_OUT,
        L_OUT => L_OUT,
        CMD_OUT => CMD_OUT,
        A_DATA_SEND => A_DATA_SEND,
        P_DATA_SEND => P_DATA_SEND,
        L_DATA_SEND => L_DATA_SEND,
        CMD_DATA_SEND=>CMD_DATA_SEND,
        A_READY => A_READY,
        P_READY => P_READY,
        L_READY => L_READY,
        CMD_READY => CMD_READY,
        dataOut => convertData,
        dataSend => convertNow,
        ready => READY,
        convert => convert
    );
    ----------------OUTPUT CONVERTER -------------------
    outconv : outConvert port map(convert_sig => convert,
        sysclk => clk,
        reset => reset,
        txdone => txdone,
        convertNow_sig => convertNow,
        dataResult => convertData,
        dataOut => txData,
        dataSend => txnow,
        convertdone_sig => convertdone
        );

    --------------ECHO----------------------
    echo_comp : echo port map(
        sysclk => clk,
        reset => reset,
        txdone => convertdone,
        rxdone => rxDone,
        rxData => rxData,
        rxnow => rxnow,
        dataOut => CMD_OUT,
        dataSend => CMD_DATA_SEND
    );
        
end cmdRX;







    


