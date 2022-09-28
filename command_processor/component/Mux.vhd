library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


-- INTENDED RESULT: TO OUTPUT CORRESPONDING OUTPUT ACCORDING TO CURRENT PROCESS


entity selector is
    port(
        ena,enp,enl:    in STD_LOGIC; -- ASSERTION : when enp = '1' , dataResult is asserted to be ready.
        reset:          in STD_LOGIC;
        ready_in:          in STD_LOGIC;

        --Data input
        A_OUT,P_OUT,L_OUT,CMD_OUT: in STD_LOGIC_VECTOR(7 downto 0);
        A_DATA_SEND,P_DATA_SEND,L_DATA_SEND,CMD_DATA_SEND: in STD_LOGIC;
        A_READY,P_READY,L_READY,CMD_READY: in STD_LOGIC;
        --Data output
        dataOut:        out STD_LOGIC_VECTOR(7 downto 0);  --Output data.
        -- Connected to Output unit.
        dataSend:       out STD_LOGIC;-- Is data Send.
        convert:        out STD_LOGIC;
        -- Connected to Output unit. 
        ready:          out STD_LOGIC-- Notify CmdProc work done.
        -- Send Event to CmdProc.
    );
end selector;


architecture selec of selector is
    type state_type is (A,P,L,CMD);
    signal curState: state_type;
    signal cov: std_logic := '1';









begin
    currentState:process(enl,enp,ena,ready_in)
    begin
        case curState is
        when CMD => 
            if ena ='1' then
                curState <= A;
                cov <= '1';
            elsif enp = '1' then
                curState <= P;
                cov <= '1';
            elsif enl ='1' then
                curState <= L;
                cov <= '1';
            end if;
        when A =>
            if ready_in = '1' then
                curState <= CMD;
                cov <= '0';
            end if;
        when P =>
            if ready_in = '1' then
                curState <= CMD;
                cov <= '0';
            end if;
        when L =>
            if ready_in = '1' then
                curState <= CMD;
                cov <= '0';
            end if;
        end case;
    end process;


    dataOut <= A_OUT when curState=A else
              P_OUT when curState =P else
              L_OUT when curState = L else
              CMD_OUT when curState = CMD else
                "00000000";
              
    dataSend <= A_DATA_SEND when curState=A else
              P_DATA_SEND when curState =P else
              L_DATA_SEND when curState = L else
              CMD_DATA_SEND when curState = CMD else
              '0';
              
    ready <= A_READY when curState=A else
              P_READY when curState =P else
              L_READY when curState = L else
              CMD_READY when curState = CMD else
              '1';

    convert <= cov;
    --Send byte when in SENDING State
       
  end selec;
    

        

