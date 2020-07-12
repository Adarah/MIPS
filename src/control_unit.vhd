library IEEE;
use IEEE.std_logic_1164.all;

entity control_unit is
  port(
    mm_ready   : in  std_logic;
    BF_ready   : in  std_logic;
    IC_ready   : in  std_logic;
    DC_ready   : in  std_logic;
    DC_data    : in  std_logic;
    DC_address : in  std_logic;
    RW         : in  std_logic;
    ready      : out std_logic;
    mm_SEL     : out std_logic_vector(1 downto 0);
    clk        : in  std_logic
    );
end entity;

architecture arch of control_unit is
  signal contador : std_logic := '0';
  signal sel_temp : std_logic_vector(1 downto 0);
begin
  contador <= not contador;
  mm_sel   <= sel_temp;
  process (contador, BF_ready, IC_ready, DC_ready)
  begin
    if falling_edge(contador) then
      if BF_ready = '0' then
        sel_temp <= "00";
      elsif DC_ready = '0' then
        sel_temp <= "01";
      elsif IC_ready = '0' then
        sel_temp <= "10";
      else
        sel_temp <= "00";
        ready    <= '1';
      end if;
    end if;
  end process;
end arch;
