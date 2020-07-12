library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity write_buffer is
  port (
    data        : in  std_logic_vector(31 downto 0);
    address     : in  std_logic_vector(31 downto 0);
    ready_in    : in  std_logic;
    enable      : in  std_logic;
    ready_out   : out std_logic;
    main_out    : out std_logic_vector(31 downto 0);
    address_out : out std_logic_vector(31 downto 0)
    );
end write_buffer;

architecture arquitetura of write_buffer is

  signal dataBuffer    : std_logic_vector (31 downto 0);
  signal addressBuffer : std_logic_vector (31 downto 0);
  signal empty         : std_logic := '0';

begin
  main_out    <= dataBuffer;
  address_out <= addressBuffer;

  process (ready_in, address, data)
  begin
    if enable = '1' then
      if ready_in = '1' then
        dataBuffer <= data;
        addressBuffer <= address;
        empty <= '1';
        ready_out <= '1';
      else
        ready_out <= '0';
      end if;
    end if;
  end process;
end arquitetura;
