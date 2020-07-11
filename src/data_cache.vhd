
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity data_cache is
	Port (
		DATA   : inout std_logic_vector(31 downto 0);
				
		ADDR32 : in std_logic_vector(31 downto 0);
		RW     : in std_logic; -- 0 para Read, 1 para Write
		ENABLE : in std_logic;
		
		READY  : out std_logic;
		
		clk    : in std_logic
	);
end Entity;

Architecture arquitetura of data_cache is
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
	
	subtype word_type is std_logic_vector(31 downto 0);-- word de 32 bits
	subtype tag_type  is std_logic_vector( 2 downto 0);-- tag de 3 bits 
	
	type cache_line is array(0 to 15) of word_type;-- bloco de 16 words
	type block_type is -- "objeto" bloco de memória
		record
			valid : std_logic; -- "valid" 1 bit
			tag : tag_type; -- tag de 3 bits
			data : cache_line; -- bloco de 16 words
			LRU : std_logic; -- 1 indica que eh o bloco meno recentemente usado
		end record;
	
	type conjunto_type is array(0 to 1) of block_type;
			
	type cache_type is array(0 to 127) of conjunto_type; --do menor pro maior
	
	signal writebuffer : word_type;
	signal buffercheio : std_logic:='0';
	signal addr_Buffer   : std_logic_vector(31 downto 0);
	
	  -- DATA cache signals
   signal tag          : tag_type;
   signal word_offset  : integer range 0 to 15;
   signal conjunto_offset : integer range 0 to 127;

  
   constant empty_block : block_type := (
    valid => '0',
    tag   => (others => '0'),
    data  => (others => (others => '0')),
	 LRU   => '1'
    );
	 
	 
	 signal cache : cache_type := (others => (others => empty_block)); --inicializa o cache com todos os blocos vazios
	  -- main memory signals
	 signal mm_data    : word_type;
	 signal mm_address : std_logic_vector(31 downto 0);
	 signal mm_ready   : std_logic;

	  -- states
	 type state_type is (IDLE, COMPARE_TAG, ALLOCATE, WRITE_BUFFER_CHEIO);
	 signal current_state : state_type := IDLE;
	 signal next_state    : state_type := IDLE;
	 signal hit           : boolean    := false;
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
      prev_address  <= ADDR32;
    -- report "changing state";
    end if;
  end process;

  tag             <= ADDR32(15 downto 13);
  conjunto_offset <= to_integer(unsigned(ADDR32(12 downto 6)));
  word_offset     <= to_integer(unsigned(ADDR32(5 downto 2)));
  changed         <= '0' when prev_address = ADDR32 else '1';

  actions : process(clk, current_state, mm_ready, buffercheio) is
    variable assignements : integer range 0 to 63 := 0;
  begin
    case current_state is
      when IDLE =>
         ready <= '1';
         if changed = '1' then
          ready <= '0', '1' after 5 ns;
          next_state <= COMPARE_TAG;
         end if;
      when COMPARE_TAG =>
	
				if cache(conjunto_offset)(0).valid = '1' and cache(conjunto_offset)(0).tag = tag then
					if RW = '0' then 
					 data       <= cache(conjunto_offset)(0).data(word_offset);
					 next_state <= IDLE;
					 hit        <= true;
					 report "HIT! Read No bloco 0 do conjunto";
					 
					elsif RW = '1' and buffercheio = '0' then
					 writebuffer <= data;
					 next_state  <= IDLE;
					 hit         <= true;
					 buffercheio <= '1';
					 addr_Buffer <= ADDR32;
					 report "HIT! Write No bloco 0 do conjunto, buffer livre";
					 
					elsif RW = '1' and buffercheio = '1' then
					 next_state  <= WRITE_BUFFER_CHEIO;
					 hit         <= false;
					 report "HIT! Write No bloco 0 do conjunto, buffer CHEIO";
					 
					else
					 next_state <= IDLE;
					 report "RW não tem valor 0 ou 1!";
					end if;
					
				elsif cache(conjunto_offset)(1).valid = '1' and cache(conjunto_offset)(1).tag = tag then
					if RW = '0' then 
					 data       <= cache(conjunto_offset)(1).data(word_offset);
					 next_state <= IDLE;
					 hit        <= true;
					 report "HIT! Read No bloco 1 do conjunto";
					 
					elsif RW = '1' and buffercheio = '0' then
					 writebuffer <= data;
					 next_state  <= IDLE;
					 hit         <= true;
					 buffercheio <= '1';
					 addr_Buffer <= ADDR32;
					 report "HIT! Write No bloco 1 do conjunto, buffer livre";
					 
					elsif RW = '1' and buffercheio = '1' then
					 next_state  <= WRITE_BUFFER_CHEIO;
					 hit         <= false;
					 report "HIT! Write No bloco 1 do conjunto, buffer CHEIO";
					 
					else
					 next_state <= IDLE;
					 report "RW não tem valor 0 ou 1!";
					end if;
			   else  -- deu MISS.
				 ready <= '0';
				 next_state <= ALLOCATE;
				 mm_address <= ADDR32(31 downto 6) & std_logic_vector(to_unsigned(assignements, 6));
				 hit        <= false;
			    report "MISS :(";
			   
				end if;
			  
		

		when WRITE_BUFFER_CHEIO =>
			if buffercheio = '0' then
				addr_Buffer <= ADDR32;
				buffercheio <= '1';
				next_state  <= IDLE;
			end if;
	
			

      when ALLOCATE =>
			if cache(conjunto_offset)(0).LRU = '1' then
	   	  mm_address <= ADDR32(31 downto 6) & std_logic_vector(to_unsigned(assignements, 6));
			  if rising_edge(mm_ready) then
				  report "assignemnts: " & integer'image(assignements);
				  cache(conjunto_offset)(0).data(assignements/4) <= mm_data;
				  cache(conjunto_offset)(0).tag                  <= ADDR32(15 downto 13);
				  mm_address                                     <= ADDR32(31 downto 6) & std_logic_vector(to_unsigned(assignements, 6));
				  if assignements > 4 * (cache_line'length - 1) then
					 cache(conjunto_offset)(0).valid <= '1';
					 next_state                <= COMPARE_TAG;
					 assignements              := 0;
					 cache(conjunto_offset)(0).LRU <= '0';
					 cache(conjunto_offset)(1).LRU <= '1';
				  else
					 assignements := assignements + 4;
					 --next_state   <= ALLOCATE;
				  end if;
			  end if;
			  
			elsif cache(conjunto_offset)(1).LRU = '1' then
	   	  mm_address <= ADDR32(31 downto 6) & std_logic_vector(to_unsigned(assignements, 6));
			  if rising_edge(mm_ready) then
				  report "assignemnts: " & integer'image(assignements);
				  cache(conjunto_offset)(1).data(assignements/4) <= mm_data;
				  cache(conjunto_offset)(1).tag                  <= ADDR32(15 downto 13);
				  mm_address                                     <= ADDR32(31 downto 6) & std_logic_vector(to_unsigned(assignements, 6));
				  if assignements > 4 * (cache_line'length - 1) then
					 cache(conjunto_offset)(1).valid <= '1';
					 next_state                <= COMPARE_TAG;
					 assignements              := 0;
					 cache(conjunto_offset)(1).LRU <= '0';
					 cache(conjunto_offset)(0).LRU <= '1';
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

  
  
  
	tratamentodebuffercheio : process(buffercheio, addr_Buffer) is
	begin
		if rising_edge(buffercheio) then
			mm_address <= addr_Buffer;
		end if;
		
		if rising_edge(mm_ready) then
			buffercheio <= '0';
		end if;
		
	end process tratamentodebuffercheio;

	
	
	end arquitetura;
	