/*

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

*/

module Heater(
    input ro_heating_enable,
    output wire [63:0] ro_heating_counter_value
);

//reg [63:0] total_value = 0;
assign ro_heating_counter_value = send_0 + send_1 + send_2 + send_3 + send_4 + send_5 + send_6 + send_7 + send_8 + send_9 + send_10 + send_11 + send_12 + send_13 + send_14 + send_15;
wire [63:0] send_0 ;
wire [63:0] send_1 ;
wire [63:0] send_2 ;
wire [63:0] send_3 ;
wire [63:0] send_4 ;
wire [63:0] send_5 ;
wire [63:0] send_6 ;
wire [63:0] send_7 ;
wire [63:0] send_8 ;
wire [63:0] send_9 ;
wire [63:0] send_10 ;
wire [63:0] send_11 ;
wire [63:0] send_12 ;
wire [63:0] send_13 ;
wire [63:0] send_14 ;
wire [63:0] send_15 ;

heater_1024 heater_0 (
    .enable (ro_heating_enable),
    .send   (send_0)
);

heater_1024 heater_1 (
    .enable (ro_heating_enable),
    .send   (send_1)
);

heater_1024 heater_2 (
    .enable (ro_heating_enable),
    .send   (send_2)
);

heater_1024 heater_3 (
    .enable (ro_heating_enable),
    .send   (send_3)
);

heater_1024 heater_4 (
    .enable (ro_heating_enable),
    .send   (send_4)
);

heater_1024 heater_5 (
    .enable (ro_heating_enable),
    .send   (send_5)
);

heater_1024 heater_6 (
    .enable (ro_heating_enable),
    .send   (send_6)
);

heater_1024 heater_7 (
    .enable (ro_heating_enable),
    .send   (send_7)
);

heater_1024 heater_8 (
    .enable (ro_heating_enable),
    .send   (send_8)
);

heater_1024 heater_9 (
    .enable (ro_heating_enable),
    .send   (send_9)
);

heater_1024 heater_10 (
    .enable (ro_heating_enable),
    .send   (send_10)
);

heater_1024 heater_11 (
    .enable (ro_heating_enable),
    .send   (send_11)
);

heater_1024 heater_12 (
    .enable (ro_heating_enable),
    .send   (send_12)
);

heater_1024 heater_13 (
    .enable (ro_heating_enable),
    .send   (send_13)
);

heater_1024 heater_14 (
    .enable (ro_heating_enable),
    .send   (send_14)
);

heater_1024 heater_15 (
    .enable (ro_heating_enable),
    .send   (send_15)
);



endmodule
