library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit_tb is
end entity;

architecture arch of control_unit_tb is

component control_unit is
  port(
    RW                      : in  std_logic;
    enable                  : in  std_logic;
    buffer_ready            : in  std_logic;
    data_cache_ready        : in  std_logic;
    instruction_cache_ready : in  std_logic;
    data_cache_hit          : in  boolean;
    instruction_cache_hit   : in  boolean;
    clk                     : in  std_logic;  -- clock de periodo 5 ns
    SEL                     : out std_logic_vector(1 downto 0);
    ready                   : out std_logic
    );
end component;

signal rw, enable, buffer_ready, data_cache_ready, instruction_cache_ready: std_logic;
signal data_cache_hit, instruction_cache_hit: boolean;
signal clk : std_logic := '1';
signal SEL : std_logic_vector(1 downto 0);
signal ready : std_logic;


begin
  cache : control_unit port map (rw, enable, buffer_ready, data_cache_ready, instruction_cache_ready,
                                 data_cache_hit, instruction_cache_hit, clk, SEL, ready);

  clk <= not clk after 2.5 ns;

  test : process
  begin
    enable <= '1';


    std.env.finish;
  end process test;


end architecture;
