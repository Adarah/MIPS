--7 julho
library ieee;
use ieee.std_logic_1164.all;

Entity data_cache is
	Port (
		HWDATA  : in bit_vector(31 downto 0);
		
		HRDATA  : out bit_vector(31 downto 0);
		
		HADDR32 : in bit_vector(31 downto 0);
		HRW     : in bit;
		HENABLE : in bit;
		HREADY  : out bit;
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
	subtype tag_type  is std_logic_vector( 1 downto 0);-- tag de 2 bits
	
	type cache_line is array(0 to 15) of word_type;-- bloco de 16 words
	type block_type is -- "objeto" bloco de memória
		record
			valid : std_logic; -- "valid" 1 bit
			tag : tag_type; -- tag de 2 bits
			data : cache_line; -- bloco de 16 words
		end record;
	type cache_type is array(0 to 255) of block_type; --do menor pro maior