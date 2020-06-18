library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity instruction_cache is
  port (
    data    : out std_logic_vector(31 downto 0);
    address : in  std_logic_vector(31 downto 0);
    enable  : in  std_logic;
    ready   : out std_logic;
    clk     : in  std_logic
    );
end instruction_cache;

architecture arch of instruction_cache is

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

  subtype word_type is std_logic_vector(31 downto 0);
  subtype tag_type is std_logic_vector(1 downto 0);
  type cache_line is array(0 to 15) of word_type;
  type block_type is record
    valid : std_logic;
    tag   : tag_type;
    data  : cache_line;
  end record block_type;
  type cache_type is array(0 to 255) of block_type;

  -- instruction cache signals
  signal tag          : tag_type;
  signal word_offset  : integer range 0 to 15;
  signal block_offset : integer range 0 to 255;

  -- signal word_offset  : integer;
  -- signal block_offset : integer;
  constant empty_block : block_type := (
    valid => '0',
    tag   => (others => '0'),
    data  => (others => (others => '0'))
    );
  signal cache : cache_type := (others => empty_block);

  -- main memory signals
  signal mm_data    : word_type;
  signal mm_address : std_logic_vector(31 downto 0);
  signal mm_ready   : std_logic;

  -- states
  type state_type is (IDLE, COMPARE_TAG, ALLOCATE);
  signal state        : state_type := IDLE;
  signal hit          : boolean    := false;
  signal assignements : integer range 0 to 15 := 0;
begin
  mm : main_memory generic map (filename => "memory_init.txt")
    port map (data    => mm_data,
              address => mm_address,
              rw      => '0',
              enable  => enable,
              ready   => mm_ready);

  next_state : process(clk, address, mm_address, mm_ready) is
  begin
    if enable = '1' and rising_edge(clk) then
      case state is
        when IDLE => state <= COMPARE_TAG;
        when COMPARE_TAG =>
          if hit then
            state <= IDLE;
          else
            state <= ALLOCATE;
          end if;

        when ALLOCATE =>
          if mm_ready = '1' and assignements = cache_line'length-1 then
            state         <= COMPARE_TAG;
            assignements  <= 0;
          else
            assignements <= assignements + 1;
          end if;
        when others => state <= COMPARE_TAG;
      end case;
    end if;

  end process;

  tag          <= address(15 downto 14);
  block_offset <= to_integer(unsigned(address(13 downto 6)));
  word_offset  <= to_integer(unsigned(address(5 downto 2)));
  -- block_var    <= cache(block_offset);

  -- actions : process(address, enable, mm_address, mm_ready)
  actions : process(clk, mm_ready) is
  -- variable block_var : block_type;    -- block is a reserved keyword
  begin
    ready <= '0';
    data  <= (others => '0');
    -- report "address: " & to_hstring(address(31 downto 0));
    -- report "TAG: " & to_hstring(tag);
    -- report "OFFSET: " & integer'image(block_offset);
    -- report "WORD OFFSET: " & integer'image(word_offset);
    -- report "block tag: " & to_hstring(cache(block_offset).tag);
    case state is
      when IDLE =>
        ready <= '1';

      when COMPARE_TAG =>
        if cache(block_offset).valid = '1' and cache(block_offset).tag = tag then
          hit  <= true after 5 ns;
          data <= cache(block_offset).data(word_offset) after 5 ns;
        else
          hit <= false after 5 ns;
        end if;

      when ALLOCATE =>
        mm_address <= address(31 downto 6) & std_logic_vector(to_unsigned(assignements, 6));
        if rising_edge(mm_ready) then
          cache(block_offset).valid              <= '1';
          cache(block_offset).data(assignements) <= mm_data;
        cache(block_offset).tag <= address(15 downto 14);
        end if;

      when others =>
        report "OTHERS";
        ready <= '0';
        hit   <= false;
        data  <= (others => '0');
    end case;
  end process actions;

end arch;
