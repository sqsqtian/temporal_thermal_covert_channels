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

 # SimpleRole

*/
 

import ShellTypes::*;

module SimpleRole
(
    // User clock and reset
    input                               clk,
    input                               rst, 

    // Simplified Memory interface
    output MemReq                       mem_reqs        [1:0],
    input                               mem_req_grants  [1:0],
    input MemResp                       mem_resps       [1:0],
    output                              mem_resp_grants [1:0],

    // PCIe Slot DMA interface
    input PCIEPacket                    pcie_packet_in,
    output                              pcie_full_out,

    output PCIEPacket                   pcie_packet_out,
    input                               pcie_grant_in,

    // Soft register interface
    input SoftRegReq                    softreg_req,
    output SoftRegResp                  softreg_resp
);
    
    // Disable DRAM
    assign mem_reqs[0] = '{valid: 1'b0, isWrite: 1'b0, addr: 64'b0, data: 512'b0};
    assign mem_resp_grants[0] = 1'b0;
    assign mem_reqs[1] = '{valid: 1'b0, isWrite: 1'b0, addr: 64'b0, data: 512'b0};
    assign mem_resp_grants[1] = 1'b0;
    
    // Disable softreg
    //assign softreg_resp = '{valid: 1'b0, data: 64'b0};

    /************************  Shanquan's Test ************************************/

reg [2:0] i = 3'b010;
always@(posedge clk) begin
  reset_uart <= i[0];
  i <= i >> 1;
end


wire       reset_uart;
wire [7:0] data_out;
wire       data_out_en;
wire       data_out_ready;

wire [7:0] data_in;
wire       data_in_en;
wire       data_in_ready;

wire [7:0] debug_1;

tacc_pseudo_uart 
#(
  .DATA_WIDTH (8),
  .FIFO_DATA_WIDTH (64)
) 
pseudo_uart(
  .clk    (clk),
  .rst    (reset_uart),
  .to_uart_data   (data_out),
  .to_uart_write_en  (data_out_en),
  .to_uart_ready  (data_out_ready),
  .from_uart_ready  (data_in_ready),
  .from_uart_read_en  (data_in_en),
  .from_uart_data (data_in),
  .debug1  (debug_1),
  .rx (softreg_req),
  .tx (softreg_resp)
);




top #(
  .DATA_WIDTH(8)  
)
top_test (
  .clk              (clk),
  .data_in_rd_ready    (data_in_ready),
  .data_in_rd_en       (data_in_en),
  .data_in          (data_in),
  .data_out_wr_ready   (data_out_ready),
  .data_out_wr_en      (data_out_en),
  .data_out         (data_out)
);








    /*************************************************************************/
    wire       loopbackQ_enq;
    PCIEPacket loopbackQ_in;
    wire       loopbackQ_full;
    PCIEPacket loopbackQ_out;
    wire       loopbackQ_empty;
    wire       loopbackQ_deq;
    
    assign loopbackQ_enq = pcie_packet_in.valid && !loopbackQ_full;
    assign loopbackQ_in = pcie_packet_in;
    assign loopbackQ_deq = !loopbackQ_empty && pcie_grant_in;
    
    assign pcie_packet_out = '{valid: !loopbackQ_empty, data: loopbackQ_out.data, slot: loopbackQ_out.slot, pad: loopbackQ_out.pad, last: loopbackQ_out.last};
    
    assign pcie_full_out = loopbackQ_full;
    
    FIFO
    #(
        .WIDTH     ($bits(PCIEPacket)),
        .LOG_DEPTH (9)
    )
    LoopbackQ
    (
        .clock     (clk),
        .reset_n   (~rst),
        .wrreq     (loopbackQ_enq),
        .data      (loopbackQ_in),
        .full      (loopbackQ_full),
        .q         (loopbackQ_out),
        .empty     (loopbackQ_empty),
        .rdreq     (loopbackQ_deq)
    );
    
endmodule
