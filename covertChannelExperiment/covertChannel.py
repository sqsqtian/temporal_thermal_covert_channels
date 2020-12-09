 #
 # This code is part of the research paper:
 # "Temporal Thermal Covert Channels in Cloud FPGAs"
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

 #
 # Covert Channel experiment.
 # Note: 1. addr_* are TACC servers, you should apply for them;
 #       2. 01010101 is an example;
 #       


import subprocess
import time
import multiprocessing
import sys
import heating
import sensor

NUM_BITS = 8



addr_13b03 = 'catcm13b03.production.tacc.utexas.edu'
addr_13b06 = 'catcm13b06.production.tacc.utexas.edu'
addr_13b09 = 'catcm13b09.production.tacc.utexas.edu'
addr_13b12 = 'catcm13b12.production.tacc.utexas.edu'
addr_14b03 = 'catcm14b03.production.tacc.utexas.edu'
addr_14b06 = 'catcm14b06.production.tacc.utexas.edu'
addr_14b09 = 'catcm14b09.production.tacc.utexas.edu'
addr_14b12 = 'catcm14b12.production.tacc.utexas.edu'


if (len(sys.argv) != 2):
    print "Please input the string you want to transmit. Example: \n\npython covertChannel.py 01010101\n"
    sys.exit()



def covertChannel (infoStr = '01010101'):
    covertChannelSend(infoStr)
    time.sleep(1) # waiting interval
    covertChannelReceive()


def covertChannelSend (infoStr):
    hotBoards = []
    if (infoStr[0] == '1'):
        hotBoards.append(addr_13b03)
    if (infoStr[1] == '1'):
        hotBoards.append(addr_13b06)
    if (infoStr[2] == '1'):
        hotBoards.append(addr_13b09)
    if (infoStr[3] == '1'):
        hotBoards.append(addr_13b12)
    if (infoStr[4] == '1'):
        hotBoards.append(addr_14b03)
    if (infoStr[5] == '1'):
        hotBoards.append(addr_14b06)
    if (infoStr[6] == '1'):
        hotBoards.append(addr_14b09)
    if (infoStr[7] == '1'):
        hotBoards.append(addr_14b12)
    
    if (len(hotBoards) == 0):# If all 0s
        return 0
    else:
        p = multiprocessing.Pool(NUM_BITS) # There are NUM_BITS threads.
        p.map(heating.heating, hotBoards)
        return 0

def covertChannelReceive ():
    boards = [addr_13b03, addr_13b06, addr_13b09, addr_13b12, addr_14b03, addr_14b06, addr_14b09, addr_14b12 ]
    p = multiprocessing.Pool(NUM_BITS) # There are NUM_BITS threads.
    p.map(sensor.ROSensor, boards)


if __name__ == '__main__':
    infoStr = str(sys.argv[1])
    covertChannel(infoStr)


