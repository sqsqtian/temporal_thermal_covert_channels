/*
Name: communication.cpp
Description: Catapult FPGA soft register communication example.

#
# Copyright (C) Shanquan Tian, CASLAB @ Yale
# Author: Shanquan Tian <shanquan.tian@yale.edu>
#
# MIT License
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
# documentation files (the ""Software""), to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and 
# to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#  
# THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE 
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

*/


#include <concurrent_queue.h>
#include <concrt.h>
#include <ppl.h>
#include <assert.h>

#include "../../Driver/Include/FPGACoreLib.h"
#pragma comment(lib, "../../Driver/Bin/FPGACoreLib.lib")
#include "../../Driver/Include/FPGAManagementLib.h"

#include "FPGA_PCIeJobDispatcher.h"

typedef uint32_t PCIePayload;

typedef struct {
    bool eom;
    PCIePayload payload;
} PCIeSendPayload;


#define PCIE_HIP_NUM 0x0

#define MAX_BUF_SIZE_BYTES 65536
#define USE_INTERRUPT false

#define CONFIG_DRAM_CHAN0 600
#define CONFIG_DRAM_CHAN1 700
#define CONFIG_DRAM_INTERLEAVED 800

typedef enum {
    SINGLE_INORDER = 0,
    SINGLE_OOO = 1,
    PARALLEL = 2,
    PARALLEL_DECOUPLED = 3
} TestMode;



// Enable PCIe (default disabled)
void enablePCIe(FPGA_HANDLE fpgaHandle) {
    DWORD pcie = -1;
    FPGA_ReadShellRegister(fpgaHandle, 0, &pcie);

    // set control_register[6]
    pcie = pcie | (1 << 6);
    FPGA_WriteShellRegister(fpgaHandle, 0, pcie);
}

// Disable PCIe
void disablePCIe(FPGA_HANDLE fpgaHandle) {
    DWORD pcie = -1;
    FPGA_ReadShellRegister(fpgaHandle, 0, &pcie);

    // clear control_register[6]
    pcie = pcie & ~(1 << 6);
    FPGA_WriteShellRegister(fpgaHandle, 0, pcie);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        printf("Please input 1 random number. FPGA will plus 1 and return it.\n\n");        
        exit(1);
    }
   
    FPGA_HANDLE fpgaHandle;

    // Open handle to FPGA 
    //printf("Opening handle...\n");
    FPGA_CreateHandle(&fpgaHandle, PCIE_HIP_NUM, 0x0, NULL, NULL);

	// Configure hardware settings
    //FPGA_WriteSoftRegister(fpgaHandle, CONFIG_DRAM_INTERLEAVED, 0);
    FPGA_WriteSoftRegister(fpgaHandle, CONFIG_DRAM_CHAN0, 0);

    // Enable PCIe (default disabled)
    enablePCIe(fpgaHandle);
    DWORD reg = -1;
    FPGA_ReadShellRegister(fpgaHandle, 0, &reg);
    //printf("Control register value: 0x%08x\n\n", reg);

	/*****************************  Shell register test ***********************************/
	/*
	The choices:
	1 for reading Board ID;
	2 for reading Shell Release version;
	3 for reading Chip ID;
	4 for reading current Temperature;
	10 for taking the measurement, starting sensors;
	11 for starting the heater;
	12 for closing the heater;
	*/



	DWORD shanquan_test;
	DWORD shanquan_test2;
	DWORD regTem;
	DWORD64 shanquan_test3;
	int currentTemperature;
	int minTemperature;
	int maxTemperature;

	 

	if (atoi(argv[1]) == 1) { //1 for reading Board ID;
		FPGA_ReadShellRegister(fpgaHandle, 57, &shanquan_test);
		printf("Board ID: 0x%x\n", shanquan_test);
	}
	else if (atoi(argv[1]) == 2) {//2 for reading Shell Release version;
		FPGA_ReadShellRegister(fpgaHandle, 58, &shanquan_test);
		printf("Shell Release Version: 0x%x\n", shanquan_test);
	}
	else if (atoi(argv[1]) == 3) {//3 for reading Chip ID;
		FPGA_ReadShellRegister(fpgaHandle, 62, &shanquan_test);
		FPGA_ReadShellRegister(fpgaHandle, 63, &shanquan_test2);
		printf("Chip ID: 0x%08x%08x\n", shanquan_test2, shanquan_test);

	}
	else if (atoi(argv[1]) == 4) {//4 for reading current Temperature;
		FPGA_ReadShellRegister(fpgaHandle, 71, &regTem);
		printf("Shell register %d, Temperature register: 0x%x\n", 71, regTem);
		currentTemperature = (regTem & 0xff00) >> 8;
		//minTemperature = (regTem & 0xff0000) >> 16;
		//maxTemperature = (regTem & 0xff000000) >> 24;
		printf("Current temperature = %d\n", currentTemperature);
	}
	else if (atoi(argv[1]) == 10) { //10 for taking the measurement, starting sensors;
		FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(4)); // start RO
		//printf("Input value: %d (dec)\n", 4);
		Sleep(10);

		// write 10000
		FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(0)); //printf("Input value: %d (dec)\n", 0);
		Sleep(10);
		FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(0)); //printf("Input value: %d (dec)\n", 0);
		Sleep(10);
		FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(0)); //printf("Input value: %d (dec)\n", 0);
		Sleep(10);
		FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(0)); //printf("Input value: %d (dec)\n", 0);
		Sleep(10);
		FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(0)); //printf("Input value: %d (dec)\n", 0);
		Sleep(10);
		FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(0)); //printf("Input value: %d (dec)\n", 0);
		Sleep(10);
		FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(39)); //printf("Input value: %d (dec)\n", 39);
		Sleep(10);
		FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(16)); //printf("Input value: %d (dec)\n", 16);
		Sleep(10);
		FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(0)); //printf("Input value: %d (dec)\n", 0);// To end the input
		Sleep(100);

		for (int j = 0; j < 8; j++) {
			for (int i = 0; i < 16; i++) {
				FPGA_ReadSoftRegister(fpgaHandle, 1234, &shanquan_test3);
				if (shanquan_test3 == 110000) {
					printf("Error! Output value: %d , this is error code 0, fifo_out is empty\n", shanquan_test3);
				}
				else {
					printf("%d Output value: %d\n", i, shanquan_test3);
				}
				Sleep(10);
			}
		}

	}
	else if (atoi(argv[1]) == 11) { //11 for starting the heater;
		FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(2)); //  turn the heater on
		//printf("Input value: %d (dec)\n", 2);
		FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(0)); //printf("Input value: %d (dec)\n", 0);// To end the input
		printf("Heater turned on.\n");
	}
	else if (atoi(argv[1]) == 12) { //12 for closing the heater;
		FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(3)); // turn the heater off
		FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(0)); //printf("Input value: %d (dec)\n", 0);// To end the input
		//printf("Input value: %d (dec)\n", 3);
		Sleep(10);

		for (int i = 0; i < 8; i++) {
			FPGA_ReadSoftRegister(fpgaHandle, 1234, &shanquan_test3);
			if (shanquan_test3 == 110000) {
				printf("Error! Output value: %d , this is error code 0, fifo_out is empty\n", shanquan_test3);
			}
			else {
				printf("%d Output value: %d\n", i, shanquan_test3);
			}
			Sleep(10);
		}
	}
	else {
		printf("NULL\n");
	}
	
	
    FPGA_CloseHandle(fpgaHandle);

    return 0;
}



// First, initialize
//FPGA_ReadSoftRegister(fpgaHandle, 0, &shanquan_test3);


// Then , start test.
//int num = 3;
/*for (int i = 0; i < 16; i++) {
FPGA_WriteSoftRegister(fpgaHandle, 200, (DWORD64)(0));
printf("Input value: %d\n", (0));
Sleep(100);
}*/



//FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(2)); // start RO heater
//printf("Input value: %x (dec)\n", 2);
/*
int choice;
int v;
for (;;) {
printf("Please input choices, 1 for write; 2 for read; \n");
scanf("%d", &choice);
if (choice == 1) {
printf("Please input value you want to write:");
scanf("%d", &v);
FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(v)); // start RO
printf("Input value: %d (dec)\n", v);
Sleep(100);
}
else if (choice == 2) {
FPGA_ReadSoftRegister(fpgaHandle, 1234, &shanquan_test3);
if (shanquan_test3 == 110000) {
printf("Output value: %d, this is error code 0, fifo_out is empty\n", shanquan_test3);
}
else {
printf("Output value: %d\n", shanquan_test3);
}
Sleep(100);
}
}
*/

/*
int choice;
for (;;) {
printf("Please input choices, 1 for enabling RO sensor; 2 for turn on heater; 3 for turn off heater\n");
scanf("%d", &choice);
if (choice == 1) {

FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(4)); // start RO
printf("Input value: %d (dec)\n", 4);
Sleep(100);

// write 10000
FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(0)); printf("Input value: %d (dec)\n", 0);
Sleep(100);
FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(0)); printf("Input value: %d (dec)\n", 0);
Sleep(100);
FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(0)); printf("Input value: %d (dec)\n", 0);
Sleep(100);
FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(0)); printf("Input value: %d (dec)\n", 0);
Sleep(100);
FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(0)); printf("Input value: %d (dec)\n", 0);
Sleep(100);
FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(0)); printf("Input value: %d (dec)\n", 0);
Sleep(100);
FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(39)); printf("Input value: %d (dec)\n", 39);
Sleep(100);
FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(16)); printf("Input value: %d (dec)\n", 16);
Sleep(100);
FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(0)); printf("Input value: %d (dec)\n",0 );// To end the input
Sleep(2000);

for (int j = 0; j < 4; j++) {
for (int i = 0; i < 16; i++) {
FPGA_ReadSoftRegister(fpgaHandle, 1234, &shanquan_test3);
if (shanquan_test3 == 110000) {
printf("%d  Output value: %d, this is error code 0, fifo_out is empty\n", i, shanquan_test3);
}
else {
printf("%d  Output value: %d\n", i, shanquan_test3);
}
Sleep(100);
}
}

FPGA_ReadShellRegister(fpgaHandle, 71, &regTem);
printf("Shell register %d, Temperature register: 0x%x\n", 71, regTem);
currentTemperature = (regTem & 0xff00) >> 8;
printf("current temperature = %d\n\n", currentTemperature);
}
else if (choice == 2) {
FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(2)); //  turn the heater on
printf("Input value: %d (dec)\n", 2);
FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(0)); printf("Input value: %d (dec)\n", 0);// To end the input
Sleep(100);
}
else if (choice == 3) {
FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(3)); // turn the heater off
FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(0)); printf("Input value: %d (dec)\n", 0);// To end the input
printf("Input value: %d (dec)\n", 3);
Sleep(100);

for (int i = 0; i < 8; i++) {
FPGA_ReadSoftRegister(fpgaHandle, 1234, &shanquan_test3);
if (shanquan_test3 == 110000) {
printf("%d  Output value: %d, this is error code 0, fifo_out is empty\n", i, shanquan_test3);
}
else {
printf("%d  Output value: %d\n", i, shanquan_test3);
}
Sleep(100);
}



}
}


*/


/*
for (int i = 0; i < 9; i++) {
FPGA_WriteSoftRegister(fpgaHandle, 1234, (DWORD64)(atoi(argv[1])+i));
printf("Input value: %d\n", (atoi(argv[1]) + i));
Sleep(100);
}
Sleep(100);
//FPGA_ReadSoftRegister(fpgaHandle, 0, &shanquan_test3);
for (int i = 0; i < 16;i++) {
FPGA_ReadSoftRegister(fpgaHandle, 1234, &shanquan_test3);
if (shanquan_test3 == 110000) {
printf("Output value: %d, this is error code 0, fifo_out is empty\n", shanquan_test3);
}
else {
//printf("Output value: %d, Debug1=%d\n", shanquan_test3&0x1f, ((shanquan_test3 & 0xe0) >> 5));
printf("Output value: %d\n", shanquan_test3);
}


Sleep(100);
}
*/