import "DPI-C" function void sdram_model1(input int  wen,input int  ren,input int wdata,input int  bank,input int column,input int row,input int  mask,output int rdata);
import "DPI-C" function void sdram_model2(input int  wen,input int  ren,input int wdata,input int  bank,input int column,input int row,input int  mask,output int rdata);
import "DPI-C" function void sdram_model3(input int  wen,input int  ren,input int wdata,input int  bank,input int column,input int row,input int  mask,output int rdata);
import "DPI-C" function void sdram_model4(input int  wen,input int  ren,input int wdata,input int  bank,input int column,input int row,input int  mask,output int rdata);
module sdram(
  input        clk,
  input[1:0]   sel,
  input        selword,
  input        cke,
  input        cs ,
  input        ras,
  input        cas,
  input        we ,
  input [12:0] a  ,
  input [ 1:0] ba ,
  input [ 1:0] dqm,
  inout [15:0] dq
);
  wire[3:0]  CMD_NOP   = 4'b0111;
  wire[3:0]  CMD_ACT   = 4'b0011;
  wire[3:0]  CMD_READ  = 4'b0101;
  wire[3:0]  CMD_WRITE = 4'b0100;
  wire[3:0]  CMD_BT    = 4'b0110;
  wire[3:0]  CMD_PRE_C = 4'b0010;
  wire[3:0]  CMD_REF   = 4'b0001;
  wire[3:0]  CMD_LOAD  = 4'b0000;
  wire[3:0]  i_cmd = {cs,ras,cas,we};  
  wire[1:0]  cas_delay;
  wire[2:0]  burst_length;
  wire[31:0] rdata;
  wire[15:0] wdata;
  wire        ren;
  wire        wen;
  reg[3:0]    bank_open;
  reg[12:0]    row_addr[3:0];
  integer i;
  always @(posedge clk) begin
    if(!cke)begin
      bank_open <= 'b0;
      for(i=0;i<4;i++)begin
        row_addr[i] <= 'b0;
      end
    end
    else if(i_cmd==CMD_ACT)begin
      bank_open[ba] <= 'b1;
      row_addr[ba]  <= a;
    end
    else if(i_cmd==CMD_PRE_C)begin
      bank_open[ba] <= 'b0;
      row_addr[ba]  <= 'b0;
    end
  end
  /* verilator lint_off UNSIGNED */
  assign      ren = state==READ_WAIT;
  assign      wen = state==WRITE;
  parameter IDLE   = 3'b000,
            ACTIVE = 3'b001,
            READ   = 3'b010,
            WRITE  = 3'b011,
            MODE   = 3'b100,
            READ_WAIT = 3'b101;
  reg[2:0]   state;
  reg[11:0]  mode;//read->read_wait->idle
  always @(posedge clk) begin
    if(!cke)begin
      state <= IDLE;
    end
    else begin
      case (state)
        IDLE:begin
          if(i_cmd==CMD_ACT)begin
            state <= ACTIVE;
          end
          else if(i_cmd==CMD_LOAD)begin
            state <= MODE;
          end
          else if(i_cmd==CMD_READ)begin//no precharge
            state <= READ;
          end
          else if(i_cmd==CMD_WRITE)begin//no precharge
            state <= WRITE;
          end
        end
        ACTIVE:begin
          if(i_cmd==CMD_READ)begin
            state <= READ;
          end
          else if(i_cmd==CMD_WRITE)begin
            state <= WRITE;
          end
        end
        READ:begin
          if(i_cmd==CMD_NOP)begin
            state <= READ_WAIT;
          end
          else begin
            state <= IDLE;
          end
        end
        READ_WAIT:begin
          if(i_cmd==CMD_READ)begin
            state <= READ;
          end
          else begin
            state <= IDLE;
          end
        end
        WRITE:begin
          state <= IDLE;//NO BURST
        end
        MODE:begin
          state <= IDLE;
        end
        default: state <= IDLE;
      endcase
    end
  end

  always @(posedge clk) begin
    if(!cke)begin
      mode <= 'b0;
    end
    else if(i_cmd==CMD_LOAD)begin
      mode <= a;
    end
  end
  assign cas_delay    = mode[5:4];
  assign burst_length = mode[2:0];  


  reg[9:0]   column;
  reg[1:0]   bank;
  reg[1:0]   mask;


  always @(posedge clk) begin
    if(!cke)begin
      mask <= 'b0;
    end
    else if(state==WRITE||i_cmd==CMD_WRITE)begin
      mask <= dqm;
    end
    else if(state==IDLE)begin
      mask <= 'b0;
    end
  end
  
  always @(posedge clk) begin
    if(!cke)begin
      column <= 'b0;
      bank   <= 'b0;
    end
    else if((state==ACTIVE|state==IDLE)&(i_cmd==CMD_WRITE|i_cmd==CMD_READ)||(state==READ_WAIT&&i_cmd==CMD_READ))begin
      column <= a;
      bank   <= ba ;
    end
    else if(state==IDLE)begin
      column <= 'b0;
      bank   <= 'b0;
    end
  end

  wire[9:0]   sdram_column = column;
  wire[12:0]  sdram_row  = row_addr[sdram_bank];
  wire[1:0]   sdram_bank = bank;
  wire[1:0]   sdram_mask = wen?mask:'b0;
  assign  dq = ren?rdata[15:0]:'bz;
////////////////////////////////////////////
  reg[15:0]  sdram_wdata;

  //to handle loop
  always @(posedge clk) begin
    sdram_wdata <= dq;
  end

  always @(*) begin
    if(sel==2'b01)begin
      if(~selword)begin
        sdram_model1(wen,ren,sdram_wdata,sdram_bank,sdram_column,sdram_row,sdram_mask,rdata);
      end
      else begin
        sdram_model3(wen,ren,sdram_wdata,sdram_bank,sdram_column,sdram_row,sdram_mask,rdata);
      end
    end
    else if(sel==2'b10)begin
      if(~selword)begin
        sdram_model2(wen,ren,sdram_wdata,sdram_bank,sdram_column,sdram_row,sdram_mask,rdata);
      end
      else begin
        sdram_model4(wen,ren,sdram_wdata,sdram_bank,sdram_column,sdram_row,sdram_mask,rdata);
      end
    end
  end
endmodule
