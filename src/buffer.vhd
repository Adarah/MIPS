library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

entity buffer is
  port (
    data    : in std_logic_vector(31 downto 0);
    address : in    std_logic_vector(31 downto 0);
    ready_in      : in    std_logic;
    ready_out   : out   std_logic;
    main_out    : out std_logic_vector(31 downto 0); 
    adress_out  : out std_logic_vector(31 downto 0);
    );
end buffer;

architecture arquitetura of buffer is

signal dataBuffer   : std_logic_vector (31 downto 0);
signal adressBuffer : std_logic_vector (31 downto 0);


begin
    main_out <= dataBuffer
    address <= adressBuffer

  process (ready_in, address, dados)
  begin
    if empty && ready_in then
        dataBuffer  <= data
        adressBuffer <= adress
        ready_out <= 1                             
    else 
        ready_out <=0
    
    end if;
  end process;
end arquitetura;