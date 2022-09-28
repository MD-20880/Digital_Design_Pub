library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- INDENDED BEHAVIOR(P_process):
-- before enable, stay at the state IDLE
-- when receved signal enp for at least one clock cycle, set nextState SENDING
-- at SENDING, enable dataOut and dataSend. set nextState Ready
-- at READY, enable ready and disable dataSend. set nextState IDLE.




entity pProc is
    port(
        enp:            in STD_LOGIC; -- ASSERTION : when enp = '1' , dataResult is asserted to be ready.
        sysclk:         in STD_LOGIC;
        reset:          in STD_LOGIC;
        txdone:         in STD_LOGIC;

        --Data input
        dataResult:     in STD_LOGIC_VECTOR(7 downto 0); -- Asserted to be ready when enp = '1'
        --Data output
        dataOut:        out STD_LOGIC_VECTOR(7 downto 0):= "00000000";  --Output data.
        -- Connected to Output unit.
        dataSend:       out STD_LOGIC:='0';-- Is data Send.
        -- Connected to Output unit. 
        ready:          out STD_LOGIC-- Notify CmdProc work done.
        -- Send Event to CmdProc.
    );
end pProc;


architecture pCom of pProc is
    type state_type is (IDLE,SEND,WAITING,SREADY);
    type logical_type is (TRUE, FALSE);
    signal nextState: state_type;
    signal pState :  state_type := IDLE;








begin
    p_nextState:process(enp, pState,txdone)
    begin
        case pState is
        when IDLE =>
            if enp = '0' then
                nextState <= IDLE;
            else
                nextState <= SEND;
            end if;
        when SEND =>
            nextState <= WAITING;
        when WAITING =>
            if rising_edge(txdone) then
                nextState <= SREADY;
            else
                nextState <= WAITING;
            end if;
        when SREADY =>
            nextState <=IDLE;
        end case;
    end process;


    stateRegister:process(sysclk,reset)
    begin
        if rising_edge (sysclk) then
            if (reset = '1') then
             pState <= IDLE;
            else
             pState <= nextState;
            end if;
        end if;
    end process;



    --Send byte when in SENDING State
    send_proc:process(sysclk)
    begin
        if rising_edge(sysclk) then
            case pState is
                when IDLE => 
                  if ENP = '0' then
                    ready <= '0';
                  else 
                    ready <= '0';
                  end if ;
                when SEND =>
                    dataOut <= dataResult; --Just put it here for now
                    dataSend <= '1';
                when WAITING =>
                    dataOut <= dataResult;
                    dataSend <= '0';
                when SREADY => 
                    dataSend <= '0';
                    ready <= '1';
            end case;
          end if;
        end process;
  end pCom;