library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

entity main_memory is
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
end main_memory;

architecture behavioural of main_memory is
  subtype word is std_logic_vector(31 downto 0);
  type memory is array (0 to 2**14 - 1) of word;
  signal mem : memory;

  impure function init(fname : string) return memory is
    file text_file         : text open read_mode is filename;
    variable line_buffer   : line;
    variable new_mem       : memory  := (others => (others => '0'));
    variable start_address : std_logic_vector(31 downto 0);
    variable num_words     : integer := 0;
    variable word_var: word;
  begin
    while not endfile(text_file) loop
      readline(text_file, line_buffer);
      hex_read(line_buffer, start_address);
      read(line_buffer, num_words);
      report "start address: " & to_hstring(start_address);
      report "num_words: " & integer'image(num_words);
      readline(text_file, line_buffer);
      for i in 0 to num_words-1 loop
        hread(line_buffer, word_var);
      report "word: " & to_hstring(word_var);
        new_mem(to_integer(unsigned(start_address)) + i) := word_var;
        end loop;
    end loop;
    return new_mem;
  end function init;

  signal mem_signal : memory := init(fname => "./memory_init.txt");
begin
  process (enable, address, rw)
  begin
    if enable then
      if rw = '0' then
        data  <= mem_signal(to_integer(unsigned(address))) after read_time;
        ready <= '0', '1' after read_time;
      elsif rw = '1' then
        mem_signal(to_integer(unsigned(address))) <= data after write_time;
        ready                                     <= '0', '1' after write_time;
      end if;
    end if;
  end process;
end behavioural;
