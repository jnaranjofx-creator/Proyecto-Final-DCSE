----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.11.2025 15:31:36
-- Design Name: 
-- Module Name: Sin_Axi_tb - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity Sin_Axi_tb is
end Sin_Axi_tb;

architecture Behavioral of Sin_Axi_tb is
      -- Parámetros
    constant ADDR_WIDTH : integer := 14;
    constant DATA_WIDTH : integer := 12;    
    
        component Sin_Axi
            Port ( clk50 : in STD_LOGIC;
           nRST : in STD_LOGIC;
           reg_start: in std_logic;
            D1 : out STD_LOGIC;
           nSync : out STD_LOGIC;
           clk_out : out STD_LOGIC;
           wr_en : in STD_LOGIC;
           data_in : in STD_LOGIC_VECTOR (data_width-1 downto 0);
           addr_wr : in STD_LOGIC_VECTOR (addr_width-1 downto 0));
        end component;
  
    -- Señales locales
    signal clk50_tb  : std_logic := '0';
    signal nRST_tb   : std_logic := '1';
    signal wr_en_tb  : std_logic := '0';
    signal data_in_tb : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal addr_wr_tb : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal D1_tb, nSync_tb, clk_out_tb : std_logic;
    signal reg_start_tb : std_logic := '1';

begin

    -- Instancia del DUT
    UUT : entity work.Sin_Axi
        port map (
            clk50   => clk50_tb,
            nRST    => nRST_tb,
            D1      => D1_tb,
            reg_start => reg_start_tb,
            nSync   => nSync_tb,
            clk_out => clk_out_tb,
            wr_en   => wr_en_tb,
            data_in => data_in_tb,
            addr_wr => addr_wr_tb
        );

    -------------------------------------------------------------------------
    -- Generador de reloj 50 MHz
    -------------------------------------------------------------------------
    clk_process : process
    begin
        clk50_tb <= not clk50_tb;
        wait for 10 ns;
    end process;

    -------------------------------------------------------------------------
    -- Señal de reset
    -------------------------------------------------------------------------
    rst_process : process
    begin
        nRST_tb <= '0';
        reg_start_tb <= '0';
        wait for 50 ns;
        nRST_tb <= '1';        
        reg_start_tb <= '1';
         wait for 50 ns;
         nRST_tb <= '1';
         reg_start_tb <= '0';
--     wait for 1250 ns;
--     reg_start_tb <= '0';
        wait;
    end process;

    -------------------------------------------------------------------------
    -- Proceso de escritura inicial en RAM
    -------------------------------------------------------------------------
    write_proc : process
    begin
        wait for 100 ns; -- esperar a que reset termine
        for i in 0 to 27 loop
            wr_en_tb   <= '1';
            data_in_tb <= std_logic_vector(to_unsigned(i * 100, DATA_WIDTH));
            addr_wr_tb <= std_logic_vector(to_unsigned(i, ADDR_WIDTH));
            wait for 20 ns;
        end loop;
        wr_en_tb <= '0';
        wait;
    end process;

end Behavioral;
