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

 # Huge heater on TACC

*/


module top #(parameter DATA_WIDTH = 8) (
  input                    clk,
  
  input                    data_in_rd_ready,
  output                   data_in_rd_en,
  input [DATA_WIDTH-1:0]   data_in,
  
  input                    data_out_wr_ready,
  output                   data_out_wr_en,
  output [DATA_WIDTH-1:0]  data_out

);



// Buffer uart_wr_ready signal, hack to fix timing issue when FIFO is full

reg uart_wr_ready_prev = 0;
always @ (posedge clk)
  uart_wr_ready_prev <= data_out_wr_ready;


// Main state machine for controller

localparam IDLE = 0,
           WAIT = 1,
           READ_OPCODE = 2,
           WAIT_RO_COUNT = 3,
           SEND_RO_COUNT = 4,
           START_RO = 5,
           TURN_heater_ON = 6,
           TURN_heater_OFF = 7,
           SEND_HEATER_COUNT = 8;

reg [7:0] state = IDLE;
reg [7:0] return_state = IDLE;

wire [7:0] opcode_to_state;

assign opcode_to_state = (data_in == 8'b00000100) ? START_RO :
                         (data_in == 8'b00000010) ? TURN_heater_ON :
                         (data_in == 8'b00000011) ? TURN_heater_OFF :
                         IDLE;




reg [8:0] rd_ctr = 0;
reg [8:0] wr_ctr = 0;
reg [63:0] r_64_data = 0;
reg [63:0] ro_counter_send = 0;
reg [63:0] timer_counter_send = 0;

reg[10:0] select_sensor = 0;


always @ (posedge clk)
begin

  data_out_wr_en = 1'b0;
  data_in_rd_en = 1'b0;
  ro_and_timer_reset = 1'b0;

  case (state)
    WAIT:
      state <= return_state;

    IDLE: begin
      if(data_in_rd_ready)
        state <= READ_OPCODE;
    end

    READ_OPCODE:
      if(data_in_rd_ready)
      begin
        data_in_rd_en <= 1'b1;
        return_state <= opcode_to_state;
        state <= WAIT;
      //if(opcode_to_state == START_RO) begin
        //select_sensor <= 0;
      //end
      end

    START_RO: begin
      if (select_sensor == 0) begin
        if(data_in_rd_ready)
        begin
          r_64_data <= {r_64_data[55:0], data_in};
          data_in_rd_en <= 1'b1;
          if (rd_ctr == 7)
          begin
            ro_and_timer_reset <= 1'b1;
            ro_sensor_enable <= 8'b00000001; // 8 sensors
            return_state <= WAIT_RO_COUNT;
            state <= WAIT;
            rd_ctr <= 0;
          end
          else
          begin
            rd_ctr <= rd_ctr + 1;
            return_state <= START_RO;
            state <= WAIT;
          end
        end
      end
      else begin // select sensor is 1,2,3,4,5,6,7
        ro_and_timer_reset <= 1'b1;
        //ro_sensor_enable <= ro_sensor_enable << 1;
        return_state <= WAIT_RO_COUNT;
        state <= WAIT;

      end
    end
      

    WAIT_RO_COUNT:
      if( timer_counter_value < r_64_data )
      begin
        return_state <= WAIT_RO_COUNT;
        state <= WAIT;
      end
      else
      begin
        ro_counter_send <= ro_counter_value;
        timer_counter_send <= timer_counter_value + select_sensor + 1;
        return_state <= SEND_RO_COUNT;
        state <= WAIT;
      end

    SEND_RO_COUNT: begin

      if (data_out_wr_ready & uart_wr_ready_prev)
      begin
        if (wr_ctr == 0)
        begin
          data_out_wr_en <= 1'b1;
          data_out <= ro_counter_send[63:56];
          ro_counter_send <= {ro_counter_send[55:0], 8'b00000000};
          wr_ctr <= wr_ctr + 1;
          return_state <= SEND_RO_COUNT;
          state <= WAIT;
        end
        else if (wr_ctr > 0 && wr_ctr < 8 )
        begin
          data_out_wr_en <= 1'b1;
          data_out <= ro_counter_send[63:56];
          ro_counter_send <= {ro_counter_send[55:0], 8'b00000000};
          wr_ctr <= wr_ctr + 1;
          return_state <= SEND_RO_COUNT;
          state <= WAIT;

        end
        else if (wr_ctr == 8)
        begin
          data_out_wr_en <= 1'b1;
          data_out <= timer_counter_send[63:56];
          timer_counter_send <= {timer_counter_send[55:0], 8'b00000000};
          wr_ctr <= wr_ctr + 1;
          return_state <= SEND_RO_COUNT;
          state <= WAIT;
        end
        else if (wr_ctr > 8 && wr_ctr < 16)
        begin
          data_out_wr_en <= 1'b1;
          data_out <= timer_counter_send[63:56];
          timer_counter_send <= {timer_counter_send[55:0], 8'b00000000};
          wr_ctr <= wr_ctr + 1;
          return_state <= SEND_RO_COUNT;
          state <= WAIT;
        end
        else // wr_ctr == 16
        begin
          wr_ctr <= 0;
          if(select_sensor < 7) begin //0,1,2,3,4,5,6
            select_sensor <= select_sensor + 1;
            ro_sensor_enable <= ro_sensor_enable << 1;
            return_state <= START_RO;
            state <= WAIT;
          end
          else begin // select sensor == 7, the last one.
            select_sensor <= 0;
            ro_sensor_enable <= ro_sensor_enable << 1;
            return_state <= IDLE;
            state <= WAIT;
          end
        end
      end
    end


    TURN_heater_ON:
      begin
        ro_heating_enable <= 1'b1;
        return_state <= IDLE;
        state <= WAIT;
      end
     
    TURN_heater_OFF:
      begin
        ro_heating_enable <= 1'b0;
        ro_counter_send <= ro_heating_counter_value;
        wr_ctr <= 0;
        return_state <= SEND_HEATER_COUNT;
        state <= WAIT;
      end

    SEND_HEATER_COUNT: begin
        if (data_out_wr_ready & uart_wr_ready_prev) begin
          if (wr_ctr < 8)
          begin
            data_out_wr_en <= 1'b1;
            data_out <= ro_counter_send[63:56];
            ro_counter_send <= {ro_counter_send[55:0], 8'b00000000};
            wr_ctr <= wr_ctr + 1;
            return_state <= SEND_HEATER_COUNT;
            state <= WAIT;
          end
          else begin
            wr_ctr <= 0;
            return_state <= IDLE;
            state <= WAIT;
          end
        end
      end

                
  endcase

end




//  Multiplexer. Selct the sensor to detect temperature.


wire ro_tick_selected; // ro_a_tick is to choose one from four ro_a_*_tick.


mux_N_1  #( // 8 to 1 MUX
  .NWAY (8)
)
mux_sensor (
  .select(select_sensor),
  .ro_in(ro_sensor_tick),
  .ro_selected(ro_tick_selected)
);


// RO counter

reg ro_and_timer_reset = 0;
wire [63:0] ro_counter_value;
wire [63:0] timer_counter_value;

counter ro_counter(
  .tick(ro_tick_selected),
  .reset(ro_and_timer_reset),
  .val(ro_counter_value)
);

counter timer_counter(
  .tick(clk),
  .reset(ro_and_timer_reset),
  .val(timer_counter_value)
);



// RO heating units


reg         ro_heating_enable = 0;
wire [63:0] ro_heating_counter_value;

Heater heater_inst (
    .ro_heating_enable (ro_heating_enable),
    .ro_heating_counter_value (ro_heating_counter_value)
);



// RO thermal sensors

reg[7:0] ro_sensor_enable = 0;
wire[7:0] ro_sensor_tick;
wire[7:0] ro_sensor_tick_prev;

ro #(
  .RO_LENGTH (3)
)
ro_sensor_0 (
  .enable(ro_sensor_enable[0]),
  .out(ro_sensor_tick[0]),
  .out_prev(ro_sensor_tick_prev[0])
);

ro #(
  .RO_LENGTH (3)
)
ro_sensor_1 (
  .enable(ro_sensor_enable[1]),
  .out(ro_sensor_tick[1]),
  .out_prev(ro_sensor_tick_prev[1])
);

ro #(
  .RO_LENGTH (3)
)
ro_sensor_2 (
  .enable(ro_sensor_enable[2]),
  .out(ro_sensor_tick[2]),
  .out_prev(ro_sensor_tick_prev[2])
);

ro #(
  .RO_LENGTH (3)
)
ro_sensor_3 (
  .enable(ro_sensor_enable[3]),
  .out(ro_sensor_tick[3]),
  .out_prev(ro_sensor_tick_prev[3])
);


ro #(
  .RO_LENGTH (3)
)
ro_sensor_4 (
  .enable(ro_sensor_enable[4]),
  .out(ro_sensor_tick[4]),
  .out_prev(ro_sensor_tick_prev[4])
);

ro #(
  .RO_LENGTH (3)
)
ro_sensor_5 (
  .enable(ro_sensor_enable[5]),
  .out(ro_sensor_tick[5]),
  .out_prev(ro_sensor_tick_prev[5])
);

ro #(
  .RO_LENGTH (3)
)
ro_sensor_6 (
  .enable(ro_sensor_enable[6]),
  .out(ro_sensor_tick[6]),
  .out_prev(ro_sensor_tick_prev[6])
);

ro #(
  .RO_LENGTH (3)
)
ro_sensor_7 (
  .enable(ro_sensor_enable[7]),
  .out(ro_sensor_tick[7]),
  .out_prev(ro_sensor_tick_prev[7])
);


endmodule
