----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.11.2025 15:27:18
-- Design Name: 
-- Module Name: RAM - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RAM is
GENERIC(
    d_width : INTEGER := 12; --width of each data word
    addr_width : INTEGER := 14
    ); --number of data words the memory can store

    Port ( clk50 : in STD_LOGIC;
           wr_en : in STD_LOGIC;
           data_in : in STD_LOGIC_VECTOR (11 downto 0);
           addr_wr : in STD_LOGIC_VECTOR (13 downto 0);
           data_out : out STD_LOGIC_VECTOR (11 downto 0);
           addr_rd : in STD_LOGIC_VECTOR (13 downto 0));
end RAM;

ARCHITECTURE logic OF RAM IS
        TYPE memory IS ARRAY((2*addr_width)-1 DOWNTO 0) OF STD_LOGIC_VECTOR(d_width-1 DOWNTO 0); --data type for memory
        SIGNAL ram : memory; --memory array
BEGIN
PROCESS(clk50)
    BEGIN
        IF(clk50'EVENT AND clk50 = '1') THEN
            IF(wr_en = '1') THEN --write enable is asserted
                ram(TO_INTEGER(UNSIGNED(addr_wr))) <= data_in; --write input data into memory
            END IF;
            data_out <= ram(TO_INTEGER(UNSIGNED(addr_rd))); --output data at the stored address
        END IF;
END PROCESS;
END logic;

