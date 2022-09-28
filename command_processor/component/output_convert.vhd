library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

-- INDENDED BEHAVIOR(P_process):
-- before enable, stay at the state IDLE
-- when receved signal enp for at least one clock cycle, set nextState SENDING
-- at SENDING, enable dataOut and dataSend. set nextState Ready
-- at READY, enable ready and disable dataSend. set nextState IDLE.




entity outConvert is
    port(
        convert_sig:        in STD_LOGIC; -- ASSERTION : when enp = '1' , dataResult is asserted to be ready.
        sysclk:         in STD_LOGIC;
        reset:          in STD_LOGIC;
        txdone:         in STD_LOGIC;
        convertNow_sig:      in STD_LOGIC;

        --Data input
        dataResult:     in STD_LOGIC_VECTOR(7 downto 0); -- Asserted to be ready when enp = '1'
        --Data output
        dataOut:        out STD_LOGIC_VECTOR(7 downto 0):= "00000000";  --Output data.
        -- Connected to Output unit.
        dataSend:       out STD_LOGIC:='0';-- Is data Send.
        -- Connected to Output unit. 
        convertdone_sig:          out STD_LOGIC-- Notify CmdProc work done.
        -- Send Event to CmdProc.
    );
end outConvert;


architecture outCom of outConvert is
    type state_type is (IDLE,SENDDATA,SENDSTART,WAITING,SENDDATA2,SENDSTART2,WAITING2,SENDWHOLEDATA,SENDWHOLESTART,WAITINGWHOLE,SENDBLANK,SENDBLANKSTART,WAITINGBLANK,SREADY);
    type asc_type is array(0 to 15) of std_logic_vector(7 downto 0);
    signal asciis : asc_type := ("00110000","00110001","00110010","00110011","00110100","00110101","00110110","00110111","00111000","00111001","01000001","01000010","01000011","01000100","01000101","01000110");
    signal nextState: state_type;
    signal convertState :  state_type := IDLE;








begin
    convert_nextState:process(convertNow_sig, convertState ,txdone)
    begin
        case convertState is
        when IDLE =>
            if rising_edge(convertNow_sig)  then
               if convert_sig = '1' then
                nextState <= SENDDATA;
               else
                nextState <= SENDWHOLEDATA;
               end if;
            else
                nextState <= IDLE;
            end if;
        when SENDDATA =>
            nextState <= SENDSTART;
        when SENDSTART =>
            nextState <= WAITING;
        when WAITING =>
            if rising_edge(txdone) then
                nextState <= SENDDATA2;
            else
                nextState <= WAITING;
            end if;
        when SENDDATA2 =>
            nextState <= SENDSTART2;
        when SENDSTART2 =>
            nextState <= WAITING2;
        when WAITING2 =>
            if rising_edge(txdone) then
                nextState <= SENDBLANK;
            else
                nextState <= WAITING2;
            end if;
        when SENDWHOLEDATA =>
            nextState <= SENDWHOLESTART;
        when SENDWHOLESTART =>
            nextState <= WAITINGWHOLE;
        when WAITINGWHOLE =>
            if rising_edge(txdone) then
                nextState <= SREADY;
            else
                nextState <= WAITINGWHOLE;
            end if;
        when SENDBLANK =>
            nextState <= SENDBLANKSTART;
        when SENDBLANKSTART =>
            nextState <= WAITINGBLANK;
        when WAITINGBLANK =>
            if rising_edge(txdone) then
                nextState <= SREADY;
            else
                nextState <= WAITINGBLANK;
            end if;
        when SREADY =>
            nextState <=IDLE;
        end case;
    end process;


    stateRegister:process(sysclk,reset)
    begin
        if rising_edge (sysclk) then
            if (reset = '1') then
             convertState <= IDLE;
            else
             convertState <= nextState;
            end if;
        end if;
    end process;



    --Send byte when in SENDING State
    send_proc:process(sysclk)
    begin
        if rising_edge(sysclk) then
            case convertState is
                when IDLE => 
                  if convertNow_sig = '1' then
                    convertdone_sig <= '0'; 
                  end if ;
                when SENDDATA =>
                    dataOut <= asciis(to_integer(unsigned(dataResult(7 downto 4)))); --Just put it here for now
                when SENDSTART =>
                    dataSend <= '1';
                when WAITING =>
                    dataOut <= asciis(to_integer(unsigned(dataResult(7 downto 4))));
                    dataSend <= '0';
                when SENDDATA2 => 
                    dataOut <= asciis(to_integer(unsigned(dataResult(3 downto 0))));
                when SENDSTART2 =>
                    dataSend <= '1';
                when WAITING2 =>
                    dataOut <= asciis(to_integer(unsigned(dataResult(3 downto 0))));
                    dataSend <= '0';
                when SENDWHOLEDATA =>
                    dataOut <= dataResult;
                when SENDWHOLESTART => 
                    dataSend <= '1';
                when WAITINGWHOLE =>
                    dataOut <= dataResult;
                    dataSend <= '0';
                when SENDBLANK =>
                    dataOut <= "00100000"; --Just put it here for now
                when SENDBLANKSTART =>
                    dataSend <= '1';
                when WAITINGBLANK =>
                    dataOut <= "00100000";
                    dataSend <= '0';
                when SREADY =>
                  convertdone_sig <= '1';            
            end case;
          end if;
        end process;
  end outCom;