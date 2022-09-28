library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;


entity tb_P_process is end tb_P_process;

architecture testP of tb_P_process is
    component P
       port(
        enp:            in STD_LOGIC;
        sysclk:       in STD_LOGIC;
        reset:          in STD_LOGIC;
        txdone:         in STD_LOGIC;

        --Data input
        dataResult:     in STD_LOGIC_VECTOR(7 downto 0);

        --Data output
        dataOut:        out STD_LOGIC_VECTOR(7 downto 0);  --Output data
        dataSend:       out STD_LOGIC;--Is data Send
        ready:          out STD_LOGIC--Notify CmdProc ready.
        );
    end component;

    for t_p : P use entity WORK.pProc(pCom);

    SIGNAL t_enp,t_sysclk,t_reset:STD_LOGIC := '0';
    SIGNAL t_dataResult: STD_LOGIC_VECTOR(7 downto 0);
    signal t_dataOut:STD_LOGIC_VECTOR(7 downto 0);
    signal t_dataSend, t_ready:STD_LOGIC;
    signal t_txdone: STD_LOGIC;

begin
    --generate clk
    t_sysclk <= NOT t_sysclk AFTER 50 ns WHEN NOW < 3 us ELSE t_sysclk;
    t_dataResult <= "00000011";
    t_enp <= '1' after 120 ns,
    '0' after 220 ns,
    '1' after 300 ns,
    '0' after 400 ns;

    t_txdone <= '1' after 500 ns;


    t_p: P Port map(t_enp,t_sysclk,t_reset,t_txdone,t_dataResult,t_dataOut,t_dataSend,t_ready);
end testP;







