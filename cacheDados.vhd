--7 julho
library ieee;
use ieee.std_logic_1164.all;

Entity data_cache is
	Port (
		HWDATA : in bit_vector(31 downto 0);
		
		HRDATA : out bit_vector(31 downto 0);
		
		HADDR32 : in bit_vector(31 downto 0);
		HRW : in bit;
		HENABLE : in bit;
		HREADY : out bit;
	);
end entity;
