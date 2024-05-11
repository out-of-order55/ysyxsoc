module gpio_top_apb(
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,
  input         in_penable,
  input  [2:0]  in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [3:0]  in_pstrb,
  output        in_pready ,
  output [31:0] in_prdata ,
  output        in_pslverr,

  output [15:0] gpio_out,
  input  [15:0] gpio_in,
  output [7:0]  gpio_seg_0,
  output [7:0]  gpio_seg_1,
  output [7:0]  gpio_seg_2,
  output [7:0]  gpio_seg_3,
  output [7:0]  gpio_seg_4,
  output [7:0]  gpio_seg_5,
  output [7:0]  gpio_seg_6,
  output [7:0]  gpio_seg_7
);
  wire  sel_led    = (in_paddr>=32'h10002000)&(in_paddr<32'h10002004);//w
  wire  sel_switch = (in_paddr>=32'h10002004)&(in_paddr<32'h10002008);//r
  wire  sel_seg    = (in_paddr>=32'h10002008)&(in_paddr<32'h1000200c);//w
  wire  seg01      = sel_seg&(in_pstrb[0]=='b1);
  wire  seg23      = sel_seg&(in_pstrb[1]=='b1);
  wire  seg45      = sel_seg&(in_pstrb[2]=='b1);
  wire  seg67      = sel_seg&(in_pstrb[3]=='b1);

  parameter   IDLE         = 2'b00,
              LED_WRITE    = 2'b01,
              SWITCH_READ  = 2'b11,
              SEG_WRITE    = 2'b10;
  reg[1:0]  state;
  always @(posedge clock) begin
    if(reset)begin
      state <= IDLE;
    end
    else begin
      case (state)
        IDLE:begin
          if(in_psel&sel_led&in_pwrite)begin
            state <= LED_WRITE;
          end
          else if(in_psel&sel_seg&in_pwrite)begin
            state <= SEG_WRITE;
          end
          else if(in_psel&sel_switch&(!in_pwrite))begin
            state <= SWITCH_READ;
          end
        end 
        LED_WRITE:begin
          state <= IDLE;
        end
        SEG_WRITE:begin
          state <= IDLE;
        end
        SWITCH_READ:begin
          state <= IDLE;
        end
        default: state <= IDLE;
      endcase
    end
  end
  reg[31:0]   gpio_o;
  reg[31:0]   seg_o;
  always @(posedge clock ) begin
    if(reset)begin
      gpio_o <= 'b0;
    end
    else if((state==LED_WRITE))begin
      gpio_o <= in_pwdata;
    end
  end
  always @(posedge clock) begin
    if(reset)begin
      seg_o <= 'b0;
    end
    else if(state==SEG_WRITE)begin
      seg_o <= in_pwdata;
    end
  end
  assign in_pready  = (state==SWITCH_READ)|(state==SEG_WRITE)|(state==LED_WRITE);
  assign in_prdata  = (state==SWITCH_READ)?{16'b0,gpio_in}:'b0;
  assign in_pslverr = 'b0;
  assign gpio_out   = gpio_o;
  assign gpio_seg_0 =       ((seg_o[3:0]==4'b0000)?(~8'b11111101)
                            :(seg_o[3:0]==4'b0001)?(~8'b01100000)
                            :(seg_o[3:0]==4'b0010)?(~8'b11011010)
                            :(seg_o[3:0]==4'b0011)?(~8'b11110010)
                            :(seg_o[3:0]==4'b0100)?(~8'b01100110)
                            :(seg_o[3:0]==4'b0101)?(~8'b10110110)
                            :(seg_o[3:0]==4'b0110)?(~8'b10111110)
                            :(seg_o[3:0]==4'b0111)?(~8'b11100000)
                            :'b0);
  assign gpio_seg_1 =       ((seg_o[7:4]==4'b0000)?(~8'b11111101)
                            :(seg_o[7:4]==4'b0001)?(~8'b01100000)
                            :(seg_o[7:4]==4'b0010)?(~8'b11011010)
                            :(seg_o[7:4]==4'b0011)?(~8'b11110010)
                            :(seg_o[7:4]==4'b0100)?(~8'b01100110)
                            :(seg_o[7:4]==4'b0101)?(~8'b10110110)
                            :(seg_o[7:4]==4'b0110)?(~8'b10111110)
                            :(seg_o[7:4]==4'b0111)?(~8'b11100000)
                            :'b0);
  assign gpio_seg_2 =       ((seg_o[11:8]==4'b0000)?(~8'b11111101)
                            :(seg_o[11:8]==4'b0001)?(~8'b01100000)
                            :(seg_o[11:8]==4'b0010)?(~8'b11011010)
                            :(seg_o[11:8]==4'b0011)?(~8'b11110010)
                            :(seg_o[11:8]==4'b0100)?(~8'b01100110)
                            :(seg_o[11:8]==4'b0101)?(~8'b10110110)
                            :(seg_o[11:8]==4'b0110)?(~8'b10111110)
                            :(seg_o[11:8]==4'b0111)?(~8'b11100000)
                            :'b0);
  assign gpio_seg_3 =       ((seg_o[15:12]==4'b0000)?(~8'b11111101)
                            :(seg_o[15:12]==4'b0001)?(~8'b01100000)
                            :(seg_o[15:12]==4'b0010)?(~8'b11011010)
                            :(seg_o[15:12]==4'b0011)?(~8'b11110010)
                            :(seg_o[15:12]==4'b0100)?(~8'b01100110)
                            :(seg_o[15:12]==4'b0101)?(~8'b10110110)
                            :(seg_o[15:12]==4'b0110)?(~8'b10111110)
                            :(seg_o[15:12]==4'b0111)?(~8'b11100000)
                            :'b0);
  assign gpio_seg_4 =       ((seg_o[19:16]==4'b0000)?(~8'b11111101)
                            :(seg_o[19:16]==4'b0001)?(~8'b01100000)
                            :(seg_o[19:16]==4'b0010)?(~8'b11011010)
                            :(seg_o[19:16]==4'b0011)?(~8'b11110010)
                            :(seg_o[19:16]==4'b0100)?(~8'b01100110)
                            :(seg_o[19:16]==4'b0101)?(~8'b10110110)
                            :(seg_o[19:16]==4'b0110)?(~8'b10111110)
                            :(seg_o[19:16]==4'b0111)?(~8'b11100000)
                            :'b0);
  assign gpio_seg_5 =       ((seg_o[23:20]==4'b0000)?(~8'b11111101)
                            :(seg_o[23:20]==4'b0001)?(~8'b01100000)
                            :(seg_o[23:20]==4'b0010)?(~8'b11011010)
                            :(seg_o[23:20]==4'b0011)?(~8'b11110010)
                            :(seg_o[23:20]==4'b0100)?(~8'b01100110)
                            :(seg_o[23:20]==4'b0101)?(~8'b10110110)
                            :(seg_o[23:20]==4'b0110)?(~8'b10111110)
                            :(seg_o[23:20]==4'b0111)?(~8'b11100000)
                            :'b0);
  assign gpio_seg_6 =       ((seg_o[27:24]==4'b0000)?(~8'b11111101)
                            :(seg_o[27:24]==4'b0001)?(~8'b01100000)
                            :(seg_o[27:24]==4'b0010)?(~8'b11011010)
                            :(seg_o[27:24]==4'b0011)?(~8'b11110010)
                            :(seg_o[27:24]==4'b0100)?(~8'b01100110)
                            :(seg_o[27:24]==4'b0101)?(~8'b10110110)
                            :(seg_o[27:24]==4'b0110)?(~8'b10111110)
                            :(seg_o[27:24]==4'b0111)?(~8'b11100000)
                            :'b0);
  assign gpio_seg_7 =       ((seg_o[31:28]==4'b0000)?(~8'b11111101)
                            :(seg_o[31:28]==4'b0001)?(~8'b01100000)
                            :(seg_o[31:28]==4'b0010)?(~8'b11011010)
                            :(seg_o[31:28]==4'b0011)?(~8'b11110010)
                            :(seg_o[31:28]==4'b0100)?(~8'b01100110)
                            :(seg_o[31:28]==4'b0101)?(~8'b10110110)
                            :(seg_o[31:28]==4'b0110)?(~8'b10111110)
                            :(seg_o[31:28]==4'b0111)?(~8'b11100000)
                            :'b0);
endmodule

