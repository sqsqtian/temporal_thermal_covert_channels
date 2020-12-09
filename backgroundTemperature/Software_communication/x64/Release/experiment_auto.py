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

import datetime
from subprocess import call
import time

command_write_heater_rpd = 'E:\\catapult\\catapult\\v1.1\\Driver\\Bin\\RSU.exe -write E:\\RPG_shanquan\\leftover_heat\\20180822_part1_heater_18p_on_local.rpd'

command_write_sensor_rpd = 'E:\\catapult\\catapult\\v1.1\\Driver\\Bin\\RSU.exe -write E:\\RPG_shanquan\\leftover_heat\\20180823_part2_sensors.rpd'

command_reconfig_rpd = 'E:\\catapult\\catapult\\v1.1\\Driver\\Bin\\RSU.exe -reconfig'


command_start_heater = 'python start_heater.py'

command_sensor_map = 'python heat_map.py'


for i in range (0, 31):
    ret = call(command_write_heater_rpd)
    ret = call(command_reconfig_rpd)
    ret = call(command_start_heater)
    time.sleep(20 * 60) # waiting for the heater running for 20 minutes 
    ret = call(command_write_sensor_rpd)
    ret = call(command_reconfig_rpd)
    time.sleep(i * 10) # waiting for different intervals
    ret = call(command_sensor_map)
    time.sleep(20 * 60) # waiting for the board cooling off










