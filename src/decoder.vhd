library IEEE;
use IEEE.std_logic_1164.all;

entity decoder is
  port (
    SEL: in std_logic_vector(1 downto 0);
    mm_ready: in std_logic;
    A: out std_logic;
    B: out std_logic;
    C: out std_logic
    );
end entity;

architecture arch of decoder is
begin
    A <= mm_ready when SEL = "00" else '0';
    B <= mm_ready when SEL = "01" else '0';
    C <= mm_ready when SEL = "10" else '0';
end;
