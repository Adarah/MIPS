library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

entity bufferTeste is
end bufferTeste;

architecture arquitetura of bufferTeste is
    component buffer is
        port (
            data    : in std_logic_vector(31 downto 0);
            address : in    std_logic_vector(31 downto 0);
            ready_in      : in    std_logic;
            enable      : in    std_logic;
            ready_out   : out   std_logic;
            main_out    : out std_logic_vector(31 downto 0); 
            adress_out  : out std_logic_vector(31 downto 0);

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

    


signal dataBuffer   : std_logic_vector (31 downto 0);
signal adressBuffer : std_logic_vector (31 downto 0);
signal data, adress : std_logic_vector (31 downto 0);
signal ready_in, ready_out, enable, rw : std_logic;
signal main_out, adress_out : std_logic_vector (31 downto 0);

begin
    mm : main_memory generic map (filename => "./memory_init.txt")
    port map (data, address, rw, enable, ready_in);
    bfer : buffer port map (data, address, ready_in, enable, ready_out, main_out, adress_out);
    test  : process
begin
    for i in 49280 to 49288 loop
      address <= std_logic_vector(to_unsigned(i, 32)); 
      data <= std_logic_vector(to_unsigned(i, 32));
      wait until ready = '1';
      -- wait for 800 ns;
    end loop;
    std.env.finish;
  end process test;
end architecture;

--begin
  --  main_out <= dataBuffer
    --address <= adressBuffer

  --process (ready_in, address, dados)
  --begin
    --if empty && ready_in then
      --  dataBuffer  <= data
        --adressBuffer <= adress
       -- ready_out <= 1                             
    --else 
      --  ready_out <=0
    
    --end if;
  --end process;
--end arquitetura;