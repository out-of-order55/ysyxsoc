// define this macro to enable fast behavior simulation
// for flash by skipping SPI transfers
//`define FAST_FLASH

module spi_top_apb #(
  parameter flash_addr_start = 32'h30000000,
  parameter flash_addr_end   = 32'h3fffffff,
  parameter spi_ss_num       = 8
) (
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

  output                  spi_sck,
  output [spi_ss_num-1:0] spi_ss,
  output                  spi_mosi,
  input                   spi_miso,
  output                  spi_irq_out
);

`ifdef FAST_FLASH

wire [31:0] data;
parameter invalid_cmd = 8'h0;
flash_cmd flash_cmd_i(
  .clock(clock),
  .valid(in_psel && !in_penable),
  .cmd(in_pwrite ? invalid_cmd : 8'h03),
  .addr({8'b0, in_paddr[23:2], 2'b0}),
  .data(data)
);
assign spi_sck    = 1'b0;
assign spi_ss     = 8'b0;
assign spi_mosi   = 1'b1;
assign spi_irq_out= 1'b0;
assign in_pslverr = 1'b0;
assign in_pready  = in_penable && in_psel && !in_pwrite;
assign in_prdata  = data[31:0];

`else

  parameter   SPI_BASE     = 32'h10001000;
  wire        is_flash     = (in_paddr>=32'h30000000)&(in_paddr<=32'h3fffffff)&in_penable;
  wire        is_spi       = (in_paddr>=32'h10001000)&(in_paddr<=32'h10001fff)&in_penable;
  reg         wb_psel    ;
  reg         wb_penable ;   
  reg [2:0]   wb_pprot   ; 
  reg         wb_pwrite  ; 
  reg [31:0]  wb_pwdata  ; 
  reg [3:0]   wb_pstrb   ; 
  wire        wb_pready  ; 
  wire [31:0] wb_prdata  ; 
  wire        wb_pslverr ;
  reg [31:0]  wb_paddr   ; 
  //normal addr 0x10001000--0x10001fff;
  reg [31:0] mspi_paddr   ; 
  reg        mspi_psel    ;
  reg        mspi_penable ;   
  reg [2:0]  mspi_pprot   ; 
  reg        mspi_pwrite  ; 
  reg [31:0] mspi_pwdata  ; 
  reg [3:0]  mspi_pstrb   ; 
  
    //flash read
  //XIP addr
  reg  [31:0] flash_paddr   ; 
  //
  wire        flash_psel    ;
  wire        flash_penable ;   
  wire [2:0]  flash_pprot   ; 
  wire        flash_pwrite  ; 
  wire [31:0] flash_pwdata  ; 
  wire [3:0]  flash_pstrb   ; 
  wire        flash_pready  ; 
  wire [31:0] flash_prdata  ; 
  wire        flash_pslverr ;  
  reg[2:0]    state;
  parameter   IDLE        = 3'b000;
  parameter   XIP_WREG    = 2'b001;
  parameter   XIP_WAIT    = 3'b010;
  parameter   XIP_RETURN  = 3'b011;
  parameter   XIP_CLOSE   = 3'b100;

  always @(*) begin
    case (state)
      IDLE       :begin
        wb_paddr  = is_spi?mspi_paddr  :'b0;
        wb_psel   = is_spi?mspi_psel   :'b0; 
        wb_penable= is_spi?mspi_penable:'b0; 
        wb_pprot  = is_spi?mspi_pprot  :'b0; 
        wb_pwrite = is_spi?mspi_pwrite :'b0; 
        wb_pwdata = is_spi?mspi_pwdata :'b0; 
        wb_pstrb  = is_spi?mspi_pstrb  :'b0; 
      end
      XIP_WREG   :begin
        wb_paddr =({32{(wreg_cnt=='b0)}}&(SPI_BASE+32'h4)
                  |{32{(wreg_cnt=='d1)}}&(SPI_BASE+32'h14)
                  |{32{(wreg_cnt=='d2)}}&(SPI_BASE+32'h18)
                  |{32{(wreg_cnt=='d3)}}&(SPI_BASE+32'h10));
        wb_psel   = ((wreg_cnt=='b0)&(psel1)
                  |(wreg_cnt=='d1)&  (psel2)
                  |(wreg_cnt=='d2)&  (psel3)
                  |(wreg_cnt=='d3)&  (psel4)); 
        wb_penable= ((wreg_cnt=='b0)&(penable1)
                  |(wreg_cnt=='d1)  &(penable2)
                  |(wreg_cnt=='d2)  &(penable3)
                  |(wreg_cnt=='d3)  &(penable4));
        wb_pprot  = 'b1  ; 
        wb_pwrite = ((wreg_cnt=='b0)&(pwrite1)
                  |(wreg_cnt=='d1)&(pwrite2)
                  |(wreg_cnt=='d2)&(pwrite3)
                  |(wreg_cnt=='d3)&(pwrite4));
        wb_pwdata = ({32{(wreg_cnt=='b0)}}&({8'h03,flash_paddr[23:0]})
                  |{32{(wreg_cnt=='d1)}}&(32'h1)
                  |{32{(wreg_cnt=='d2)}}&(32'h1)
                  |{32{(wreg_cnt=='d3)}}&(32'h540));
        wb_pstrb  = 'hf; 
      end
      XIP_WAIT   :begin
        wb_paddr   = SPI_BASE+32'h10;
        wb_psel    = psel_wait;
        wb_penable = penable_wait;
        wb_pprot   = 'b1;
        wb_pwrite  = 'b0;
        wb_pwdata  = 'b0;
        wb_pstrb   = 'b0;
      end
      XIP_CLOSE:begin
        wb_paddr   = (SPI_BASE+32'h18);
        wb_psel    = psel_close;
        wb_penable = penable_close;
        wb_pprot   = 'b1;
        wb_pwrite  = 'b1;
        wb_pwdata  = 'b0;
        wb_pstrb   = 'h1;
      end
      XIP_RETURN :begin
        wb_paddr   = SPI_BASE;
        wb_psel    = psel_return;
        wb_penable = penable_return;
        wb_pprot   = 'b1;
        wb_pwrite  = 'b0;
        wb_pwdata  = 'b0;
        wb_pstrb   = 'b0;
      end
      default:begin
        wb_paddr  = is_spi?mspi_paddr  :'b0;
        wb_psel   = is_spi?mspi_psel   :'b0; 
        wb_penable= is_spi?mspi_penable:'b0; 
        wb_pprot  = is_spi?mspi_pprot  :'b0; 
        wb_pwrite = is_spi?mspi_pwrite :'b0; 
        wb_pwdata = is_spi?mspi_pwdata :'b0; 
        wb_pstrb  = is_spi?mspi_pstrb  :'b0; 
      end 
    endcase
  end
  

  //to sync signal
  always @(posedge clock or posedge reset) begin
    if(reset)begin
      mspi_paddr   <= 'b0;
      mspi_psel    <= 'b0;
      mspi_penable <= 'b0;
      mspi_pprot   <= 'b0;
      mspi_pwrite  <= 'b0;
      mspi_pwdata  <= 'b0;
      mspi_pstrb   <= 'b0;
    end
    else if(state==IDLE)begin
      mspi_paddr   <= in_paddr  ;
      mspi_psel    <= in_psel   ;
      mspi_penable <= in_penable;
      mspi_pprot   <= in_pprot  ;
      mspi_pwrite  <= in_pwrite ;
      mspi_pwdata  <= in_pwdata ;
      mspi_pstrb   <= in_pstrb  ;
    end
  end

  // to sync
  always @(posedge clock or posedge reset) begin
    if(reset)begin
      flash_paddr <='b0;
    end
    else if(is_flash)begin
      flash_paddr <= in_paddr;
    end
  end
  //fsm
  always @(posedge clock or posedge reset) begin
    if(reset)begin
      state <= IDLE;
    end
    else begin
      case (state)
          IDLE:begin
              if(is_spi)begin
                state <= state;
              end
              else if(is_flash)begin
                state <= XIP_WREG;
              end
              else begin
                state <= IDLE;
              end
          end
          XIP_WREG: begin
            if(wreg_cnt==3'd4)begin
              state <= XIP_WAIT;
            end
            else begin
              state <= state;
            end
          end
          XIP_WAIT:begin
            if((wb_prdata[8]=='b0)&&data_valid)begin
              state <= XIP_CLOSE;
            end
            else begin
              state <= state ;
            end
          end
          XIP_CLOSE:begin
            if(penable_close&psel_close&wb_pready&wb_pwrite)begin
              state <= XIP_RETURN;
            end
            else begin
              state <= state;
            end
          end
          XIP_RETURN:begin
            if(penable_return&psel_return&wb_pready)begin
              state <= IDLE;
            end
            else begin
              state <= state;
            end
          end
        default:state <= IDLE; 
      endcase
    end
  end

///////////////////////////pwrite , penable ,psel XIP_WREG////////////////////
  //XIP_WREG
  reg[2:0]  wreg_cnt;
  reg[31:0] reg1,reg2,reg3,reg4;
  reg       pwrite1,pwrite2,pwrite3,pwrite4;
  reg       penable1,penable2,penable3,penable4;
  reg       psel1,psel2,psel3,psel4;
  always @(posedge clock or posedge reset) begin
    if(reset)begin
      wreg_cnt<='b0;
    end
    else if(state==XIP_WREG)begin
      if(wb_pwrite&wb_psel&wb_penable&wb_pready)begin
        wreg_cnt <= wreg_cnt + 1;
      end
      else begin
        wreg_cnt <= wreg_cnt;
      end
    end
    else begin
      wreg_cnt <= 'b0;
    end
  end
  always @(posedge clock or posedge reset) begin
    if(reset)begin
      pwrite1  <= 'b0;
      penable1 <= 'b0;
      psel1    <= 'b0;
    end
    else if(pwrite1&psel1&penable1&wb_pready)begin
      pwrite1  <= 'b0;
      penable1 <= 'b0;
      psel1    <= 'b0;
    end
    else if((wreg_cnt=='b0)&&(state==XIP_WREG))begin
      pwrite1  <= 'b1;
      penable1 <= 'b1;
      psel1    <= 'b1;
    end

    else begin
      pwrite1  <= pwrite1;
      penable1 <= penable1;
      psel1    <= psel1;
    end
  end
  always @(posedge clock or posedge reset) begin
    if(reset)begin
      pwrite2  <= 'b0;
      penable2 <= 'b0;
      psel2    <= 'b0;
    end
    else if(pwrite2&psel2&penable2&wb_pready)begin
      pwrite2  <= 'b0;
      penable2 <= 'b0;
      psel2    <= 'b0;
    end
    else if((wreg_cnt=='d1)&&(state==XIP_WREG))begin
      pwrite2  <= 'b1;
      penable2 <= 'b1;
      psel2    <= 'b1;
    end

    else begin
      pwrite2  <= pwrite2;
      penable2 <= penable2;
      psel2    <= psel2;
    end
  end
  always @(posedge clock or posedge reset) begin
    if(reset)begin
      pwrite3  <= 'b0;
      penable3 <= 'b0;
      psel3    <= 'b0;
    end
    else if(pwrite3&psel3&penable3&wb_pready)begin
      pwrite3  <= 'b0;
      penable3 <= 'b0;
      psel3    <= 'b0;
    end
    else if((wreg_cnt=='d2)&&(state==XIP_WREG))begin
      pwrite3  <= 'b1;
      penable3 <= 'b1;
      psel3    <= 'b1;
    end

    else begin
      pwrite3  <= pwrite3;
      penable3 <= penable3;
      psel3    <= psel3;
    end
  end
  always @(posedge clock or posedge reset) begin
    if(reset)begin
      pwrite4  <= 'b0;
      penable4 <= 'b0;
      psel4    <= 'b0;
    end
    else if(pwrite4&psel4&penable4&wb_pready)begin
      pwrite4  <= 'b0;
      penable4 <= 'b0;
      psel4    <= 'b0;
    end
    else if((wreg_cnt=='d3)&&(state==XIP_WREG))begin
      pwrite4  <= 'b1;
      penable4 <= 'b1;
      psel4    <= 'b1;
    end
    else begin
      pwrite4  <= pwrite4;
      penable4 <= penable4;
      psel4    <= psel4;
    end
  end
////////////////////////////////////////////////////////////////
//////////////////////////pwrite,enable,sel ,XIP_WAIT - RETURN -CLOSE///////////////
  reg   penable_wait,penable_return,penable_close,psel_wait,psel_return,psel_close;
  reg   data_valid;
  always @(posedge clock or posedge reset) begin
    if(reset)begin
      penable_wait <= 'b0;
      psel_wait    <= 'b0;
      data_valid   <= 'b0;  
    end
    else if(penable_wait&psel_wait&wb_pready)begin
      penable_wait <= 'b0;
      psel_wait    <= 'b0;
      data_valid   <= 'b1; 
    end
    else if(state==XIP_WAIT)begin
      penable_wait <= 'b1;
      psel_wait    <= 'b1;
      data_valid   <= 'b0; 
    end
    else begin
      penable_wait <= penable_wait;
      psel_wait    <= psel_wait;
      data_valid   <= 'b0; 
    end

  end
  always @(posedge clock or posedge reset) begin
    if(reset)begin
      penable_return <= 'b0;
      psel_return    <= 'b0; 
    end
    else if(state==XIP_RETURN)begin
      penable_return <= 'b1;
      psel_return    <= 'b1; 
    end
    else if(penable_return&psel_return&wb_pready)begin
      penable_return <= 'b0;
      psel_return    <= 'b0; 
    end
  end
  always @(posedge clock or posedge reset) begin
    if(reset)begin
      penable_close <= 'b0;
      psel_close    <= 'b0; 
    end
    else if(penable_close&psel_close&wb_pwrite&wb_pready)begin
      penable_close <= 'b0;
      psel_close    <= 'b0; 
    end
    else if(state==XIP_CLOSE)begin
      penable_close <= 'b1;
      psel_close    <= 'b1; 
    end
  end
////////////////////////////////////////////////////////////////////////////
  reg[1:0]  state_r;
  wire[31:0] data_convert = (state==XIP_RETURN)?{wb_prdata[7:0],wb_prdata[15:8],wb_prdata[23:16],wb_prdata[31:24]}:wb_prdata;
  always @(posedge clock or posedge reset) begin
    if(reset)begin
      state_r <= 'b0;
    end
    else begin
      state_r <= state;
    end
  end
assign in_pready  = ((is_flash&(state==XIP_RETURN))
                  |(is_spi&(state==IDLE)))
                  &(wb_pready)
                  ;
assign in_prdata  = ((state_r==IDLE)|(state_r==XIP_RETURN))?data_convert:'b0;
assign in_pslverr = 'b0;
spi_top u0_spi_top (
  .wb_clk_i(clock),
  .wb_rst_i(reset),
  .wb_adr_i(wb_paddr[4:0] ),
  .wb_dat_i(wb_pwdata     ),
  .wb_dat_o(wb_prdata     ),
  .wb_sel_i(wb_pstrb      ),
  .wb_we_i (wb_pwrite     ),
  .wb_stb_i(wb_psel       ),
  .wb_cyc_i(wb_penable    ),
  .wb_ack_o(wb_pready     ),
  .wb_err_o(wb_pslverr    ),
  .wb_int_o(spi_irq_out   ),

  .ss_pad_o(spi_ss),
  .sclk_pad_o(spi_sck),
  .mosi_pad_o(spi_mosi),
  .miso_pad_i(spi_miso)
);

`endif // FAST_FLASH

endmodule
