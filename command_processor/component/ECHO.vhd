library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- INDENDED BEHAVIOR(P_process):
-- before enable, stay at the state IDLE
-- when receved signal enp for at least one clock cycle, set nextState SENDING
-- at SENDING, enable dataOut and dataSend. set nextState Ready
-- at READY, enable ready and disable dataSend. set nextState IDLE.




entity echo is
    port(
        sysclk:         in STD_LOGIC;
        reset:          in STD_LOGIC;



        txdone:         in STD_LOGIC;

        --Ports connected to Rx
        rxdone:         out STD_LOGIC;
        rxData:       in STD_LOGIC_VECTOR(7 downto 0);
        rxnow:        in STD_LOGIC;
        --Data output
        dataOut:        out STD_LOGIC_VECTOR(7 downto 0);  --Output data.
        -- Connected to Output unit.
        dataSend:       out STD_LOGIC -- Is data Send.
        -- Connected to Output unit. 
        );
end echo;


architecture echo_1 of echo is

    type state_type is (IDLE,SEND,BEFORE_WAIT,WAITING,SREADY,FINALSET);
    signal nextState: state_type;
    signal echoState :  state_type := IDLE;




  begin
    
    echo_nextState:process(echoState,txdone,rxnow)
    begin
        case echoState is
        when IDLE =>
            if rxnow = '0' then
                nextState <= IDLE;
            else
                nextState <= SEND;
            end if;
        when SEND =>
            nextState <= BEFORE_WAIT;
        when BEFORE_WAIT =>
            nextState <= WAITING;
        when WAITING =>
            if txdone = '1' then
                nextState <= SREADY;
            else
                nextState <= WAITING;
            end if;
        when SREADY =>
            nextState <=FINALSET;
        when FINALSET =>
            nextState <= IDLE;
        end case;
    end process;


    stateRegister:process(sysclk,reset)
    begin
        if rising_edge (sysclk) then
            if (reset = '1') then
             echoState <= IDLE;
            else
             echoState <= nextState;
            end if;
        end if;
    end process;



    --Send byte when in SENDING State
    send_proc:process(sysclk)
    begin
        if rising_edge(sysclk) then
            dataSend <= '0';
            case echoState is
                when IDLE => 
                    rxdone <= '0';
                when SEND =>
                    dataOut <= rxData; --Just put it here for now
                    dataSend <= '1';
                when BEFORE_WAIT =>
                when WAITING =>
                    dataOut <= rxData;
                when SREADY => 
                    dataSend <= '0';
                    rxdone <= '1';
                when FINALSET =>
                    rxdone <= '0';
            end case;
          end if;
        end process;
  end echo_1;