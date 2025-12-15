# Proyecto-Final-DCSE
En este repositorio se encuentran los ficheros .vhd .xsa .bit .c del proyecto final de la asignatura de diseño de circuitos y sistemas electrónicos

Para la implementación del DAC se han usado los ficheros Addr_Crtl.vhd, RAM.vhd, DAC_controller.vhd y Sin_Axi.vhd, este ultimo es donde se encuentran instanciados todos los anteriores, junto con estos documentos se adjunta su test bench siendo el fichero Sin_Axi_tb.

Por otro lado para el ADC, se ha usado el ADC_controller, donde se podrán encontrar también los módulos de procesamientos de datos y el test bench es el tb_adc_controller.vhd, para la comrpobación de el funcionamiento de los bloques defrecuencia, se ha forzado a cambiar de 1 a 0 la variable de prev_sample_is_positive.

