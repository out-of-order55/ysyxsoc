module ps2_top_apb(
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,
  input         in_penable,
  input  [2:0]  in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [3:0]  in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr,

  input         ps2_clk,
  input         ps2_data
);
  wire      kbd_en;
  wire[7:0] data;
  wire      ready;
  wire      nextdata_n;
  wire      sampling;
  wire      overflow;
  wire[7:0] data_o;
  wire      data_ready;
  reg       pready;
ysyx_23060024_ps2_keyboard u_ps2_keyboard(
    .clk        (    clock          ),
    .clrn       (    ~reset         ),
    .ps2_clk    (    ps2_clk        ),
    .ps2_data   (    ps2_data       ),
    .data       (    data           ),
    .ready      (    ready          ),
    .nextdata_n (    nextdata_n     ),
    .sampling   (    sampling       ),
    .overflow   (    overflow       )
);
  reg[7:0]    kbd_data;
  reg         kbd_en_r;
  reg         has_data;
  reg         next_n;
  always @(posedge clock) begin
    if(reset)begin
      next_n <= 'b1;
    end
    else if(in_pready)begin
      next_n <= 'b0;
    end
    else begin
      next_n <= 'b1;
    end
  end
  always @(posedge clock) begin
      if(reset)begin
        has_data <= 'b0;
      end
      else if(kbd_en)begin
        has_data <= 'b0;
      end
      else if(ready)begin
        has_data <= 'b1;
      end
  end
  always @(posedge clock) begin
      if(reset)begin
          kbd_data <= 'b0;
          pready   <= 'b0;
      end
      else if(in_pready&in_psel&in_penable)begin
          kbd_data <= 'b0;
          pready   <= 'b0;
      end
      else if(in_psel&in_penable&(!in_pwrite))begin
        if(ready)begin
          kbd_data <= data;
          pready   <= 'b1;
        end
        else begin
          kbd_data <= 'b0;
          pready   <= 'b1;
        end
      end

  end
  // always @(*) begin
  //   if(data==8'hf0)
  //   $write("CODE`%x`\n",data);
  // end
  assign in_pready  = pready;
  assign in_prdata  = kbd_data;
  assign in_pslverr = 'b0;
  assign nextdata_n = next_n;
endmodule
