library IEEE;
use IEEE.std_logic_1164.all;

entity memory_hierarchy is
  port(
    instruction_cache_data    : out std_logic_vector(31 downto 0);
    instruction_cache_address : in  std_logic_vector(31 downto 0);
    data_cache_data_in        : in  std_logic_vector(31 downto 0);
    data_cache_data_out       : out std_logic_vector(31 downto 0);
    data_cache_address        : in  std_logic_vector(31 downto 0);
    RW                        : in  std_logic;
    clk                       : in  std_logic;
    enable                    : in  std_logic;
    ready                     : out std_logic
    );
end entity;

architecture arch of memory_hierarchy is

  component control_unit is
    port(
      RW                      : in  std_logic;
      enable                  : in  std_logic;
      buffer_ready            : in  std_logic;
      data_cache_ready        : in  std_logic;
      instruction_cache_ready : in  std_logic;
      data_cache_hit          : in  boolean;
      instruction_cache_hit   : in  boolean;
      clk                     : in  std_logic;
      SEL                     : out std_logic_vector(1 downto 0);
      ready                   : out std_logic
      );
  end component;

  component instruction_cache is
    port (
      data       : out std_logic_vector(31 downto 0);
      address    : in  std_logic_vector(31 downto 0);
      enable     : in  std_logic;
      ready      : out std_logic;
      hit        : out boolean;
      mm_data    : in  std_logic_vector(31 downto 0);
      mm_address : out std_logic_vector(31 downto 0);
      mm_ready   : in  std_logic;
      clk        : in  std_logic
      );
  end component;

  component data_cache is
    port (
      data_in    : in  std_logic_vector(31 downto 0);
      data_out   : out std_logic_vector(31 downto 0);
      ADDR32     : in  std_logic_vector(31 downto 0);
      RW         : in  std_logic;       -- 0 para Read, 1 para Write
      ENABLE     : in  std_logic;
      READY      : out std_logic;
      hit        : out boolean;
      mm_data    : in  std_logic_vector(31 downto 0);
      mm_address : out std_logic_vector(31 downto 0);
      mm_ready   : in  std_logic;
      clk        : in  std_logic
      );
  end component;

  component write_buffer is
    port (
      data        : in  std_logic_vector(31 downto 0);
      address     : in  std_logic_vector(31 downto 0);
      mm_ready_in : in  std_logic;
      enable      : in  std_logic;
      ready_out   : out std_logic;
      main_out    : out std_logic_vector(31 downto 0);
      address_out : out std_logic_vector(31 downto 0)
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
      ready   : out   std_logic
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

  component decoder is
    port (
      SEL      : in  std_logic_vector(1 downto 0);
      mm_ready : in  std_logic;
      A        : out std_logic;
      B        : out std_logic;
      C        : out std_logic
      );
  end component;

  signal buffer_ready, data_cache_ready, instruction_cache_ready : std_logic;
  signal data_cache_hit, instruction_cache_hit                   : boolean;
  signal sel                                                     : std_logic_vector(1 downto 0);
  signal instruction_cache_mm_data, instruction_cache_mm_address : std_logic_vector(31 downto 0);
  signal instruction_cache_mm_ready                              : std_logic;
  signal data_cache_mm_data, data_cache_mm_address               : std_logic_vector(31 downto 0);
  signal data_cache_mm_ready                                     : std_logic;
  signal buffer_mm_data                   : std_logic_vector(31 downto 0);
  signal buffer_mm_address_in, buffer_mm_address_out             : std_logic_vector(31 downto 0);
  signal buffer_mm_ready                                         : std_logic;

  signal mm_data, mm_address : std_logic_vector(31 downto 0);
  signal mm_ready            : std_logic;

begin
  UC : control_unit port map (
    RW                      => RW,
    enable                  => enable,
    buffer_ready            => buffer_ready,
    data_cache_ready        => data_cache_ready,
    instruction_cache_ready => instruction_cache_ready,
    data_cache_hit          => data_cache_hit,
    instruction_cache_hit   => instruction_cache_hit,
    clk                     => clk,
    SEL                     => sel,
    ready                   => ready);

  IC : instruction_cache port map (
    data       => instruction_cache_data,
    address    => instruction_cache_address,
    enable     => enable,
    ready      => instruction_cache_ready,
    hit        => instruction_cache_hit,
    mm_data    => instruction_cache_mm_data,
    mm_address => instruction_cache_mm_address,
    mm_ready   => instruction_cache_mm_ready,
    clk        => clk
    );

  DC : data_cache port map (
    data_in    => data_cache_data_in,
    data_out   => data_cache_data_out,
    addr32     => data_cache_address,
    RW         => rw,
    enable     => enable,
    ready      => data_cache_ready,
    hit        => data_cache_hit,
    mm_data    => data_cache_mm_data,
    mm_address => data_cache_mm_address,
    mm_ready   => data_cache_mm_ready,
    clk        => clk
    );

  BUF : write_buffer port map (
    data        => data_cache_data_in,
    address     => data_cache_address,
    mm_ready_in => buffer_mm_ready,
    enable      => rw,
    ready_out   => buffer_ready,
    main_out    => buffer_mm_data,
    address_out => buffer_mm_address_out
    );

  data_mux : mux4to1 port map (
    A     => buffer_mm_data,
    B     => data_cache_mm_data,
    C     => instruction_cache_mm_data,
    D     => (others => '0'),
    SEL   => sel,
    saida => mm_data
    );

  address_mux : mux4to1 port map (
    A     => buffer_mm_address_out,
    B     => data_cache_mm_address,
    C     => instruction_cache_mm_address,
    D     => (others => '0'),
    SEL   => sel,
    saida => mm_address
    );

  mm_ready_decoder : decoder port map (
    SEl      => sel,
    mm_ready => mm_ready,
    A        => buffer_mm_ready,
    B        => data_cache_mm_ready,
    C        => instruction_cache_mm_ready
    );

  mm : main_memory generic map (filename => "./memory_init.txt")
    port map (
      data    => mm_data,
      address => mm_address,
      rw      => rw,
      enable  => enable,
      ready   => mm_ready
      );

end arch;
