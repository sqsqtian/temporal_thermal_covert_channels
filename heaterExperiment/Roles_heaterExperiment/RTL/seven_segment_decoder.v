/*

 #
 # This code is part of the research paper:
 # "Temporal Thermal Covert Channels in Cloud FPGAs"
 #
 # Copyright (C) Shanquan Tian, CASLAB @ Yale
 # Authors: Shanquan Tian <shanquan.tian@yale.edu>
 #          Jakub Szefer <jakub.szefer@yale.edu>
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

module seven_segment_decoder (
    input [3:0] in,
    output [6:0] out
);

// Segment A
assign out[0]     = (~in[3]&~in[2]&~in[1]&in[0])
                    | (~in[3]&in[2]&~in[1]&~in[0])
                    | (in[3]&in[2]&~in[1]&in[0])
                    | (in[3]&~in[2]&in[1]&in[0]);

// Segment B
assign out[1]     = (in[3]&in[2]&~in[1]&~in[0])
                    | (~in[3]&in[2]&~in[1]&in[0])
                    | (in[3]&in[1]&in[0])
                    | (in[2]&in[1]&~in[0]);    
    
// Segment C
assign out[2]     = (in[3]&in[2]&~in[0])
                    | (in[3]&in[2]&in[1])
                    | (~in[3]&~in[2]&in[1]&~in[0]);    
                    
// Segment D
assign out[3]     = (~in[3]&in[2]&~in[1]&~in[0])
                    | (~in[3]&~in[2]&~in[1]&in[0])
                    | (in[2]&in[1]&in[0])
                    | (in[3]&~in[2]&in[1]&~in[0]);    

// Segment E
assign out[4]     = (~in[3]&in[2]&~in[1])
                    | (~in[3]&in[0])
                    | (~in[2]&~in[1]&in[0]);    
                    
// Segment F
assign out[5]     = (~in[3]&~in[2]&in[0])
                    | (~in[3]&~in[2]&in[1])
                    | (~in[3]&in[1]&in[0])
                    | (in[3]&in[2]&~in[1]&in[0]);        
        
// Segment G
assign out[6]     = (~in[3]&~in[2]&~in[1])
                    | (in[3]&in[2]&~in[1]&~in[0])
                    | (~in[3]&in[2]&in[1]&in[0]);            
    
endmodule
