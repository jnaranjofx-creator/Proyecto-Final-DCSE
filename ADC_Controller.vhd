----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.11.2025 19:43:36
-- Design Name: 
-- Module Name: ADC_Controller - Behavioral
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

entity ADC_Controller is
generic (
        DIVISOR: integer := 5
);
Port (
        CLK_200      : in  STD_LOGIC; -- Reloj 100MHz
        RESET    : in  STD_LOGIC;
        MISO     : in  STD_LOGIC; -- Entrada de datos del ADC
        
        -- Variables EXACTAS del dibujo (Entradas/Salidas)
        Start    : in  STD_LOGIC;
        CS       : out STD_LOGIC;
        SCLK     : out STD_LOGIC;
        DRDY     : out STD_LOGIC;
        cnt      : out std_logic_vector(31 downto 0);
        clk_100  : out std_logic;
        clk_25  : out std_logic;
        clk_20  : out std_logic;
        
        max : out std_logic_vector(31 downto 0); -- máximo
        frec : out std_logic_vector(31 downto 0); -- frecuencia
        min : out std_logic_vector(31 downto 0); -- minimo
        
        Data_Out : out STD_LOGIC_VECTOR(11 downto 0)
    );
end ADC_Controller;

architecture Behavioral of ADC_Controller is

    -- 1. ESTADOS DEL DIBUJO
    type state_type is (HOLD, FPORCH, SHIFTING, BPORCH);
    signal e_act, e_sig : state_type;

    -- 2. VARIABLES DEL DIBUJO (Contadores)
    -- "cnt": Usado en FPORCH (<3) y BPORCH (<1)
    signal cnt_sg : unsigned (31 downto 0);
    signal en_cnt : std_logic; 
    signal en_shift : std_logic; 
    
    -- "cntData": Usado en SHIFTING (<16)
    signal cntData : unsigned (31 downto 0);

    -- 3. VARIABLES AUXILIARES (No están en el dibujo pero son necesarias)
    signal shift_reg : std_logic_vector(15 downto 0); -- Para guardar lo que entra
    signal sclk_int  : std_logic; -- Copia interna de SCLK

    -- Prescaler: Necesario para que "SCLK Activo" vaya a velocidad humana (10 MHz)
    -- 100MHz / 10MHz = 10 ciclos (5 arriba, 5 abajo)
    
    signal s_clk_100: std_logic;
    signal s_clk_25: std_logic;
    signal s_clk_20: std_logic;
    
    signal count_div_8   : unsigned (6 downto 0);
    signal count_div_10   : unsigned (8 downto 0);
    signal tick      : std_logic := '0'; -- Permiso para mover SCLK
    signal fcntData      : std_logic := '0'; -- Permiso para mover SCLK
    signal data_out_sg : STD_LOGIC_VECTOR(11 downto 0);
    
    
    -- Constantes para el Estimador de Frecuencia
    constant CLK_FREQ_HZ : integer := 20000000; -- Frecuencia del contador (s_clk_20, 20 MHz)
    constant ZERO_REF : std_logic_vector(11 downto 0) := "100000000000"; -- Punto de referencia Cero (o Punto Medio, si es offset binario)

    -- Señales internas para el Estimador de Frecuencia
    signal data_in_unsigned : unsigned(15 downto 0);
    signal sample_is_positive : std_logic := '0';
    signal prev_sample_is_positive : std_logic := '0';
    signal zero_cross_detected : std_logic := '0';

    -- Contadores para el período
    signal period_counter : unsigned(31 downto 0) := (others => '0');
    signal period_value : unsigned(31 downto 0) := (others => '0');
    
        -- Señales internas de 12 bits para MAX/MIN
    signal local_max : unsigned(11 downto 0); 
    signal local_min : unsigned(11 downto 0); 
    signal first_sample_flag : std_logic := '1';        
        -- Dato actual (data_out_sg es 11 downto 0, lo usamos directamente)
        constant current_data : unsigned(11 downto 0) := unsigned(data_out_sg);

begin

    -- Conectar señal interna a salida física
    SCLK <= sclk_int;
    Data_Out <= data_out_sg;
    -- Asignar las señales internas a los puertos de salida
    clk_100 <= s_clk_100;
    clk_25  <= s_clk_25;
    clk_20  <= s_clk_20;
    -- Prescaler
    process(CLK_200, RESET)
    begin
        if RESET = '0' then
            s_clk_100 <= '0';
            s_clk_25  <= '0';
            s_clk_20  <= '0';
            count_div_8 <= (others => '0');
            count_div_10 <= (others => '0');
            tick    <= '0';
        elsif rising_edge(CLK_200) then
            tick <= '0';
            s_clk_100 <= not s_clk_100;
            
            if count_div_8 = "011" then
                count_div_8 <= (others => '0'); -- Resetea a "00"
                s_clk_25 <= not s_clk_25;
                tick    <= '1'; -- ¡Momento de actuar!
            else
                count_div_8 <= count_div_8 + 1;
            end if;
            
            if count_div_10 = "100" then -- Compara con el valor 4
                count_div_10 <= (others => '0');
                s_clk_20 <= not s_clk_20;
            else
                count_div_10 <= count_div_10 + 1;
            end if;
            
        end if;
    end process;



    -- MÁQUINA DE ESTADOS 
   FSM_P: process(s_clk_20, RESET, sclk_int, tick)
    begin
    
        if RESET = '0' then
            e_act    <= HOLD;
            
--            CS       <= '1';
--            sclk_int <= '1';
--            DRDY     <= '0';
--            cnt_sg      <= (others => '0');
--            cntData  <= (others => '0');
--            Data_Out <= (others => '0');

        elsif rising_edge(s_clk_20) then
            e_act <= e_sig;                  
        end if;
        end process;
   
        
    cnt_proces: process(s_clk_20,reset)
    begin
    if reset = '0' then 
        cnt_sg <= (others => '0');
        elsif rising_edge(s_clk_20)then
            if en_cnt = '1'then
--                cnt_sg <= (others => '0');
             if cnt_sg < 9 then
                cnt_sg <= cnt_sg + 1;
             end if;
             else 
                cnt_sg <= (others => '0');           
         end if;
    end if;
    end process;    
        
 cnt <= std_logic_vector(cnt_sg);   
     
                 
    shift_register : process (s_clk_20,reset)
    begin
    if reset = '0' then
        shift_reg <= (others => '0');
        cntData <= (others => '0');
        sclk_int <= '1';       
       elsif rising_edge(s_clk_20) then 
            if en_shift = '1' then    
            
                if fcntData = '1' then
                    cntData <= (others => '0');
                else
                sclk_int <= not sclk_int; -- Genera la onda cuadrada
                    
                    -- Leer dato en flanco de subida (cuando sclk pasa de 0 a 1)
                    if sclk_int = '0' then
                        shift_reg <= shift_reg(14 downto 0) & MISO;
                        cntData   <= cntData + 1; -- Incrementamos cntData
                    end if;
                    end if;
--              else   
--                cntData <= (others => '0');
            end if;
       end if;      
       end process;   
       
       fcntData <= '1' when cntData =16 else '0';
        
        FSM: process(e_act,e_sig,cnt_sg,start,cntData)
        begin
        
         e_Sig <= e_act;
        case e_act is
                
                -- ---------------------------------------------------
                -- BURBUJA 1: HOLD
                -- Salidas: CS='1', DRDY='0', SCLK=Desh
                -- ---------------------------------------------------
                when HOLD =>
                    CS       <= '1';
--                    sclk_int <= '1'; -- Deshabilitado (Alto)
--                    cnt_sg   <= (others => '0');   -- Preparamos contadores a 0
--                    cntData  <= (others => '0');
                    en_cnt <= '0';
                    en_shift <= '0';
                    DRDY <= '0';
                    
                    -- Transición: Start = '1' --> FPORCH
                    if Start = '1' then
                        e_sig <= FPORCH;
                    end if;

                -- ---------------------------------------------------
                -- BURBUJA 2: FPORCH
                -- Salidas: CS='0', DRDY='0', SCLK=Desh
                -- ---------------------------------------------------
                when FPORCH =>
                    CS <= '0';
                    en_cnt <= '1';
                    en_shift <= '0';
                    DRDY <= '0';
                    -- Condición: cnt < 3 T100MHz
                    if cnt_sg = 3 then
                        -- Transición: cnt = 3 --> SHIFTING
                        e_sig <= SHIFTING;                       
                    end if;

                -- ---------------------------------------------------
                -- BURBUJA 3: SHIFTING
                -- Salidas: CS='0', DRDY='0', SCLK=Activo
                -- ---------------------------------------------------
                when SHIFTING =>
                    CS <= '0';
                    en_cnt <= '0';
                    en_shift <= '1';                   
                    DRDY <= '0';
                    -- Lógica de "SCLK Activo" (usando el tick del prescaler)


                    -- Condición de Salida del dibujo: cntData = 16 --> BPORCH
                    if cntData = 16 then
                        e_sig <= BPORCH;                        
                    end if;

                -- ---------------------------------------------------
                -- BURBUJA 4: BPORCH
                -- Salidas: CS='0', DRDY='1', SCLK=Desh
                -- ---------------------------------------------------
                when BPORCH =>
                    CS       <= '0';
--                    sclk_int <= '1'; -- Deshabilitado
                    en_cnt <= '1';
                    en_shift <= '0';
                    DRDY     <= '1'; -- ¡Salida activa según tabla!
                    -- Condición: cnt < 1 T100MHz
                    if cnt_sg = 1 then
                        -- Transición: cnt = 1 --> HOLD
                        e_sig    <= HOLD;
                        data_out_sg <= shift_reg(11 downto 0);
                    end if;

            end case;
           
    end process;

-- Conversión y Detección de Signo
    process(s_clk_20, RESET)
    begin
        if RESET = '0' then
            prev_sample_is_positive <= '0';
            sample_is_positive <= '0';
            zero_cross_detected <= '0';
        elsif rising_edge(s_clk_20) then
            -- Guardar el signo anterior en cada ciclo de reloj
            prev_sample_is_positive <= sample_is_positive;
            
            -- ¿Es el dato actual 'positivo' (por encima del ZERO_REF)?
            if data_out_sg > ZERO_REF then
                sample_is_positive <= '1';
            else
                sample_is_positive <= '0';
            end if;
            
            -- Detección de Cruce por Cero (flanco ascendente)
            -- Se detecta cuando pasa de 'negativo' ('0') a 'positivo' ('1')
            if (prev_sample_is_positive = '0') and (sample_is_positive = '1') then
                zero_cross_detected <= '1';
            else
                zero_cross_detected <= '0';
            end if;
        end if;
    end process;


-- Estimador de Frecuencia (Frecuencímetro)
    process(s_clk_20, RESET)
    begin
        if RESET = '0' then
            period_counter <= (others => '0');
            period_value <= (others => '0');
            frec <= (others => '0');
        elsif rising_edge(s_clk_20) then
            
            if zero_cross_detected = '1' then
                -- ¡Cruce por cero detectado!
                -- Si se detecta un flanco ascendente, la cuenta anterior es el período
                period_value <= period_counter; -- Guardar el período medido
                period_counter <= (others => '0'); -- Reiniciar el contador de período
                
                -- Calcular Frecuencia (F = F_clk / T_count)
                -- Evitar división por cero
                if period_value /= 0 then
                    -- Esta división se realiza en cada cruce por cero
                    frec <= std_logic_vector(to_unsigned(CLK_FREQ_HZ / to_integer(period_value), frec'length));
                else
                    frec <= (others => '0'); -- Frecuencia indefinida o muy alta
                end if;
            else
                -- Mientras no haya cruce, incrementar el contador de período
                period_counter <= period_counter + 1;
            end if;
        end if;
    end process;
    
-- Proceso de Máximo y Mínimo (Corregido con Inicialización Robusta)
process(s_clk_20, RESET)
    -- El dato actual se define aquí para la comparación de 12 bits
    constant current_data : unsigned(11 downto 0) := unsigned(data_out_sg); 
begin
    if RESET = '0' then
        -- En el RESET, inicializar el flag y las señales a valores conocidos
        local_max <= (others => '0');
        local_min <= (others => '1');
        first_sample_flag <= '1';
    elsif rising_edge(s_clk_20) then
    
        if e_act = HOLD then
            local_max <= (others => '0'); -- Reiniciar a 0
            local_min <= (others => '1'); -- Reiniciar a 4095
            first_sample_flag <= '1'; -- Aseguramos la re-inicialización con el primer dato
        end if;
        -- 1. Inicialización con la primera muestra válida
        if first_sample_flag = '1' then
            -- Forzar MAX y MIN a ser igual a la primera muestra real
            local_max <= current_data;
            local_min <= current_data;
            first_sample_flag <= '0'; -- Desactivar el flag después del primer ciclo
        else
            -- 2. Lógica de comparación normal
            
            -- MAX
            if current_data > local_max then
                local_max <= current_data;
            end if;
            
            -- MIN
            if current_data < local_min then
                local_min <= current_data;
            end if;
        end if;
        
    end if;
end process;

-- Asignación a las salidas de 32 bits (Fuera del proceso)
max <= std_logic_vector(resize(local_max, max'length));
min <= std_logic_vector(resize(local_min, min'length));
    -- 'frec' ya se asigna dentro del proceso de estimación, pero si lo sacas, sería:
    -- frec <= std_logic_vector(frec_sg);
    
end Behavioral;