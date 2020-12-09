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

 # FIFO
 # Usage: 1) Please Reset fifo at the biginning. For example, #10; reset_fifoout <= 0; #10; reset_fifoout <= 1; #10; reset_fifoout <= 0;
 #        2) Set rd as high for one clock cycle, you will get data after one cycle;
 #        3) Set wr as high for one clock cycle.
 #        4) Please do not wr and rd at the same time at the biggning. You can wr and rd at the same time if FIFO is not empty.

*/



module FIFO_Shanquan # (parameter abits = 4, dbits = 64)(
    input clock,
    input reset,
    input wr,
    input rd,
    input [dbits-1:0] din,
    output empty,
    output full,
    output [dbits-1:0] dout,
    output [7:0] size // debug
);
// abits is for address bits, namely number of records in fifo = 2^(number of address bits)
// dbits is for data bits, namely the data width of each record

reg [dbits-1:0] out; // output data 
reg [dbits-1:0] regarray[2**abits-1:0]; 
reg [abits-1:0] wr_reg, wr_next, wr_succ; //points to the register which should be written, current, next, successor(the possible next position)
reg [abits-1:0] rd_reg, rd_next, rd_succ; //points to the register which needs to be read from
reg full_reg, empty_reg, empty_next;
reg full_next;
assign full = full_reg;
assign empty = empty_reg;
assign dout = out;

wire wr_en;
assign wr_en = wr & ~full; //only write if write signal is high and fifo is not full
always @ (posedge clock) begin
  if(wr_en) begin
    regarray[wr_reg] <= din; 
  end
end

always @ (posedge clock) begin
  if(rd) begin
    out <= regarray[rd_reg];
  end
end


reg [7:0] size_reg = 0;
assign size = size_reg;

always @( posedge clock) begin
  //if(clock == 0) begin
    size_reg <= (wr_reg - rd_reg) % (2**abits);
  //end
end


always @ (posedge clock or posedge reset) begin
  if (reset) begin // Reset FIFO
    wr_reg <= 0;
    rd_reg <= 0;
    full_reg <= 1'b0;
    empty_reg <= 1'b1;
  end
  else begin
    wr_reg <= wr_next; 
    rd_reg <= rd_next;
    full_reg <= full_next;
    empty_reg <= empty_next;
    /*if((wr_reg - rd_reg) % (2**abits + 1) == 2**abits) begin
      full_reg <= 1'b1;   //its full now
    end*/
  end
end



always @(*) begin
  wr_succ = (wr_reg + 1)%(2**abits); // possible next position
  rd_succ = (rd_reg + 1)%(2**abits); 
  wr_next = wr_reg;  // the same
  rd_next = rd_reg;  
  full_next = full_reg;  
  empty_next = empty_reg;  
   
  case({wr,rd})
    //2'b00: do nothing

    2'b01: begin  //read
      if(~empty) begin //if fifo is not empty, you can read
        rd_next = rd_succ;
        full_next = 1'b0;
        if(rd_succ == wr_reg) begin // if possible next reading position is the same to writing position, then it is empty
          empty_next = 1'b1;  
        end
      end
    end
    
    2'b10: begin //write
      if(~full) begin // If fifo is not full, then you can write
        wr_next = wr_succ;
        empty_next = 1'b0;
        if(wr_succ == rd_reg) begin 
          full_next = 1'b1;  
        end 
      end
    end
    
    2'b11: begin //read and write at the same time
      wr_next = wr_succ;
      rd_next = rd_succ;
    end
    //
  endcase
  
end

endmodule
