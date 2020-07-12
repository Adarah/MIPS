library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_cache_tb is
end entity;

architecture arch of data_cache_tb is

  component data_cache is
	port (
	  DATA : inout std_logic_vector(31 downto 0);

	  ADDR32 : in std_logic_vector(31 downto 0);
	  RW     : in std_logic;            -- 0 para Read, 1 para Write
	  ENABLE : in std_logic;

	  READY : out std_logic;

	  clk : in std_logic
	  );


  end component;

  signal DATA, ADDR32      : std_logic_vector(31 downto 0);
  signal RW, ENABLE, READY : std_logic;
  signal clk               : std_logic := '0';

begin
  cache : data_cache port map (DATA, ADDR32, RW, ENABLE, READY, clk);

  clk <= not clk after 1.25 ns;
  test : process
  begin
	enable <= '1';
	for i in 49280 to 49288 loop
	  RW     <= '0';  --testando para leitura -- 01234567 89ABCDEF 11111111
	  ADDR32 <= std_logic_vector(to_unsigned(i, 32));
	  wait until ready = '1';
	  report "ficou pronto";
-- wait for 800 ns;
	end loop;
	report "leu tudo certo";

	for i in 49280 to 49288 loop
	  RW     <= '1';                    --testando para escrita
	  DATA   <= x"FEDCBA98";
	  ADDR32 <= std_logic_vector(to_unsigned(i, 32));
	  wait until ready = '1';
	  report "terminou uma operacao de escrita";
-- wait for 800 ns;
	end loop;

	for i in 49280 to 49288 loop
	  RW     <= '0';  --testando para leitura após escrita --saida esperada FEDCBA98 FEDCBA98 FEDCBA98
	  ADDR32 <= std_logic_vector(to_unsigned(i, 32));
	  wait until ready = '1';
-- wait for 800 ns;
	end loop;

	for i in 2000 to 2007 loop
	  RW     <= '1';                    --testando para miss na escrita
	  DATA   <= x"EEEEEEEE";
	  ADDR32 <= std_logic_vector(to_unsigned(i, 32));
	  wait until ready = '1';
-- wait for 800 ns;
	end loop;

	for i in 2000 to 2007 loop
	  RW     <= '0';  --testando para leitura após escrita (miss) --miss e depois -> EEEEEEEE EEEEEEEE
	  ADDR32 <= std_logic_vector(to_unsigned(i, 32));
	  wait until ready = '1';
-- wait for 800 ns;
end loop;

std.env.finish;
  end process test;





end architecture;
