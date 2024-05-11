import "DPI-C" function void psram(input int addr,input int wen,input int ren,input int wdata,input int size,output int rdata);
module psram(
  input sck,
  input ce_n,
  inout [3:0] dio
);

  //assign dio = 4'bz;
  reg qpi_mode;
  always @(posedge sck ) begin
    if((cmd==8'h1a)&(dio[0]))begin
      qpi_mode <= 'b1;
    end
  end

  reg[4:0]  cnt;
  always @(posedge sck or posedge ce_n) begin
    if(ce_n)begin
      cnt <= 'b0;
    end
    else if(~ce_n)begin
      cnt <= cnt +1;
    end
  end
  reg[7:0]    cmd;
  always @(posedge sck or posedge ce_n) begin
    if(ce_n)begin
      cmd <= 'b0;
    end
    else if(qpi_mode)begin
      if(cnt>'d1)begin
        cmd <= cmd;
      end
      else begin
        cmd <= {cmd[3:0],dio};
      end
    end
    else begin
      if(cnt>'d7)begin
        cmd<=cmd;
      end
      else begin
        cmd <= {cmd[6:0],dio[0]};
      end
    end
  end
  wire[31:0]  rdata;
  reg[31:0]   addr_temp;
  reg[31:0]   wdata;
  reg[3:0]   rdata_temp;
  always @(posedge sck or posedge ce_n) begin
    if(ce_n)begin
      addr_temp  <= 'b0;
    end
    else if(cnt=='d7)begin
      addr_temp  <= addr;
    end
  end
  wire  ren = cmd==8'heb; 
  wire  wen = (cmd==8'h38)&((cnt=='d16)?'b1
                            :(cnt=='d12)?'b1
                            :(cnt=='d10)?'b1
                            :'b0);
  wire[3:0] size = {4{(cmd==8'h38)}}&((cnt=='d16)?'b1111
                            :(cnt=='d12)?'b0011
                            :(cnt=='d10)?'b0001
                            :'b0);
  reg[23:0]  addr;
  always @(*) begin
    case(cnt)
      'd2: addr[23:20] = dio; 
      'd3: addr[19:16] = dio;
      'd4: addr[15:12] = dio;
      'd5: addr[11:8]  = dio;
      'd6: addr[7:4]   = dio;
      'd7: addr[3:0]   = dio;
      default:addr = 'b0;
    endcase
  end
  always @(posedge sck  or posedge ce_n) begin
    case (cnt)
      'd8:wdata[7:4]   <= dio;
      'd9:wdata[3:0]   <= dio;
      'd10:wdata[15:12] <= dio;
      'd11:wdata[11:8]  <= dio;
      'd12:wdata[23:20] <= dio;
      'd13:wdata[19:16] <= dio;
      'd14:wdata[31:28] <= dio;
      'd15:wdata[27:24] <= dio;
      default:wdata     <= 'b0;  
    endcase
  end
  always @(posedge sck  or posedge ce_n) begin
    case (cnt)
      'd14:rdata_temp        <= rdata[7:4];
      'd15:rdata_temp        <= rdata[3:0];
      'd16:rdata_temp        <= rdata[15:12];
      'd17:rdata_temp        <= rdata[11:8];
      'd18:rdata_temp        <= rdata[23:20];
      'd19:rdata_temp        <= rdata[19:16] ;
      'd20:rdata_temp        <= rdata[31:28]  ;
      'd21:rdata_temp        <= rdata[27:24]  ;
      default:rdata_temp     <= 'b0;  
    endcase
  end
  always @(*) begin
    psram(addr_temp,wen,ren,wdata,size,rdata);
  end
  assign  dio = (ren&(cnt>='d14))?rdata_temp:'bzzzz;
endmodule
