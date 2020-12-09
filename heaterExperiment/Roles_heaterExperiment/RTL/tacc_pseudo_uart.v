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

 # Interface for UART, based on CASLAB exisitng UART

*/

module tacc_pseudo_uart #(parameter DATA_WIDTH = 8,FIFO_DATA_WIDTH = 64) (
  input                    clk,             //clk_50m,
  input                    rst,             // (none)

// data : host <- shell <- pseudo uart <- role

  output                   to_uart_ready,   //tx_busy,        ///waiting
  input                    to_uart_write_en,   //wr_en,
  input   [DATA_WIDTH-1:0] to_uart_data,    //din,

// data : host -> shell -> pseudo uart -> role
  
  output                   from_uart_ready, //rdy,            ///waiting
  input                    from_uart_read_en, //rdy_clr, 
  output  [DATA_WIDTH-1:0] from_uart_data,   //dout

  output [7:0]    debug1,
  // replace below connections with connections to Role

  input  SoftRegReq  rx,
  output SoftRegResp tx
);


//reg [7:0] debug1_reg;
assign debug1 = size_fifoin;




localparam WAIT = 0,
           IDLE = 1,
           RECEIVE = 2,
           SEND = 3,
           READ_FROM_FIFO = 4,
           WRITE_TO_FIFO = 5;

reg [7:0] state1 = IDLE;

reg [6:0] state2 = IDLE;
reg [7:0] return_state2 = IDLE;

reg wr_fifoin_return = 0;
reg rd_fifoin_return = 0;

// ready signal
assign from_uart_ready = ~ empty_fifoin;
assign to_uart_ready = ~ full_fifoout;


assign from_uart_data = dout_fifoin[7:0];


/*****************************  fifo in *****************************************/
reg softreg_write_en = 0;
reg [7:0] ctl=0;
always @(posedge clk) begin
  if(rx.valid && rx.isWrite && (rx.addr == 32'd1234)) begin
    softreg_write_en <= 1;
  end
  else begin
    if(softreg_write_en==1 && ctl < 1) begin
      ctl <= ctl + 1;
    end
    else begin
      ctl <= 0;
      softreg_write_en <= 0;
    end
  end
end

reg [63:0] softreg_write_data;

always @ (posedge clk) begin
  if (rx.valid && rx.isWrite && (rx.addr == 1234)) begin
    softreg_write_data <= rx.data;
  end
end

/*
always @ (posedge (rx.valid && rx.isWrite)) begin
  softreg_write_data <= rx.data;
end
*/



always @(posedge clk or posedge rst) begin // fifo in
  if (rst) begin
    // reset
    reset_fifoin <= 1;
    
  end
  else begin // main
    reset_fifoin <= 0;
    wr_fifoin <= 0;
    //from_uart_valid_reg <= 0;

    case(state1) 
      IDLE: begin
        if(softreg_write_en == 1) begin //If it is valid, write.   data : host -> shell -> pseudo uart -> role 
          state1 <= RECEIVE;
          //return_state1 <= RECEIVE;
        end
        else if(from_uart_read_en == 1 && from_uart_ready == 1) begin
          //??
          state1 <= READ_FROM_FIFO;
          //return_state1 <= READ_FROM_FIFO;
        end
        else begin
          state1 <= IDLE;
          //return_state1 <= IDLE;
        end
      end

      RECEIVE: begin
      wr_fifoin <= 1;
      din_fifoin <= softreg_write_data;
      state1 <= IDLE;
    
    /*
      if(softreg_write_data != 0) begin 
        wr_fifoin <= 1;
        din_fifoin <= softreg_write_data;
        state1 <= IDLE;
      end
      else begin
        state1 <= IDLE;
      end
      */
      end

      READ_FROM_FIFO: begin
        //from_uart_data_reg = dout_fifoin[7:0];
        if(empty_fifoin != 1) begin

          state1 <= READ_FROM_FIFO;
          //return_state1 <= READ_FROM_FIFO;
        end
        else begin
          state1 <= IDLE;
          //return_state1 <= IDLE;
        end
      end

    endcase
  end
end



/*****************************  fifo out *****************************************/



reg first_order = 1;
reg [DATA_WIDTH:0] old_order = 0;


reg softreg_read_en = 0;
always @( *) begin
  if(rx.valid & (~rx.isWrite) && (rx.addr == 1234)) begin
    softreg_read_en = 1;
  end
  
  if(tx.valid == 1) begin
    softreg_read_en = 0;
  end
end

reg[FIFO_DATA_WIDTH-1:0] error_0 = 110000;

always @(posedge clk or posedge rst) begin // 
  if (rst) begin
    // reset
    reset_fifoout <= 1;
  end
  else begin // main
    reset_fifoout <= 0;

    wr_fifoout <= 0;
    rd_fifoout <= 0;
    tx.valid <= 0;

    case(state2) 
      WAIT: begin
        state2 <= return_state2;
      end

      IDLE: begin
        if(softreg_read_en == 1) begin
          if(empty_fifoout != 1) begin // If it is not empty
            wr_fifoout <= 0;
            rd_fifoout <= 1;
            state2 <= WAIT;
            return_state2 <= SEND;
          end
          else begin // If it is empty
            tx.valid <= 1;
            tx.data = error_0;
            state2 <= IDLE;
          end
        end
        else begin // If there is no request
          if(to_uart_write_en == 1 && to_uart_ready == 1) begin
            state2 <= WRITE_TO_FIFO;
          end
          else begin
            state2 <= IDLE;
          end
        end
      end

      SEND: begin
        tx.valid = 1'b1;
        tx.data = dout_fifoout;
        wr_fifoout <= 0;
        rd_fifoout <= 0;
        state2 <= IDLE;
      end

      WRITE_TO_FIFO: begin
        wr_fifoout <= 1;
        rd_fifoout <= 0;
        din_fifoout <= to_uart_data;
        state2 <= IDLE;
      end
    endcase
  end
end



reg         reset_fifoin = 1;
reg         wr_fifoin = 0;
//reg         rd_fifoin = 0;
reg [FIFO_DATA_WIDTH-1:0]  din_fifoin;
wire        empty_fifoin;
wire        full_fifoin;
wire [FIFO_DATA_WIDTH-1:0] dout_fifoin;
wire [7:0]       size_fifoin;

FIFO_Shanquan #(
    .abits (5),
    .dbits (FIFO_DATA_WIDTH)
)
fifo_in
(
    .clock     (clk),
    .reset     (reset_fifoin),
    .wr        (wr_fifoin),
    .rd        (from_uart_read_en),
    .din       (din_fifoin),
    .empty     (empty_fifoin),
    .full      (full_fifoin),
    .dout      (dout_fifoin),
    .size      (size_fifoin)
);

reg         reset_fifoout = 1;
reg         wr_fifoout = 0;
reg         rd_fifoout = 0;
reg [FIFO_DATA_WIDTH-1:0]  din_fifoout;
wire        empty_fifoout;
wire        full_fifoout;
wire [FIFO_DATA_WIDTH-1:0] dout_fifoout;
wire [7:0]       size_fifoout;


FIFO_Shanquan #(
    .abits (8),
    .dbits (FIFO_DATA_WIDTH)
)
fifo_out
(
    .clock     (clk),
    .reset     (reset_fifoout),
    .wr        (wr_fifoout),
    .rd        (rd_fifoout),
    .din       (din_fifoout),
    .empty     (empty_fifoout),
    .full      (full_fifoout),
    .dout      (dout_fifoout),
    .size      (size_fifoout)
);






endmodule