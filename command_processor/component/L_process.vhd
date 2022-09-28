library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.common_pack.all;
-- INDENDED BEHAVIOR(P_process):
-- before enable, stay at the state IDLE
-- when receved signal enp for at least one clock cycle, set nextState SENDING
-- at SENDING, enable dataOut and dataSend. set nextState Ready
-- at READY, enable ready and disable dataSend. set nextState IDLE.




entity lProc is
    port(
        enl:            in STD_LOGIC; -- ASSERTION : when enp = '1' , dataResult is asserted to be ready.
        sysclk:         in STD_LOGIC;
        reset:          in STD_LOGIC;
        txdone:         in STD_LOGIC;

        --Data input
        dataResult:     in CHAR_ARRAY_TYPE(0 to 6); -- Asserted to be ready when enp = '1'  **
        --Data output
        dataOut:        out STD_LOGIC_VECTOR(7 downto 0):= "00000000";  --Output data.
        -- Connected to Output unit.
        dataSend:       out STD_LOGIC:='0';-- Is data Send.
        -- Connected to Output unit. 
        ready:          out STD_LOGIC-- Notify CmdProc work done.
        -- Send Event to CmdProc.
    );
end lProc;


architecture lCom of lProc is
    type state_type is (IDLE,SEND,WAITING,SREADY);
    signal nextState: state_type;
    signal lState :  state_type := IDLE;
    signal num_bit_send: INTEGER := 0;
    signal base: INTEGER := 0;








begin
    l_nextState:process(enl, lState,num_bit_send,txdone)
    begin
        case lState is
        when IDLE =>
            if enl = '0' then
                nextState <= IDLE;
            else
                nextState <= SEND;
            end if;
        when SEND =>
                nextState <= WAITING;
        when WAITING =>
            if rising_edge(txdone) then
                if num_bit_send = 7 then
                    nextState <= SREADY;
                else 
                    nextState <= SEND;
                end if;
            else
                nextState <= WAITING;
            end if;
        when SREADY =>
            nextState <= IDLE;
        end case;
    end process;


    stateRegister:process(sysclk,reset)
    begin
        if rising_edge (sysclk) then
            if (reset = '1') then
             lState <= IDLE;
            else
             lState <= nextState;
            end if;
        end if;
    end process;



    --Send byte when in SENDING State
    send_proc:process(sysclk)
    begin
        if rising_edge(sysclk) then
            case lState is
                when IDLE => 
                if enl = '0' then
                  ready <= '0';
                else 
                  ready <= '0';
                end if ;
                when SEND =>
                    -- Maybe It is better to have a shift register here. But we just leave it here now any try if it can run.
                  if num_bit_send<8 then
                    dataOut <= dataResult(num_bit_send); --Just put it here for now
                    dataSend <= '1';
                    num_bit_send <= num_bit_send +1;
                  end if ;
                when WAITING =>
                  dataSend <= '0';
                when SREADY => 
                    dataSend <= '0';
                    ready <= '1';
                    num_bit_send <= 0;
            end case;
          end if;
        end process;
  end lCom;
    

        

