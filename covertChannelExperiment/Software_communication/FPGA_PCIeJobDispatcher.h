/*
Name: FPGA_PCIeJobDispatcher.h
Description: Catapult PCIe job dispatcher, wraps up FPGA API calls

Copyright (c) Microsoft Corporation
 
All rights reserved. 
 
MIT License
 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
documentation files (the ""Software""), to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and 
to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE 
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#ifndef __FPGA_JOB_DISPATCHER__
#define __FPGA_JOB_DISPATCHER__

#include <stdint.h>
#include <concrt.h>
#include <concurrent_queue.h>
#include <vector>
#include <atomic>

#include "../../Driver/Include/FPGACoreLib.h"
#pragma comment(lib, "../../Driver/Bin/FPGACoreLib.lib")
#include "../../Driver/Include/FPGAManagementLib.h"



class FPGA_PCIeJobDispatcher {
private:
    typedef struct {
        uint32_t size;
        void* inputPtr;
        void* outputPtr;
    } Job;


    typedef struct {
        FPGA_HANDLE handle;
        uint32_t slot;
        volatile bool* finished;
        std::atomic<uint32_t>* dones;
        concurrency::concurrent_queue<Job>* inputQ;
        concurrency::concurrent_queue<Job>* outputQ;
    } DispatchParams;

    uint32_t numSlots;
    FPGA_HANDLE fpgaHandle;
    DispatchParams* dispatchParams;
    std::atomic<uint32_t> dones;

    bool useInterrupts;
    volatile bool finished;

    std::vector<concurrency::concurrent_queue<Job> > jobSendQueues;
    std::vector<concurrency::concurrent_queue<Job> > jobRecvQueues;

    static void dispatch(void* params);
public:
    FPGA_PCIeJobDispatcher(FPGA_HANDLE handle, uint32_t slots);
    ~FPGA_PCIeJobDispatcher();
    void sendJob(uint32_t slot, void* inputPtr, void* outputPtr, uint32_t size);
    bool recvJob(uint32_t slot, uint32_t& size);
    void shutdown();
};


void FPGA_PCIeJobDispatcher::dispatch(void* params) {
    DispatchParams* dparams = (DispatchParams*)params;
    FPGA_HANDLE fpgaHandle = dparams->handle;
    uint32_t slot = dparams->slot;
    volatile bool* finished = dparams->finished;
    std::atomic<uint32_t>* dones = dparams->dones;
    concurrency::concurrent_queue<Job>* inputQ = dparams->inputQ;
    concurrency::concurrent_queue<Job>* outputQ = dparams->outputQ;

    FPGA_STATUS status = FPGA_STATUS_SUCCESS;
    bool useInterrupts = true;

    //printf("Starting dispatch slot %d, finished %d\n", slot, *finished);

    Job job;
    DWORD *inputBuf, *outputBuf;

    if ((status = FPGA_GetInputBufferPointer(fpgaHandle, slot, &inputBuf)) != FPGA_STATUS_SUCCESS) {
        printf("Slot %d FPGA_GetInputBufferPointer failed\n", slot);
        goto finish;
    };
    if ((status = FPGA_GetOutputBufferPointer(fpgaHandle, slot, &outputBuf)) != FPGA_STATUS_SUCCESS) {
        printf("Slot %d FPGA_GetOutputBufferPointer failed\n", slot);
        goto finish;
    }

    while (!*finished || !inputQ->empty()) {
        if (!inputQ->try_pop(job)) {
            concurrency::wait(0);
            continue;
        }

        // Clear output buffer as sanity check
        memset(outputBuf, 0, 64 * 1024);

        // If job exists, send it out
        memcpy(inputBuf, job.inputPtr, job.size);
        if ((status = FPGA_SendInputBuffer(fpgaHandle, slot, job.size, useInterrupts)) != FPGA_STATUS_SUCCESS) {
            printf("Slot %d FPGA_SendInputBuffer failed\n", slot);
            goto finish;
        }

        // Wait for response
        BOOL isDone = false;
        while (!isDone) {
            if ((status = FPGA_GetOutputBufferDone(fpgaHandle, slot, &isDone)) != FPGA_STATUS_SUCCESS) {
                printf("Slot %d FPGA_GetOutputBufferDone failed\n", slot);
                goto finish;
            }
            concurrency::wait(0);
        }

        uint32_t size;
        //printf("Waiting for response buf %d\n", slot);
        if ((status = FPGA_WaitOutputBuffer(fpgaHandle, slot, (DWORD*)&size, useInterrupts, 0)) != FPGA_STATUS_SUCCESS) {
            printf("Slot %d FPGA_WaitOutputBuffer failed\n", slot);
            goto finish;
        }
        memcpy(job.outputPtr, outputBuf, size);
        if ((status = FPGA_DiscardOutputBuffer(fpgaHandle, slot)) != FPGA_STATUS_SUCCESS) {
            printf("Slot %d FPGA_DiscardOutputBuffer failed\n", slot);
            goto finish;
        }

        //printf("Buf %d received\n", slot);
        outputQ->push({ size, job.inputPtr, job.outputPtr });
        concurrency::wait(0);
    }

finish:
    dones->fetch_add(1, std::memory_order_relaxed);
    printf("Dispatch slot %d, finished = %d, error status = %d, done = %d\n", slot, *finished, status, *dones);
}

void FPGA_PCIeJobDispatcher::sendJob(uint32_t slot, void* inputPtr, void* outputPtr, uint32_t size) {
    jobSendQueues[slot].push({ size, inputPtr, outputPtr });
}

bool FPGA_PCIeJobDispatcher::recvJob(uint32_t slot, uint32_t& size) {
    Job job;
    bool success = jobRecvQueues[slot].try_pop(job);
    size = job.size;
    return success;
}


// TODO: CONVERT TO REGULAR THREADS! Use WinThreads?
FPGA_PCIeJobDispatcher::FPGA_PCIeJobDispatcher(FPGA_HANDLE handle, uint32_t slots) {
    fpgaHandle = handle;
    numSlots = slots;
    useInterrupts = true;
    finished = false;
    dones = 0;
    
    
    // Create job queues (TODO: improve perf with fixed-size circular queues)
    for (uint32_t i = 0; i < numSlots; i++) {
        jobSendQueues.push_back(concurrency::concurrent_queue<Job>());
        jobRecvQueues.push_back(concurrency::concurrent_queue<Job>());
    }

    // Construct dispatch options
    dispatchParams = new DispatchParams[slots];

    for (uint32_t i = 0; i < slots; i++) {
        dispatchParams[i].handle = handle;
        dispatchParams[i].slot = i;
        dispatchParams[i].finished = &finished;
        dispatchParams[i].dones = &dones;
        dispatchParams[i].inputQ = &jobSendQueues[i];
        dispatchParams[i].outputQ = &jobRecvQueues[i];

        Concurrency::CurrentScheduler::ScheduleTask(dispatch, (void*)&dispatchParams[i]);
    }
    
}

void FPGA_PCIeJobDispatcher::shutdown() {
    finished = true;
    
    while (dones != numSlots) {
        concurrency::wait(0);
    }
}

FPGA_PCIeJobDispatcher::~FPGA_PCIeJobDispatcher() {
    shutdown();
}
#endif