----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.11.2025 17:20:29
-- Design Name: 
-- Module Name: tb_ADC_controller - Behavioral
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_ADC_Controller is
end tb_ADC_Controller;

architecture Behavioral of tb_ADC_Controller is

    -- 1. Declaramos tu diseño (El que acabamos de hacer)
    component ADC_Controller
    Port (
        clk_200      : in STD_LOGIC;
        RESET    : in STD_LOGIC;
        MISO     : in STD_LOGIC;
        Start    : in STD_LOGIC;
        CS       : out STD_LOGIC;
        SCLK     : out STD_LOGIC;
        DRDY     : out STD_LOGIC;
        Data_Out : out STD_LOGIC_VECTOR(11 downto 0)
    );
    end component;

    -- 2. Cables para conectar
    signal clk_200 , reset, start, miso : std_logic := '0';
    signal cs, sclk, drdy : std_logic;
    signal data_out : std_logic_vector(11 downto 0);

begin

    -- 3. Conectamos los cables a tu diseño
    uut: ADC_Controller Port map (
        clk_200  => clk_200 , RESET => reset, MISO => miso, Start => start,
        CS => cs, SCLK => sclk, DRDY => drdy, Data_Out => data_out
    );

    -- 4. Generador de Reloj (100 MHz -> 10 ns)
    process begin
        clk_200  <= '0'; wait for 2.5 ns;
        clk_200 <= '1'; wait for 2.5 ns;
    end process;

    -- 5. "Simulador" simple del ADC (Solo para que entre algún dato)
    -- Si CS baja, enviamos bits (cambiando MISO cada vez que SCLK baja)
    process begin
        wait until falling_edge(cs); -- Espera a que la máquina arranque
        
        for i in 1 to 16 loop
            wait until falling_edge(sclk); -- Sincronizado con tu reloj generado
            miso <= not miso; -- Cambia 0 -> 1 -> 0 -> 1... (Datos ficticios)
        end loop;
        
        miso <= '0'; -- Limpia la línea al acabar
    end process;

    -- 6. EL GUIÓN DE LA PRUEBA (Lo que hace cambiar los estados)
    process begin
        -- A. Empezamos reseteando para ir a HOLD
        reset <= '0';
        wait for 100 ns;
        reset <= '1';
        wait for 50 ns;

        -- B. ¡ACCIÓN! Pulsamos START
        -- Esto es lo que dispara el cambio de HOLD -> FPORCH
        start <= '1';
        --wait for 10 ns; -- Un ciclo de reloj es suficiente
        --start <= '0';

        -- C. Esperamos a ver qué pasa
        -- La máquina debería ir sola: FPORCH -> SHIFTING -> BPORCH -> HOLD
        wait until drdy = '1'; -- Esperamos hasta que termine
        
        wait for 100 ns; -- Un poco de margen final
        wait; -- Fin de la simulación
    end process;

end Behavioral;

