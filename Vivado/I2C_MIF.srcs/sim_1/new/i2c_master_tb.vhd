----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.05.2019 14:51:11
-- Design Name: 
-- Module Name: i2c_master_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity i2c_master_tb is
--  Port ( );
end i2c_master_tb;

architecture Behavioral of i2c_master_tb is

component i2c_master is
  generic(
    input_clk : integer := 50_000_000;                  --input clock speed from user logic in hz
    bus_clk   : integer := 400_000);                    --speed the i2c bus (scl) will run at in hz
  port(
    clk       : in     std_logic;                       -- system clock
    reset_n   : in     std_logic;                       -- active low reset
    ena       : in     std_logic;                       -- latch in command
    addr      : in     std_logic_vector(6 downto 0);    -- address of target slave
    rw        : in     std_logic;                       -- '0' is write, '1' is read
    data_wr   : in     std_logic_vector(7 downto 0);    -- data to write to slave
    busy      : out    std_logic;                       -- indicates transaction in progress
    data_rd   : out    std_logic_vector(7 downto 0);    -- data read from slave
    ack_error : buffer std_logic;                       -- flag if improper acknowledge from slave
    sda       : inout  std_logic;                       -- serial data of i2c bus
    scl       : inout  std_logic);                      -- serial clock output of i2c bus
end component;

component I2C_slave is
  generic (
    SLAVE_ADDR : std_logic_vector(6 downto 0));
  port (
    scl              : inout std_logic;
    sda              : inout std_logic;
    clk              : in    std_logic;
    rst              : in    std_logic;
    -- User interface
    read_req         : out   std_logic;
    data_to_master   : in    std_logic_vector(7 downto 0);
    data_valid       : out   std_logic;
    data_from_master : out   std_logic_vector(7 downto 0));
end component;

constant CLK_PERIOD : time := 10 ns;

signal clk       :  STD_LOGIC;                    --system clock
signal reset_n   :  STD_LOGIC;                    --active low reset
signal ena       :  STD_LOGIC;                    --latch in command
signal addr      :  STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
signal rw        :  STD_LOGIC;                    --'0' is write, '1' is read
signal data_wr   :  STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
signal busy      :  STD_LOGIC;                    --indicates transaction in progress
signal data_rd   :  STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
signal ack_error :  STD_LOGIC;                    --flag if improper acknowledge from slave
signal sda       :  STD_LOGIC;                    --serial data output of i2c bus
signal scl       :  STD_LOGIC;                   --serial clock output of i2c bus

signal rst                  :  STD_LOGIC;                    --active high reset
signal read_req             :  STD_LOGIC;                    --data request from master
signal data_valid_master    :  STD_LOGIC;                    --data valid from master
signal data_from_master     :  STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from master
signal data_to_master       :  STD_LOGIC_VECTOR(7 DOWNTO 0); --data sent to master

begin

sda <= 'H';
scl <= 'H';


i2c_master_i : i2c_master
  generic map(
    input_clk => 50_000_000,                  --input clock speed from user logic in hz
    bus_clk   => 400_000)                     --speed the i2c bus (scl) will run at in hz
  port map(
    clk       => clk,                       -- system clock
    reset_n   => reset_n,                         -- active low reset
    ena       => ena,      -- latch in command
    addr      => addr,      -- address of target slave
    rw        => rw,      -- '0' is write, '1' is read
    data_wr   => data_wr,      -- data to write to slave
    busy      => busy,      -- indicates transaction in progress
    data_rd   => data_rd,      -- data read from slave
    ack_error => ack_error,      -- flag if improper acknowledge from slave
    sda       => sda,   -- serial data of i2c bus
    scl       => scl      -- serial clock output of i2c bus
    );
    
i2c_slave_i : I2C_slave
  generic map(
    SLAVE_ADDR      => "0001000"
    )
  port map (
    scl                 => scl,
    sda                 => sda,
    clk                 => clk,
    rst                 => rst,
    -- User interface
    read_req            => read_req, 
    data_to_master      => x"FF", -- data_to_master,
    data_valid          => data_valid_master,
    data_from_master    => data_from_master
    );


proc_reset_n : process 
begin
    reset_n <= '0';
    rst     <= '1';
    wait for 102 ns;
    reset_n <= '1';
    rst     <= '0';
    wait;
end process proc_reset_n;

proc_clock : process 
begin
    clk <= '0';
    wait for 10 ns;
    clk_loop : loop
        clk <= not clk;
        wait for CLK_PERIOD/2.0;
    end loop;
end process proc_clock;

proc_data_to_master : process
begin
    data_to_master <= x"00";
    data_to_master_loop : loop
       wait until rising_edge(clk);
       wait for 1 ns;
       data_to_master <= data_to_master + 1;
    end loop;
    wait;
end process proc_data_to_master;   


proc_data_transfer : process 
begin
    addr    <= "0000000";
    data_wr <= "00000000";
    rw      <= '0';
    ena     <= '0';
    wait until rising_edge(clk);
    wait for 1 ns;
    rw      <= '0';
    ena     <= '0';

--  WRITE
    wait for 50 us;
    wait until rising_edge(clk);
    wait for 1 ns;
    addr    <= "0001000";
    data_wr <= "10100101";
    rw      <= '0';
    ena     <= '1';
    wait until rising_edge(busy);
    wait until rising_edge(clk);
    wait for 1 ns;
    rw      <= '0';
    ena     <= '0';
    
--  Single-byte write sequence   
    wait for 50 us;
    wait until rising_edge(clk);
    wait for 1 ns;
    addr    <= "0001000";
    data_wr <= "10100101";
    rw      <= '0';
    ena     <= '1';
    wait until rising_edge(busy);
    wait until rising_edge(clk);
    wait for 1 ns;
    rw      <= '0';
    wait until rising_edge(busy);
    wait until rising_edge(clk);
    wait for 1 ns;
    rw      <= '0';
    ena     <= '0';
    
--  Burst write sequence   
    wait for 50 us;
    wait until rising_edge(clk);
    wait for 1 ns;
    addr    <= "0001000";
    data_wr <= "10100101";
    rw      <= '0';
    ena     <= '1';
    wait until rising_edge(busy);
    wait until rising_edge(clk);
    wait for 1 ns;
    rw      <= '0';
    wait until rising_edge(busy);
    wait until rising_edge(clk);
    wait for 1 ns;
    rw      <= '0';
    wait until rising_edge(busy);
    wait until rising_edge(clk);
    wait for 1 ns;
    rw      <= '0';
    ena     <= '0';
    
    wait for 500 us; 
       
--  READ
    wait for 50 us;
    wait until rising_edge(clk);
    wait for 1 ns;
    addr    <= "0001000";
 --   data_wr <= "10100101";
    rw      <= '1';
    ena     <= '1';
   wait until rising_edge(busy);
   wait until rising_edge(clk);
   wait for 1 ns;
   rw      <= '0';
   ena     <= '0';
       
--  Single-byte read sequence   
    wait for 50 us;
    wait until rising_edge(clk);
    wait for 1 ns;
    addr    <= "0001000";
    data_wr <= "10100101";
    rw      <= '0';
    ena     <= '1';
    wait until rising_edge(busy);
    wait until rising_edge(clk);
    wait for 1 ns;
    rw      <= '1';
    wait until rising_edge(busy);
    wait until rising_edge(clk);
    wait for 1 ns;
    rw      <= '0';
    ena     <= '0';
    
--  Burst read sequence   
    wait for 50 us;
    wait until rising_edge(clk);
    wait for 1 ns;
    addr    <= "0001000";
    data_wr <= "10100101";
    rw      <= '0';
    ena     <= '1';
    wait until rising_edge(busy);
    wait until rising_edge(clk);
    wait for 1 ns;
    rw      <= '1';
    wait until rising_edge(busy);
    wait until rising_edge(clk);
    wait for 1 ns;
    rw      <= '1';
    wait until rising_edge(busy);
    wait until rising_edge(clk);
    wait for 1 ns;
    rw      <= '0';
    ena     <= '0';
    
    wait;
end process proc_data_transfer;

end Behavioral;
