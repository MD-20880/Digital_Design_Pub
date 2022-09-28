library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use work.common_pack.all;

entity tb_L_process is end tb_L_process;

architecture testL of tb_L_process is
    component L
       port(
        enl:            in STD_LOGIC;
        sysclk:       in STD_LOGIC;
        reset:          in STD_LOGIC;
        txdone:       in STD_LOGIC;
        --Data input
        dataResult:     in CHAR_ARRAY_TYPE(0 to 6);

        --Data output
        dataOut:        out STD_LOGIC_VECTOR(7 downto 0);  --Output data
        dataSend:       out STD_LOGIC;--Is data Send
        ready:          out STD_LOGIC--Notify CmdProc ready.
        );
    end component;

    for t_l : L use entity WORK.lProc(lCom);

    SIGNAL t_enl,t_sysclk,t_reset:STD_LOGIC := '0';
    SIGNAL t_dataResult: CHAR_ARRAY_TYPE(0 to 6);
    signal t_dataOut:STD_LOGIC_VECTOR(7 downto 0);
    signal t_dataSend, t_ready:STD_LOGIC;
    signal t_txdone: STD_LOGIC;

begin
    --generate clk
    t_sysclk <= NOT t_sysclk AFTER 50 ns WHEN NOW < 3 us ELSE t_sysclk;
    t_dataResult <= ("00110101","00110001","00110011","00110110","00110000","00110000","00111001");
    t_enl <= '1' after 120 ns,
    '0' after 220 ns,
    '1' after 300 ns,
    '0' after 400 ns;

    t_txdone <= '1' after 800 ns, '0' after 900 ns,
    '1' after 1200 ns, '0' after 1300 ns,
    '1' after 1500 ns, '0' after 1600 ns;
    
    t_reset <= '1' after 2000 ns,
    '0' after 2100 ns;


    t_l: L Port map(t_enl,t_sysclk,t_reset,t_txdone,t_dataResult,t_dataOut,t_dataSend,t_ready);
end testL;








