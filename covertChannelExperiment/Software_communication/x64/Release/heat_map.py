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

import time
import datetime
import subprocess

# Open a file to be written into.
today = str(datetime.datetime.today())
today = today[0:10]+"_"+today[11:13]+"-"+today[14:16]
f = open (today+".txt", "a+")

# First, read board ID and chip ID.
p = subprocess.Popen(["communication.exe", "1"], stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
line =  p.stdout.readline()
f.write(line+"\n")
print(line)

p = subprocess.Popen(["communication.exe", "3"], stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
line =  p.stdout.readline()
f.write(line+"\n")
print(line)

time.sleep(1) # sleep for 1 seconds

data_num = 0 # number of the rows of data

# Then, start & close sensors, calculate the oscillation number of 0~7, for 10 minutes, every 10 seconds
period = 4
print("Start 8 RO sensors...\n")
for t in range(0, 10 * (int (60 / period))):
    p = subprocess.Popen(["communication.exe", "10"], stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.STDOUT )
    for i in range(0, 8):# There are 8 sensors
        for j in range(0, 2):# First is sensor output, sencond is timer conter
            value = 0
            for k in range(0, 8):# Each output set includes 8 bytes
                line =  p.stdout.readline()
                reg = line.split()[3]
                reg = int(reg)
                value = value + reg*2**(8*(7-k))
            if j == 0 :
                # The sensor value
                now = str(datetime.datetime.now())
                f.write(str(data_num)+"\t" + now+"\t"+str(value)+"\t")
                print(str(data_num)+"\t" + now+"\t"+str(value)+"\t")
                data_num += 1
            else :
                # The timer counter value
                value = value - 1 # This is a trick in Verilog module
                f.write(str(value)+"\n")
                print(str(value)+"\n")
    # and read on-chip thermal sensor
    p = subprocess.Popen(["communication.exe", "4"], stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.STDOUT )
    line =  p.stdout.readline()#The first line was dropped 
    line =  p.stdout.readline()
    on_chip_sensor = line.split()[3]
    now = str(datetime.datetime.now())
    f.write(str(data_num)+"\t" +now + "\t" +"on_chip_sensor = " + on_chip_sensor + "\n")
    print(str(data_num)+"\t" +now + "\t" +"on_chip_sensor = " + on_chip_sensor + "\n")
    data_num +=1
    time.sleep(period)





f.close()


