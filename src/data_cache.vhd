library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity data_cache is
  port (
    data   : inout std_logic_vector(31 downto 0);
    ADDR32 : in    std_logic_vector(31 downto 0);
    RW     : in    std_logic;           -- 0 para Read, 1 para Write
    ENABLE : in    std_logic;
    READY  : out   std_logic;
    clk    : in    std_logic
    );
end entity;

architecture arquitetura of data_cache is
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

  subtype word_type is std_logic_vector(31 downto 0);  -- word de 32 bits
  subtype tag_type is std_logic_vector(2 downto 0);    -- tag de 3 bits

  type cache_line is array(0 to 15) of word_type;  -- bloco de 16 words
  type block_type is                    -- "objeto" bloco de memória
  record
    valid : std_logic;                  -- "valid" 1 bit
    tag   : tag_type;                   -- tag de 3 bits
    data  : cache_line;                 -- bloco de 16 words
    LRU   : std_logic;  -- 1 indica que eh o bloco meno recentemente usado
  end record;

  type conjunto_type is array(0 to 1) of block_type;

  type cache_type is array(0 to 127) of conjunto_type;  --do menor pro maior

  -- signal write_buffer : word_type;
  -- signal buffer_cheio : std_logic := '0';
  -- signal addr_buffer  : std_logic_vector(31 downto 0);

  -- DATA cache signals
  signal tag             : tag_type;
  signal word_offset     : integer range 0 to 15;
  signal conjunto_offset : integer range 0 to 127;


  constant empty_block : block_type := (
    valid => '0',
    tag   => (others => '0'),
    data  => (others => (others => '0')),
    LRU   => '1'
    );


  signal cache      : cache_type := (others => (others => empty_block));  --inicializa o cache com todos os blocos vazios
  -- main memory signals
  signal mm_data    : word_type;
  signal mm_address : std_logic_vector(31 downto 0);
  signal mm_ready   : std_logic;

  -- states
  -- type state_type is (IDLE, COMPARE_TAG, ALLOCATE, IDLE_BUFFER_CHEIO, WRITE_BUFFER_CHEIO);
  type state_type is (IDLE, COMPARE_TAG, ALLOCATE);
  signal current_state : state_type := IDLE;
  signal next_state    : state_type := IDLE;
  signal hit           : boolean    := false;
  signal changed       : std_logic;
  signal prev_address  : std_logic_vector(31 downto 0);
  signal prev_data     : std_logic_vector(31 downto 0);



  signal temp : std_logic_vector(2 downto 0);

begin
  -- with current_state select
  --   temp <= "000" when IDLE,
  --   "001"         when COMPARE_TAG,
  --   "010"         when ALLOCATE,
  --   "011"         when IDLE_BUFFER_CHEIO,
  --   "100"         when others;

  with current_state select
    temp <= "000" when IDLE,
    "001"         when COMPARE_TAG,
    "010"         when others;
  mm : main_memory generic map (filename => "memory_init.txt")
    port map (data    => mm_data,
              address => mm_address,
              rw      => RW,
              enable  => enable,
              ready   => mm_ready);

  state_change : process(clk, enable, changed) is
  begin
    if enable = '1' and rising_edge(clk) then
      current_state <= next_state;
      prev_address  <= ADDR32;
      prev_data     <= DATA;
    end if;
  end process;

  tag             <= ADDR32(15 downto 13);
  conjunto_offset <= to_integer(unsigned(ADDR32(12 downto 6)));
  word_offset     <= to_integer(unsigned(ADDR32(5 downto 2)));
  changed         <= '0' when prev_address = ADDR32 and prev_data = DATA else '1';

  actions : process(clk, current_state, mm_ready) is
    variable assignements : integer range 0 to 64 := 0;
  begin
    case current_state is
      when IDLE =>
        ready <= '1';
        if changed = '1' then
          ready      <= '0', '1' after 5 ns;
          next_state <= COMPARE_TAG;
        end if;
      when COMPARE_TAG =>
        -- vai pra idle buffer cheio se o buffer estiver cheio
        next_state <= IDLE;
        hit        <= true;
        if cache(conjunto_offset)(0).valid = '1' and cache(conjunto_offset)(0).tag = tag then  -- se hit no bloco 1
          -- report "estado do buffer: " & to_string(buffer_cheio);
          if RW = '0' then
            report "enviando isso para data: " & to_hstring(cache(conjunto_offset)(0).data(word_offset));
            data       <= cache(conjunto_offset)(0).data(word_offset);
            report "HIT! Read No bloco 0 do conjunto";
          elsif RW = '1' then
            report "data na escrita: " & to_hstring(data);
            cache(conjunto_offset)(0).data(word_offset) <= data;
            report "escrita";
          else
            report "RW nao eh nem 0 nem 1";
          end if;

        elsif cache(conjunto_offset)(1).valid = '1' and cache(conjunto_offset)(1).tag = tag then  -- se hit no bloco 2
          if RW = '0' then
            -- data       <= cache(conjunto_offset)(1).data(word_offset);
            report "HIT! Read No bloco 1 do conjunto";
          elsif RW = '1' then
            cache(conjunto_offset)(1).data(word_offset) <= data;
          else
            report "RW nao eh nem 0 nem 1";
          end if;
        elsif RW = '0' then                            -- deu MISS.
          ready      <= '0';
          next_state <= ALLOCATE;
          mm_address <= ADDR32(31 downto 6) & std_logic_vector(to_unsigned(assignements, 6));
          hit        <= false;
          report "MISS na leitura";
        else
          report "MISS NA ESCRITA";

            report "data na escrita: " & to_hstring(data);

          hit <= false;
        end if;

        -- when IDLE_BUFFER_CHEIO =>
        --   -- escreve na memoria principal. Pra qualquer acesso, voltar pro estado
        --   -- compare_tag, exceto se o buffer ficar vazio, entao voltar pra IDLE
        --   mm_address <= addr_buffer;
        --   mm_data    <= write_buffer;
        --   if changed = '1' then
        --     ready <= '1';
        --     next_state <= COMPARE_TAG;
        --   end if;
        --   if rising_edge(mm_ready) then
        --     buffer_cheio <= '0';
        --     next_state <= COMPARE_TAG;
        --     ready <= '1';
        --     report "operation: " & to_string(RW);
        --   end if;

        -- when WRITE_BUFFER_CHEIO =>
        --   -- esperar ate o buffer ficar vazio, e ai voltar pro compare_tag -> idle_buffer_cheio
        --   ready <= '0';
        --   if rising_edge(mm_ready) then
        --     report "ficou ponrot mm ready";
        --     buffer_cheio <= '0';
        --     next_state <= COMPARE_TAG;
        --   end if;

      when ALLOCATE =>
        mm_address <= ADDR32(31 downto 6) & std_logic_vector(to_unsigned(assignements, 6));
        if cache(conjunto_offset)(0).LRU = '1' then
          if rising_edge(mm_ready) then
            report "assignemnts: " & integer'image(assignements);
            cache(conjunto_offset)(0).data(assignements/4) <= mm_data;
            cache(conjunto_offset)(0).tag                  <= ADDR32(15 downto 13);
            mm_address                                     <= ADDR32(31 downto 6) & std_logic_vector(to_unsigned(assignements, 6));
            if assignements >= 4 * (cache_line'length - 1) then
              cache(conjunto_offset)(0).valid <= '1';
              next_state                      <= COMPARE_TAG;
              assignements                    := 0;
              cache(conjunto_offset)(0).LRU   <= '0';
              cache(conjunto_offset)(1).LRU   <= '1';
            else
              assignements := assignements + 4;
            --next_state   <= ALLOCATE;
            end if;
          end if;

        elsif cache(conjunto_offset)(1).LRU = '1' then
          report "allocate bloco 2";
          if rising_edge(mm_ready) then  -- se hit no bloco 2
            report "assignemnts: " & integer'image(assignements);
            cache(conjunto_offset)(1).data(assignements/4) <= mm_data;
            cache(conjunto_offset)(1).tag                  <= ADDR32(15 downto 13);
            mm_address                                     <= ADDR32(31 downto 6) & std_logic_vector(to_unsigned(assignements, 6));
            if assignements > 4 * (cache_line'length - 1) then
              cache(conjunto_offset)(1).valid <= '1';
              next_state                      <= COMPARE_TAG;
              assignements                    := 0;
              cache(conjunto_offset)(1).LRU   <= '0';
              cache(conjunto_offset)(0).LRU   <= '1';
            else
              assignements := assignements + 4;
            --next_state   <= ALLOCATE;
            end if;
          end if;

        else
          report "erro no ALLOCATE!";

        end if;

      when others =>
        report "OTHERS";
        ready <= '0';
        hit   <= false;
        data  <= (others => '0');


    end case;
  end process actions;


  -- process(mm_data, mm_ready, mm_address, RW, enable) is
  -- begin
  --   report "leitura dos valures de entrada para memoria principal";
  --   report "mm_data: " & to_hstring(mm_data);
  --   report "mm_ready: " & to_string(mm_ready);
  --   report "mm_address: " & to_hstring(mm_address);
  --   report "rw: " & to_string(RW);
  --   report "enable: " & to_string(enable);
  --   end process;

end arquitetura;
