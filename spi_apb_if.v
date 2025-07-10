module spi_apb_if(P_clk,P_rst,P_addr,P_sel,P_enable,P_write,P_wdata,P_ready,P_slverr,P_rdata,ss,spi_interrupt_request,receive_data,miso_data,tip,send_data,mstr,cpol,cpha,lsbfe,spiswai,mosi_data,spi_mode,spr,sppr);
  //input configration 
  input P_clk;
  input P_rst;
  input [2:0]P_addr;
  input ss;
  input P_sel;
  input P_enable;
  input P_write;
  input [7:0]P_wdata;
  input receive_data;
  input [7:0]miso_data;
  input tip;

  
  //output configration
  output  P_ready;
  output   P_slverr;
  output  [7:0]P_rdata;
  output  spi_interrupt_request;
  output reg send_data;
  output mstr;
  output cpol;
  output cpha;
  output lsbfe;
  output spiswai;
  output reg [7:0]mosi_data;
  output reg [1:0]spi_mode;
  output  [2:0]spr;
  output  [2:0]sppr;


reg[7:0] SPI_CR1;
reg[7:0] SPI_CR2;
reg[7:0] SPI_SR;
reg[7:0] SPI_DR;
reg[7:0] SPI_BR;

wire sptef;
wire spif;
wire spe;
wire modfen;
wire modf;
wire ssoe;
wire wr_enb;
wire rd_enb;
wire spie;
wire sptie;

parameter cr2_mask =8'b0001_1011;
parameter br_mask = 8'b0111_0111;
//CR1
assign ssoe   = SPI_CR1[1];
assign mstr   = SPI_CR1[4];
assign spe    = SPI_CR1[6];
assign spie   = SPI_CR1[7];
assign sptie  = SPI_CR1[5];
assign cpol   = SPI_CR1[3];
assign cpha   = SPI_CR1[2];
assign lsbfe  = SPI_CR1[0];
//CR2
assign modfen = SPI_CR2[4];
assign spiswai= SPI_CR2[1];

//BR
assign sppr   = SPI_BR[6:4];
assign spr    = SPI_BR[2:0];





  
  //state declaration for APB states
  parameter [1:0] idle=2'b00;
  parameter [1:0] setup=2'b01;
  parameter [1:0] enable=2'b10;

 //state decleration for SPI modes 
  parameter [1:0] spi_run=2'b00;
  parameter [1:0] spi_wait=2'b01;
  parameter [1:0] spi_stop=2'b10;
  
  //state declaration of present and next (APB FSM)
  reg [1:0] present_state,next_state;
   //state declaration of next (SPI FSM)
  reg [1:0] next_mode;

  always @(posedge P_clk or negedge P_rst) 
  begin
    if(!P_rst) 
    begin
    present_state <= idle;
    spi_mode<=spi_run;
    end
    else
	begin
         present_state <= next_state;
	 spi_mode<=next_mode;
	end
  end
//APB FSM
  always @(*) 
begin
  next_state = present_state;
  case (present_state)
    idle:
    begin
      if (P_sel   && !P_enable) 	
      next_state = setup;
    end

    setup:
    begin 
          if(P_sel && !P_enable)
	    next_state =setup;
	else if(P_sel && P_enable)
	    next_state=enable;
	else
	begin
	next_state=idle;
	end

    end
    enable :
    begin
      if (P_sel)
       next_state = setup;
      else
	next_state=idle;
     end
    default: next_state= idle;
    endcase 
 end
//SPI FSM
always @(*) 
begin
  next_mode =spi_mode;
  case (spi_mode)
    spi_run:
    begin
      if (!spe) 	
      next_mode = spi_wait;
    end

    spi_wait:
    begin 
          if (spe) 
	  next_mode = spi_run; 
	  else if(spiswai)
	    next_mode=spi_stop;
	  else
	    next_mode=spi_wait;
    end
    spi_stop :
    begin
      if (!spiswai)
       next_mode = spi_wait;
      else if(spe)
	next_mode= spi_run;
     end
default: next_mode=spi_run;
    endcase 
 end


assign wr_enb = (P_write&&(present_state==enable));
assign rd_enb = (!P_write &&(present_state == enable));
assign P_ready = (present_state==enable)? 1'b1:1'b0;
assign P_slverr=(present_state==enable)?tip:1'b0;
assign sptef = (SPI_DR==8'b00)?1'b1:1'b0;
assign spif = (SPI_DR!=8'b00)?1'b1:1'b0;
assign modf=(mstr&modfen&(~ssoe)&(~ss));

//SR
always@(posedge P_clk or negedge P_rst)
begin
if(!P_rst)
SPI_SR <= 8'b00;
else
begin
SPI_SR <= {spif,1'b0,sptef,modf,4'b0};
end
end

//mosi_data
always@(posedge P_clk or negedge P_rst)
begin
if(!P_rst)
mosi_data <= 0;
else if (((SPI_DR == P_wdata) && SPI_DR != miso_data) && (spi_mode==spi_run || spi_mode==spi_wait) && ~wr_enb)
begin
mosi_data <= SPI_DR;
end
end

//SPI_CR1
always@(posedge P_clk or negedge P_rst)
begin
if(!P_rst)
SPI_CR1 <= 8'h04;
else
begin
	if ((wr_enb)&&(P_addr==3'b000))
	SPI_CR1<=P_wdata;
	//else if (!wr_enb)
	//SPI_CR1<=8'h00;
end
end

//SPI_CR2
always@(posedge P_clk or negedge P_rst)
begin
if(!P_rst)
SPI_CR2 <= 8'h00;
else
begin
	if ((wr_enb)&&(P_addr==3'b001))
	SPI_CR2<=(P_wdata&cr2_mask);
	//else if (!wr_enb)
	//SPI_CR2=8'h00;
end
end

//SPI_BR
always@(posedge P_clk or negedge P_rst)
begin
if(!P_rst)
SPI_BR <= 8'h00;
else
begin
	if ((wr_enb)&&(P_addr==3'b010))
	SPI_BR<=(P_wdata&br_mask);
	//else if (!wr_enb)
	//SPI_BR<=8'h00;
end
end

//spi_interrupt_request
assign spi_interrupt_request = ( !spie && !sptie )?0:( spie && !sptie )? (spif || modf ):( !spie && sptie )? sptef :(spif || sptef || modf );



//SPI_DR
always@(posedge P_clk or negedge P_rst)
begin
if(!P_rst)
SPI_DR <= 8'h00;
else
begin
	if ((wr_enb)&&(P_addr==3'b101))
	SPI_DR<=P_wdata;
	else if (!wr_enb)
	begin
		if((SPI_DR==P_wdata)&&(SPI_DR!=miso_data)&&( (spi_mode==spi_run)||(spi_mode==spi_wait) ))
			SPI_DR<=8'b0;
		else if(receive_data&& ( (spi_mode==spi_run)||(spi_mode==spi_wait) ))
			SPI_DR<= miso_data;
	end
end
end

//P_rdata
assign P_rdata=(!rd_enb)?8'b0:(P_addr==3'b000)?SPI_CR1:(P_addr==3'b001)?SPI_CR2:(P_addr==3'b010)?SPI_BR:(P_addr==3'b011)?SPI_SR:SPI_DR;

//send_data
always @(posedge P_clk or negedge P_rst )
 begin
	if (!P_rst)
	send_data<=1'b0;
	else if (!wr_enb )
	  begin 
	if (( (spi_mode==spi_run)||(spi_mode==spi_wait) ) &&(SPI_DR==P_wdata) &&(SPI_DR!=miso_data))
	send_data<=1'b1;
	else
	begin
	if (receive_data && ( (spi_mode==spi_run)||(spi_mode==spi_wait) ))
        send_data<=0;
        else
	send_data<=0;
end
end 
end




endmodule
