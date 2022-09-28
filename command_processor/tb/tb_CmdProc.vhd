library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.common_pack.all;


entity tb_CmdProc is end tb_CmdProc;

architecture testCmd of tb_CmdProc is
    component cmdProc
        port (
            clk:		    in std_logic;
            reset:	    in std_logic;
            rxnow:	    in std_logic;
            rxData:	    in std_logic_vector (7 downto 0);
            txData:	    out std_logic_vector (7 downto 0);
            rxdone:	    out std_logic;
            ovErr:	    in std_logic;
            framErr:	in std_logic;
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
    end component;

    for t_CMD : cmdProc use entity WORK.cmdProc(cmdRX);

    SIGNAL clk,reset,rxnow:STD_LOGIC := '0';
    SIGNAL rxData: STD_LOGIC_VECTOR(7 downto 0);
   
   	SIGNAL txData:	     std_logic_vector (7 downto 0);
    SIGNAL rxdone:	     std_logic;
    SIGNAL  ovErr:	     std_logic;
    SIGNAL framErr:	  std_logic;
    SIGNAL  txnow:	     std_logic;
    SIGNAL  txdone:	     std_logic;
    SIGNAL start:         std_logic;
    SIGNAL  numWords_bcd:  BCD_ARRAY_TYPE(2 downto 0);
    SIGNAL dataReady:     std_logic;
    SIGNAL  byte:          std_logic_vector(7 downto 0);
    SIGNAL  maxIndex:     BCD_ARRAY_TYPE(2 downto 0);
    SIGNAL  dataResults:   CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
    SIGNAL  seqDone:       std_logic;

begin
    --generate clk
    clk <= NOT clk AFTER 50 ns WHEN NOW < 3 us ELSE clk;
    rxData  <= "01010000" after 50 ns,
    "00001011" after 450 ns,
    "01001100" after 950 ns
    ;
    rxnow <= '1' after 100 ns,
    '0' after 200 ns,
    '1' after 500 ns,
    '0' after 600 ns,
    '1' after 1000 ns,
    '0' after 1100 ns
    ;
    
    txdone <= '1' after 400 ns,
    '0' after 500 ns,
    '1' after 1600 ns,
    '0' after 1700 ns;

  

    t_cmd: cmdProc Port map(
    clk => clk, 
    reset => reset, 
    rxnow => rxnow, 
    rxData => rxData,
    txData => txData,
    rxdone =>rxdone,
    ovErr=>ovErr,
    framErr=>framErr,
    txnow=>txnow,
    txdone => txdone,
    start=>start,
    numWords_bcd=>numWords_bcd,
    dataReady=>dataReady,
    byte=>byte,
    maxIndex=>maxIndex,
    dataResults=>dataResults,
    seqDone=>seqDone
    );
end testCmd;








