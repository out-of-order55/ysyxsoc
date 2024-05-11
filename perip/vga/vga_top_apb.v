module vga_top_apb(
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

  output [7:0]  vga_r,
  output [7:0]  vga_g,
  output [7:0]  vga_b,
  output        vga_hsync,
  output        vga_vsync,
  output        vga_valid
);
wire[31:0]  vga_data;
reg         pready;
wire [9:0] h_addr;
wire [9:0] v_addr;
reg[31:0]   frame_buffer[524287];

always @(posedge clock) begin
  if(in_psel&&in_penable&&in_pwrite)begin
    frame_buffer[in_paddr[23:2]] <=  in_pwdata;
  end
end
always @(posedge clock) begin
  if(reset)begin
    pready <= 'b0;
  end
  else if(in_psel&&in_penable&&in_pwrite&in_pready)begin
    pready <= 'b0;
  end
  else if(in_psel&&in_penable&&in_pwrite)begin
    pready <= 'b1;
  end
end
assign in_pready  = pready;

assign vga_data = frame_buffer[v_addr*640+h_addr];
//wr_ctrl
vga_ctrl my_vga_ctrl(
    .pclk(clock),
    .reset(reset),
    .h_addr(h_addr),
    .v_addr(v_addr),
    .vga_data(vga_data[23:0]),
    .hsync(vga_hsync),
    .vsync(vga_vsync),
    .valid(vga_valid),
    .vga_r(vga_r),
    .vga_g(vga_g),
    .vga_b(vga_b)
);

endmodule
