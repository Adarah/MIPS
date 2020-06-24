library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity main_memory_tb is
end entity;


architecture main_memory_tb_arch of main_memory_tb is
  component main_memory is
    generic (
      filename   : in string;
      read_time  : in time := 40 ns;
      write_time : in time := 40 ns
      );
    port (
      data    : inout std_logic_vector(31 downto 0);
      address : in    std_logic_vector(31 downto 0);
      rw      : in    std_logic;
      enable  : in    std_logic;
      ready   : out   std_logic
      );
  end component;

  signal data, address     : std_logic_vector(31 downto 0);
  signal rw, enable, ready : std_logic;

begin
  mm : main_memory generic map (filename => "./memory_init.txt")
    port map (data, address, rw, enable, ready);
  testbench : process
  begin
    for i in 0 to 16 loop
      address <= std_logic_vector(to_unsigned(i, 32));
      rw      <= '0';
      enable  <= '1';
      wait for 100 ns;
    end loop;

    for i in 64 to 65 loop
      address <= std_logic_vector(to_unsigned(i, 32));
      rw      <= '0';
      enable  <= '1';
      wait for 100 ns;
    end loop;
    for i in 49276 to 49277 loop
      address <= std_logic_vector(to_unsigned(i, 32));
      rw      <= '0';
      wait for 100 ns;
    end loop;
    wait for 500 ns;
    std.env.finish;
  end process testbench;
end main_memory_tb_arch;
