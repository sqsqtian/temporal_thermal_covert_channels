 #
 #
 # This code is part of the research paper:
 # "Temporal Thermal Covert Channels in Cloud FPGAs"
 #
 # This code measures the temperature pattern on server.
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
f = open ("server_temperature_pattern_" + today + ".txt", "a+")

# First, read board ID and chip ID.
p = subprocess.Popen(["communication.exe", "1"], stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
line =  p.stdout.readline()
f.write(line+"\n")
print(line)

p = subprocess.Popen(["communication.exe", "3"], stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
line =  p.stdout.readline()
f.write(line+"\n")
print(line)

time.sleep(10) # sleep for 10 seconds

# Measure the server temperature every 5 minutes.

for d in range (0,30):
    for h in range (0, 24):
        for t in range (0, 30):
            p = subprocess.Popen(["communication.exe", "4"], stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.STDOUT )
            line =  p.stdout.readline()#The first line was dropped 
            line =  p.stdout.readline()
            on_chip_sensor = line.split()[3]
            now = str(datetime.datetime.now())
            f.write(now + "\t" + on_chip_sensor + "\n")
            print (now + "\t" + on_chip_sensor + "\n")
            time.sleep(120) # 120s = 2 minutes



f.close()

