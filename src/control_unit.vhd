library IEEE;
use IEEE.std_logic_1164.all;

entity control_unit is
  port(
    RW                      : in  std_logic;
    enable                  : in  std_logic;
    buffer_ready            : in  std_logic;
    data_cache_ready        : in  std_logic;
    instruction_cache_ready : in  std_logic;
    data_cache_hit          : in  boolean;
    instruction_cache_hit   : in  boolean;
    clk                     : in  std_logic;  -- clock de periodo 5 ns
    SEL                     : out std_logic_vector(1 downto 0);
    ready                   : out std_logic
    );
end entity;

architecture arch of control_unit is
  type state is (IDLE, BUF, DC, IC);
  signal current_state  : state := IDLE;
  signal next_state     : state;
  -- signal next_state_msb     : std_logic;
  -- signal next_state_lsb     : std_logic;
  -- signal next_state_code    : std_logic_vector(1 downto 0);
  -- signal buffer_is_ready    : boolean;
  -- signal is_write_operation : boolean;
  signal DC_hit, IC_hit : std_logic;
  signal selector       : std_logic_vector(3 downto 0);
begin
  -- | RW | BUF_READY | DC HIT | IC HIT | OQ ESPERAR      | next_state | state_code |
  -- |----+-----------+--------+--------+-----------------+------------+------------|
  -- |  0 |         0 |      0 |      0 | DC -> IC        | DC         |         10 |
  -- |  0 |         0 |      0 |      1 | DC              | DC         |         10 |
  -- |  0 |         0 |      1 |      0 | IC              | IC         |         11 |
  -- |  0 |         0 |      1 |      1 | NOP             | IDLE       |         00 |
  -- |  0 |         1 |      0 |      0 | BUF -> DC -> IC | BUF        |         01 |
  -- |  0 |         1 |      0 |      1 | BUF -> DC       | BUF        |         01 |
  -- |  0 |         1 |      1 |      0 | BUF -> IC       | BUF        |         01 |
  -- |  0 |         1 |      1 |      1 | NOP             | IDLE       |         00 |
  -- |  1 |         0 |      0 |      0 | IC              | IC         |         11 |
  -- |  1 |         0 |      0 |      1 | NOP             | IDLE       |         00 |
  -- |  1 |         0 |      1 |      0 | IC              | IC         |         11 |
  -- |  1 |         0 |      1 |      1 | NOP             | IDLE       |         00 |
  -- |  1 |         1 |      0 |      0 | BUF -> DC -> IC | BUF        |         01 |
  -- |  1 |         1 |      0 |      1 | BUF             | BUF        |         01 |
  -- |  1 |         1 |      1 |      0 | BUF -> IC       | BUF        |         01 |
  -- |  1 |         1 |      1 |      1 | BUF             | BUF        |         01 |
  -- |----+-----------+--------+--------+-----------------+------------+------------|

  DC_hit   <= '1' when data_cache_hit        else '0';
  IC_hit   <= '1' when instruction_cache_hit else '0';
  selector <= RW & buffer_ready & DC_hit & IC_hit;

  -- buffer_is_ready    <= true when buffer_status = '1' else false;
  -- is_write_operation <= true when RW = '1'            else false;
  -- next_state_msb     <= '1'  when (not buffer_is_ready and instruction_cache_hit)
  --                   or (not is_write_operation and not buffer_is_ready and data_cache_hit)
  --                   else '0';

  -- next_state_lsb <= '1' when (data_cache_hit and not instruction_cache_hit)
  --                   or (buffer_is_ready and not data_cache_hit)
  --                   or (is_write_operation and not instruction_cache_hit)
  --                   or (is_write_operation and buffer_is_ready)
  --                   else '0';

  -- next_state_code <= next_state_msb & next_state_lsb;

  state_transition : process (clk, enable)
  begin
    if enable = '1' and rising_edge(clk) then
      current_state <= next_state;
    end if;
  end process state_transition;

  next_state_logic : process (current_state, buffer_ready, data_cache_ready, instruction_cache_ready)
  begin
    case current_state is
      when IDLE =>
        ready <= '1';
        SEL   <= "00";
        case selector is
          when "0000" | "0001"                                              => next_state <= DC;
          when "0010" | "1000" | "1010"                                     => next_state <= IC;
          when "0100" | "0101" | "0110" | "1100" | "1101" | "1110" | "1111" => next_state <= BUF;
          when others                                                       => next_state <= IDLE;
        end case;
        -- case next_state_code is
        --   when "00" => next_state <= IDLE;
        --   when "01" => next_state <= BUF;
        --   when "10" => next_state <= DC;
        --   when "11" => next_state <= IC;
        --   when others =>
        --     report "transitioned to OTHERS state from IDLE";
        --     next_state <= IDLE;
        -- end case;

      when BUF =>
        ready <= '0';
        SEL   <= "00";
        if buffer_ready = '1' then
          next_state <= DC;
          SEL        <= "01";
        end if;

      when DC =>
        ready <= '0';
        SEL   <= "01";
        if data_cache_ready = '1' then
          next_state <= IC;
          SEL        <= "10";
        end if;

      when IC =>
        ready <= '0';
        SEL   <= "10";
        if instruction_cache_ready = '1' then
          next_state <= IDLE;
          SEL        <= "00";
        end if;

      when others =>
        ready <= '0';
        SEL   <= "00";
        report "entrou no estado 'others' da UC";
    end case;
  end process next_state_logic;

end arch;
