library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity write_buffer_tb is
end write_buffer_tb;

architecture arquitetura of write_buffer_tb is
    component write_buffer is
        port (
            data    : in std_logic_vector(31 downto 0);
            address : in    std_logic_vector(31 downto 0);
            mm_ready_in      : in    std_logic;
            enable      : in    std_logic;
            ready_out   : out   std_logic;
            main_out    : out std_logic_vector(31 downto 0); 
            address_out  : out std_logic_vector(31 downto 0)
        );
    end component;    

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
          ready  : out   std_logic
          );
      end component;

signal data : std_logic_vector (31 downto 0);
signal ready_in, ready_out, enable, rw : std_logic;
signal main_out, address_out : std_logic_vector (31 downto 0);
    signal address: std_logic_vector(31 downto 0);

begin
    mm : main_memory generic map (filename => "./memory_init.txt")
    port map (main_out, address_out, rw, enable, ready_in);
    bfer : write_buffer port map (data, address, ready_in, enable, ready_out, main_out, address_out);
    test  : process
begin
  enable <= '1';
  rw <= '1';
  wait for 80 ns;
  for i in 1000 to 1001 loop
      address <= std_logic_vector(to_unsigned(i, 32));
      data <= std_logic_vector(to_unsigned(i, 32));
      wait until ready_out = '1';
      -- wait for 5 ns;
    end loop;

    for i in 2000 to 2001 loop
      address <= std_logic_vector(to_unsigned(i, 32));
      data <= std_logic_vector(to_unsigned(i, 32));
      -- wait until ready_out = '1';
      wait for 25 ns;

    end loop;
    std.env.finish;
  end process test;
end architecture;
