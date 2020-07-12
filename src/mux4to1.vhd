library ieee;
use ieee.std_logic_1164.all;

entity mux4to1 is
  port(
    A: in std_logic_vector(31 downto 0);
    B: in std_logic_vector(31 downto 0);
    C: in std_logic_vector(31 downto 0);
    D: in std_logic_vector(31 downto 0);
    SEL:in  std_logic_vector(1 downto 0);
    saida: out std_logic_vector(31 downto 0)
);

end entity;

architecture arch of mux4to1 is
begin
  with SEL select
    saida <= A when "00",
    B when "01",
    C when "10",
    D when "11",
    (others => '0') when others;
 end arch;
