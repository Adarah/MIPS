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
  signal current_state : state_type := IDLE;
  signal next_state    : state_type := IDLE;
  signal hit           : boolean    := false;
  -- signal assignements  : integer range 0 to 15 := 0;
  signal changed       : std_logic;
  signal prev_address  : std_logic_vector(31 downto 0);
begin
  mm : main_memory generic map (filename => "memory_init.txt")
    port map (data    => mm_data,
              address => mm_address,
              rw      => '0',
              enable  => enable,
              ready   => mm_ready);

  state_change : process(clk, enable, changed) is
  begin
    if enable = '1' and rising_edge(clk) then
      current_state <= next_state;
      prev_address  <= address;
    -- report "changing state";
    end if;
  end process;

  tag          <= address(15 downto 14);
  block_offset <= to_integer(unsigned(address(13 downto 6)));
  word_offset  <= to_integer(unsigned(address(5 downto 2)));
  changed      <= '0' when prev_address = address else '1';
  -- block_var    <= cache(block_offset);

  -- actions : process(address, enable, mm_address, mm_ready)
  actions : process(clk, current_state, mm_ready) is
    variable assignements : integer range 0 to 60 := 0;
  begin
    case current_state is
      when IDLE =>
        ready <= '1';
        if changed = '1' then
          ready      <= '0', '1' after 5 ns;
          next_state <= COMPARE_TAG;
        end if;
      when COMPARE_TAG =>
        if cache(block_offset).valid = '1' and cache(block_offset).tag = tag then
          -- ready      <= '0', '1'                              after 5 ns;
          data       <= cache(block_offset).data(word_offset);
          next_state <= IDLE;
          hit        <= true;
          report "HIT!";
        else
          -- ready      <= '0';
          ready      <= '0';
          next_state <= ALLOCATE;
          mm_address <= address(31 downto 6) & std_logic_vector(to_unsigned(assignements, 6));
          hit        <= false;
        -- report "MISS :(";
        end if;

      when ALLOCATE =>
        mm_address <= address(31 downto 6) & std_logic_vector(to_unsigned(assignements, 6));
        if rising_edge(mm_ready) then
          report "assignemnts: " & integer'image(assignements);
          -- divido por 4 devido aos bytes. assignments endereca palavra ao inves
          -- de bytes
          cache(block_offset).data(assignements/4) <= mm_data;
          cache(block_offset).tag                  <= address(15 downto 14);
          mm_address                               <= address(31 downto 6) & std_logic_vector(to_unsigned(assignements, 6));
          if assignements >= 4 * (cache_line'length - 1) then
            cache(block_offset).valid <= '1';
            next_state                <= COMPARE_TAG;
            assignements              := 0;
          else
            assignements := assignements + 4;
            next_state   <= ALLOCATE;
          end if;
        end if;

      when others =>
        report "OTHERS";
        ready <= '0';
        hit   <= false;
        data  <= (others => '0');
    end case;
  end process actions;

end arch;
