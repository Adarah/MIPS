library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity instruction_cache_tb is
end instruction_cache_tb;

architecture arch of instruction_cache_tb is
  component instruction_cache is
    port (
      data    : out std_logic_vector(31 downto 0);
      address : in  std_logic_vector(31 downto 0);
      enable  : in  std_logic;
      ready   : out std_logic;
      clk     : in  std_logic
      );
  end component;
  signal data, address : std_logic_vector(31 downto 0);
  signal enable, ready : std_logic;
  signal clk           : std_logic := '0';
begin
  cache : instruction_cache port map (data, address, enable, ready, clk);
  -- address <= (others => '0');
  clk <= not clk after 80 ns;
  test  : process
  begin
    enable <= '1';
    for i in 49280 to 49284 loop
      address <= std_logic_vector(to_unsigned(i, 32));
      -- wait until ready = '1';
      wait for 1000 ns;
    end loop;
    wait for 1000 ns;
    std.env.finish;
  end process test;
end architecture;
