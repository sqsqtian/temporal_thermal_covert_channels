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

# First, read board ID and chip ID.
p = subprocess.Popen(["communication.exe", "1"], stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
line =  p.stdout.readline()
print(line)

p = subprocess.Popen(["communication.exe", "3"], stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
line =  p.stdout.readline()
print(line)

time.sleep(1) # sleep for 3 seconds

data_num = 0 # number of the rows of data


print("Then, turn the heater on...\n")
# Third, turn on the heater, and read & calculate sensor oscillation number every 2 seconds for 10 minutes,
#period_2 = 2

p = subprocess.Popen(["communication.exe", "11"], stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
line =  p.stdout.readline()
print(line+"\n")

today = str(datetime.datetime.today())
today = today[0:10]+"_"+today[11:13]+"-"+today[14:16]
f = open('recordHeating_'+today+'.txt', 'w')
f.write('Heating process started at ' + today)
f.close()
#t = input("How long time? (in minutes)\n")
#now = str(datetime.datetime.now())
#print (now + "  start... \n")
#time.sleep(t * 60)

#now = str(datetime.datetime.now())
#print (now + "  end... \n")
