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




import subprocess
import time


addr_13b03 = 'catcm13b03.production.tacc.utexas.edu'
addr_13b06 = 'catcm13b06.production.tacc.utexas.edu'
addr_13b09 = 'catcm13b09.production.tacc.utexas.edu'
addr_13b12 = 'catcm13b12.production.tacc.utexas.edu'
addr_14b03 = 'catcm14b03.production.tacc.utexas.edu'
addr_14b06 = 'catcm14b06.production.tacc.utexas.edu'
addr_14b09 = 'catcm14b09.production.tacc.utexas.edu'
addr_14b12 = 'catcm14b12.production.tacc.utexas.edu'




def heating (addr):
    sshConnect = 'sshpass -p YourPassword ssh userName@' + addr
    cmd0 = 'powershell; cd E:\\catapult\\v1.1\\Software\\communication\\x64\\Release ;'
    cmd1 = 'E:\\catapult\\v1.1\\Driver\\Bin\\RSU.exe -write E:\\20180822_part1_heater_18p_on_local.rpd;'
    cmd2 = 'E:\\catapult\\v1.1\\Driver\\Bin\\RSU.exe -reconfig;'
    cmd3 = 'python start_heater.py;'
    cmd = cmd0 + cmd1 + cmd2 + cmd3
    commands = sshConnect.split() + [cmd]
    print commands
    p = subprocess.call( commands )
    print ("Heater has been started, now start waiting...\n")
    time.sleep(10*60)
    return 0



if __name__ == '__main__':
    heating(addr_13b06)


