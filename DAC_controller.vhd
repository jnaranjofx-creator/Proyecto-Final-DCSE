----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.11.2025 15:20:24
-- Design Name: 
-- Module Name: DAC_controller - Behavioral
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

entity DAC_controller is
    Port ( Data1 : in STD_LOGIC_VECTOR (11 downto 0);
           start : in STD_LOGIC;
           reg_start : in STD_LOGIC;
           nRST : in STD_LOGIC;
           clk50 : in STD_LOGIC;
           D1 : out STD_LOGIC;
           nSync : out STD_LOGIC;
           clk_out : out STD_LOGIC;
           Done : out STD_LOGIC);
end DAC_controller;

architecture Behavioral of DAC_controller is

        signal clk_25: std_logic;

        -- maquina finita de estados

        type estados is (IDLE, ShiftOUT,SyncData);
        signal e_act, e_sig : estados;
        
        signal enShift: std_logic;
        signal LoadData: std_logic;
        signal shiftcounter: unsigned(3 downto 0);
        
        -- sift register 
        
       signal reg : std_logic_vector(15 downto 0);
       
begin

conta : process(clk50, nRST)
begin
    if nRST = '0' then
        clk_25 <= '0';
    elsif rising_edge(clk50) then
        clk_25 <= not clk_25;  -- invierte cada ciclo -> divide la frecuencia por 2
    end if;
end process;

clk_out <= clk_25;

    P_s_FSM: process (clk_25,nrst)
    begin
        
        if nrst = '0' then
            e_act <= idle;
        elsif rising_edge(clk_25) then
            e_act <= e_sig;
        end if;
    end process;

FSM: process (e_act,start, shiftcounter,reg_start)
begin
    e_Sig <= e_act;
    
    case e_act is
        when IDLE =>
        
            enShift <= '0'; Done<= '1';
            nsync <= '1'; LoadData <= '1';
            
            if start = '1' or reg_start = '1' then
            e_sig <= shiftout;
            end if;
            
         when shiftOUT => 
            
            enShift <= '1'; Done<= '0';
            nsync <= '0'; LoadData <= '0';
            
            if shiftcounter = "1111" then
            e_sig <= SyncData;
            end if;
            
         when SyncData =>
         
            enShift <= '0'; Done<= '0';
            nsync <= '1'; LoadData <= '0';
            
            if start = '0' then
            e_sig <= IDLE;
            end if;
    end case;
end process;



    shift_register: process (clk_25,loaddata,enshift)
                    begin
                        if rising_edge(clk_25) then
                        
                        if nrst = '0' then 
                            reg <= (others => '0');
                            shiftcounter <= (others => '0');
                           -- D1 <= '0'; -- Inicialización forzada de la salida
                        
                            elsif loaddata = '1' then
                                reg(15 downto 12) <= "0000";
                                reg(11 downto 0) <= data1;
                                
                                shiftcounter <= (others => '0');
                            
                            elsif(enshift = '1') then
                        
                                reg <= reg(14 downto 0)& reg(15);
                                shiftcounter <= shiftcounter + 1;
                                
                            end if; 
--                            D1 <= reg(15);
                        end if;
                    end process;
--reg <= data1;
D1 <= reg(15);
--reg(15 downto 1) <= reg (14 downto 0);

end Behavioral;