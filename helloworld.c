/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/


/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"

#include "xil_io.h"
#include "myip_dac_controller.h"
#include "xparameters.h"


#define DAC_BASEADDR XPAR_MYIP_DAC_CONTROLLER_0_S00_AXI_BASEADDR


// Definicion de parametros del ADC
#include "myip_ADC_cont_8_reg.h"

#define ADC_BASEADDR XPAR_MYIP_ADC_CONT_8_REG_0_S00_AXI_BASEADDR

#define ADC_CTRL_REG    0x00 // Reg 0: Control (Bit 0 = START)
#define ADC_DATA_REG    0x04 // Reg 1: Dato de la Muestra (DATA_OUT, bits 11:0)
#define ADC_STAT_REG    0x08 // Reg 2: Estado (DRDY, Bit 0)
// Registros Nuevos
#define ADC_MAX_REG     0x10 // Reg 4: Valor Máximo Adquirido (16)
#define ADC_FREQ_REG    0x14 // Reg 5: Frecuencia de la Señal (20)
#define ADC_MIN_REG     0x18 // Reg 6: Valor Mínimo Adquirido (24)
// --- Parámetros de Calibración del ADC ---
#define ADC_BITS            12              // N = Número de bits del ADC
#define ADC_MAX_VAL         4095 // 2^12 - 1 = 4095
#define V_REF               3300            // Tensión de Referencia del ADC (¡CONFIRMA ESTE VALOR!)

// --- FUNCIÓN PRINCIPAL DE ADQUISICIÓN ADC ---

int read_single_sample() {
    u32 status;
    int sample;

    // 1. Iniciar la conversión (Pulso START)
    // Escribir 1 en el Registro 0 (ADC_CTRL_REG) activa el pulso START (Bit 0).
    MYIP_ADC_CONT_8_REG_mWriteReg(XPAR_MYIP_ADC_CONT_8_REG_0_S00_AXI_BASEADDR, ADC_CTRL_REG, 1);
    //MYIP_ADC_CONT_8_REG_mWriteReg(XPAR_MYIP_ADC_CONT_8_REG_0_S00_AXI_BASEADDR, ADC_CTRL_REG, 0);-


    // 2. Polling: Esperar hasta que DRDY esté listo (Bit 0 del Registro 2)
    // Bucle para leer el registro de estado hasta que el flag DRDY se active.
    do {
        status = MYIP_ADC_CONT_8_REG_mReadReg(XPAR_MYIP_ADC_CONT_8_REG_0_S00_AXI_BASEADDR, ADC_STAT_REG);
    } while ((status & 0x01) == 0); // Espera mientras el bit 0 (DRDY) sea '0'

    // 3. Lectura: Lee la muestra adquirida
    // El dato está en el Registro 1 (ADC_DATA_REG), limpiamos los bits superiores.
    sample = (int) (MYIP_ADC_CONT_8_REG_mReadReg(XPAR_MYIP_ADC_CONT_8_REG_0_S00_AXI_BASEADDR, ADC_DATA_REG) & 0x0FFF);

    // NOTA: El AXI Slave (S00_AXI) y la FSM se encargan de la sincronización y el latching.

    return sample;
}

int main()
{
    init_platform();

    print("Generando LUT...\n");

    MYIP_DAC_CONTROLLER_mWriteReg(XPAR_MYIP_DAC_CONTROLLER_0_S00_AXI_BASEADDR, 0, 0); //wren
    MYIP_DAC_CONTROLLER_mWriteReg(XPAR_MYIP_DAC_CONTROLLER_0_S00_AXI_BASEADDR, 12, 0); //start





        for(int i = 0; i < 16384; i++)
        {

			int j=i%4096;


        	MYIP_DAC_CONTROLLER_mWriteReg(XPAR_MYIP_DAC_CONTROLLER_0_S00_AXI_BASEADDR, 4, j);
        	MYIP_DAC_CONTROLLER_mWriteReg(XPAR_MYIP_DAC_CONTROLLER_0_S00_AXI_BASEADDR, 8, i);
        	MYIP_DAC_CONTROLLER_mWriteReg(XPAR_MYIP_DAC_CONTROLLER_0_S00_AXI_BASEADDR, 0, 1); //wren
			MYIP_DAC_CONTROLLER_mWriteReg(XPAR_MYIP_DAC_CONTROLLER_0_S00_AXI_BASEADDR, 0, 0); //wren

        };


        MYIP_DAC_CONTROLLER_mWriteReg(XPAR_MYIP_DAC_CONTROLLER_0_S00_AXI_BASEADDR, 12, 1);
        //MYIP_DAC_CONTROLLER_mWriteReg(XPAR_MYIP_DAC_CONTROLLER_0_S00_AXI_BASEADDR, 12, 0);

        print("LUT cargada.\n");


        xil_printf("Generación DAC iniciada. Iniciando adquisición ADC...\r\n");

        // 3. BUCLE PRINCIPAL DE ADQUISICIÓN ADC
            int acquired_sample;
            int acquisition_count = 0;
		// Variables para las nuevas lecturas
			u32 frequency_val;
			u32 max_val;
			u32 min_val;
			int mean_val; // Usaremos un float para el promedio
			// Nueva variable para la tensión
			int voltage_val;


            while(1)
            {
                    // A. Iniciar y Leer una Muestra (Mantenemos la adquisición individual)
                    acquired_sample = read_single_sample();

                    // B. Lectura de los Registros de la IP (Frecuencia, Máximo y Mínimo)
                    voltage_val = (int)(((long long)acquired_sample * V_REF) / ADC_MAX_VAL);// tensión de la señal

                    // La frecuencia se lee del registro 5 (offset 0x14)
                    frequency_val = MYIP_ADC_CONT_8_REG_mReadReg(ADC_BASEADDR, ADC_FREQ_REG);

                    // El máximo se lee del registro 4 (offset 0x10)
                    max_val = MYIP_ADC_CONT_8_REG_mReadReg(ADC_BASEADDR, ADC_MAX_REG) & 0x0FFF; // 12 bits

                    // El mínimo se lee del registro 6 (offset 0x18)
                    min_val = MYIP_ADC_CONT_8_REG_mReadReg(ADC_BASEADDR, ADC_MIN_REG) & 0x0FFF; // 12 bits

                    // C. Cálculo del Valor Medio
                    // Aseguramos que la operación se realice con flotantes para obtener precisión
                    mean_val = (max_val + min_val) / 2.0;

                    // D. Imprimir el resultado (Información detallada)
                    printf("--- Muestra #%d ---\r\n", acquisition_count++,acquired_sample);

                    printf("Dato Actual: %d (0x%x) -> Tension: %d.%03d V\r\n",
                                        acquired_sample, acquired_sample,
                                        voltage_val / 1000, voltage_val % 1000); // <-- LÍNEA MODIFICADA
                        printf("Frecuencia (Hz): %u\r\n", frequency_val);
                        printf("Valor Máximo: %u\r\n", max_val);
                        printf("Valor Mínimo: %u\r\n", min_val);
                        printf("Valor Medio (calc.): %.2d\r\n", mean_val);
                        printf("-------------------\r\n");


                    // E. Retardo
                    for (long i = 0; i < 50000000; i++);
                }

    cleanup_platform();
    return 0;
}
