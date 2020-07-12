library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_cache_tb is
end entity;

architecture arch of data_cache_tb is

  component data_cache is
    port (
      DATA_in  : in  std_logic_vector(31 downto 0);
      DATA_out : out std_logic_vector(31 downto 0);
      ADDR32   : in  std_logic_vector(31 downto 0);
      RW       : in  std_logic;         -- 0 para Read, 1 para Write
      ENABLE   : in  std_logic;

      READY : out std_logic;

      clk : in std_logic
      );


  end component;

  signal DATA_in, Data_OUT, ADDR32 : std_logic_vector(31 downto 0);
  signal RW, ENABLE, READY         : std_logic;
  signal clk                       : std_logic := '0';

begin
  cache : data_cache port map (DATA_in, DATA_OUT, ADDR32, RW, ENABLE, READY, clk);

  clk <= not clk after 1.25 ns;
  test : process
  begin
    enable <= '1';
    for i in 49280 to 49288 loop
      RW     <= '0';  --testando para leitura -- 01234567 89ABCDEF AAAAAAAA
      ADDR32 <= std_logic_vector(to_unsigned(i, 32));
      wait until ready = '1';
    end loop;
    report "leu tudo certo";

    for i in 49280 to 49288 loop
      RW      <= '1';                   --testando para escrita com hit
      DATA_in <= x"FEDCBA98";
      ADDR32  <= std_logic_vector(to_unsigned(i, 32));
      wait until ready = '1';
    end loop;
    -- for i in 49280 to 49288 loop
    --   RW     <= '0';  --testando para leitura após escrita --saida esperada FEDCBA98 FEDCBA98 FEDCBA98
    --   ADDR32 <= std_logic_vector(to_unsigned(i, 32));
    --   wait until ready = '1';
    -- end loop;

    -- report "terminou de reler os writes";
    -- for i in 2000 to 2007 loop
    --   RW      <= '1';                   --testando para miss na escrita
    --   DATA_IN <= x"EEEEEEEE";
    --   ADDR32  <= std_logic_vector(to_unsigned(i, 32));
    --   wait until ready = '1';
    -- end loop;
    -- report "terminou write misses";

    -- for i in 2000 to 2007 loop
    --   RW     <= '0';  --testando para leitura após escrita (miss) --miss e depois -> EEEEEEEE EEEEEEEE
    --   ADDR32 <= std_logic_vector(to_unsigned(i, 32));
    --   wait until ready = '1';
    -- end loop;

    --testando LRU
    for i in 128 to 136 loop  -- esperase que entre no block 1 do conjutno 2
      RW     <= '0';
      ADDR32 <= std_logic_vector(to_unsigned(i, 32));
      report "128";
    end loop;

    for i in 57472 to 57480 loop
      -- esperase que entre no block 0 do conjutno 2, dando deplace no bloco anterior
      RW     <= '0';
      ADDR32 <= std_logic_vector(to_unsigned(i, 32));
      report "5742";
    end loop;
    report "terminou tudo";

    std.env.finish;
  end process test;


end architecture;
