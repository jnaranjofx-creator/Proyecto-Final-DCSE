----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.11.2025 15:23:01
-- Design Name: 
-- Module Name: Addr_Ctrl - Behavioral
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

entity Addr_Ctrl is
 generic (
        ADDR_WIDTH : integer := 14
    );
    Port ( clk50 : in STD_LOGIC;
           nRST : in STD_LOGIC;
           DONE : in STD_LOGIC;
           addr_rd : out STD_LOGIC_VECTOR (13 downto 0);
           START : out STD_LOGIC);
end Addr_Ctrl;

architecture Behavioral of Addr_Ctrl is
    -- Señales internas
    signal done_d   : std_logic ;  -- detector de flanco
    signal enCnt    : std_logic ;  -- pulso habilitador
    signal count    : unsigned(ADDR_WIDTH-1 downto 0);
    signal start_reg: std_logic ;
    constant MAX_ADDR : unsigned(ADDR_WIDTH-1 downto 0) := (others => '1');
    
    signal done_d2 : std_logic := '0';
    
begin

    --------------------------------------------------------------------
    -- 1?? Detector de flanco de subida de DONE
    --------------------------------------------------------------------
        process(clk50, nRST)
    begin
        if nRST = '0' then
            done_d <= '1';
             enCnt  <= '0';
        elsif rising_edge(clk50) then
            if done_d = '0' and DONE = '1' then
                enCnt <= '1';
            else
                enCnt <= '0';
            end if;
--            enCnt  <= (not done_d) and DONE;  -- flanco ascendente
            done_d <= DONE;
        end if;
    end process;

    --------------------------------------------------------------------
    -- 2?? Contador de direcciones (incrementa en flanco de DONE)
    --------------------------------------------------------------------
    process(clk50, nRST)
    begin
        if nRST = '0' then
            count <= (others => '0');
        elsif rising_edge(clk50) then
            if enCnt = '1' then
            if count = MAX_ADDR then -- Reinicio cíclico al final
                    count <= (others => '0');
                else
                    count <= count + 1; -- Incremento normal
                end if;
            end if;
        end if;
    end process;

    addr_rd <= std_logic_vector(count);

    --------------------------------------------------------------------
    -- 3?? Registro de START (pulso sincronizado con DONE)
    --------------------------------------------------------------------
--    process(clk50, nRST)
--    begin
--        if nRST = '0' then
--            start_reg <= '0';
--        elsif rising_edge(clk50) then
--            start_reg <= enCnt;  -- genera pulso sincronizado
--        end if;
--    end process;

    START <= enCnt; -- start_reg;

end Behavioral;
