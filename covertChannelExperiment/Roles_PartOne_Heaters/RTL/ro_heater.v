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
 
module ro_heater (
  input wire  enable,
  output wire out
);

// Keep RO_LENGTH an odd number
parameter RO_LENGTH = 3;

wire [RO_LENGTH:0] w /* synthesis keep = 1 */;

genvar i;

assign w[0] = w[RO_LENGTH] & enable;

generate 
  for(i=0; i<RO_LENGTH; i=i+1) begin : ro_gen_loop

    assign w[i+1] = ~ w[i];

  end
endgenerate

assign out = w[RO_LENGTH];

endmodule