library ieee;
use ieee.std_logic_1164.all;

-- DC = data_cache
-- IC = instruction_cache
entity control_unit is
  port(
    DC_data_in  : in  std_logic_vector(31 downto 0);
    DC_data_out : out std_logic_vector(31 downto 0);
    DC_address  : in  std_logic_vector(31 downto 0);
    DC_RW       : in  std_logic;

    IC_data    : out std_logic_vector(31 downto 0);
    IC_address : in  std_logic_vector(31 downto 0);

    ready : in std_logic;
    clk   : in std_logic
    );
end entity;
architecture arch of control_unit is
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
  component instruction_cache is
    port (
      data    : out std_logic_vector(31 downto 0);
      address : in  std_logic_vector(31 downto 0);
      enable  : in  std_logic;
      ready   : out std_logic;
      clk     : in  std_logic
      );
  end component;

  component data_cache is
    port (
      data_in  : in  std_logic_vector(31 downto 0);
      data_out : out std_logic_vector(31 downto 0);
      ADDR32   : in  std_logic_vector(31 downto 0);
      RW       : in  std_logic;         -- 0 para Read, 1 para Write
      ENABLE   : in  std_logic;
      READY    : out std_logic;
      clk      : in  std_logic
      );
  end component;

  component mux4to1 is
    port(
      A     : in  std_logic_vector(31 downto 0);
      B     : in  std_logic_vector(31 downto 0);
      C     : in  std_logic_vector(31 downto 0);
      D     : in  std_logic_vector(31 downto 0);
      SEL   : in  std_logic_vector(1 downto 0);
      saida : out std_logic_vector(31 downto 0)
      );
  end component;

begin
end arch;
