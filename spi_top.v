`include "baudrate_generator.v"
`include "spi_apb_if.v"
`include "shift_reg.v"
`include "spi_slave_control.v"
module spi_top(
input P_clk,
input P_rst,
input P_write,
input P_sel,
input P_enable,
input miso,
input [2:0] P_addr,
input [7:0] P_wdata,

output [7:0] P_rdata,
output P_ready,
output P_slverr,
output sclk,
output ss,
output mosi,
output spi_interrupt_request
);

wire tip;
wire [1:0] spi_mode;
wire spiswai,cpol,cpha,flag_high,flag_low,flags_high,flags_low,send_data,lsbfe,receive_data,mstr;
wire [11:0]baudratedivisor;
wire[7:0]data_mosi,data_miso;
wire[2:0]spr,sppr;

baudrate_generator BAUDRATE_GENERATOR(
    .P_clk(P_clk),
    .P_rst(P_rst),
    .ss(ss),
    .sppr(sppr),
    .spr(spr),
    .spi_mode(spi_mode),
    .cpha(cpha),
    .cpol(cpol),
    .spiswai(spiswai),
    .baudratedivisor(baudratedivisor),
    .sclk(sclk),
    .flag_low(flag_low),
    .flag_high(flag_high),
    .flags_low(flags_low),
    .flags_high(flags_high));
spi_apb_if SPI_APB_IF(
    .P_clk(P_clk),
    .P_rst(P_rst),
    .P_addr(P_addr),
    .P_sel(P_sel),
    .P_enable(P_enable),
    .P_write(P_write),
    .P_wdata(P_wdata),
    .P_ready(P_ready),
    .P_slverr(P_slverr),
    .P_rdata(P_rdata),
    .ss(ss),
    .spi_interrupt_request(spi_interrupt_request),
    .receive_data(receive_data),
    .miso_data(data_miso),
    .tip(tip),
    .send_data(send_data),
    .mstr(mstr),
    .cpol(cpol),
    .cpha(cpha),
    .lsbfe(lsbfe),
    .spiswai(spiswai),
    .mosi_data(data_mosi),
    .spi_mode(spi_mode),
    .spr(spr),
    .sppr(sppr));

spi_slave_control SPI_SLAVE_CONTROL(
    .P_clk(P_clk),
    .P_rst(P_rst),
    .mstr(mstr),
    .spiswai(spiswai),
    .spi_mode(spi_mode),
    .send_data(send_data),
    .baudratedivisor(baudratedivisor),
    .tip(tip),
    .receive_data(receive_data),
    .ss(ss));

shift_reg SHIFT_REG(
        .PCLK(P_clk), 
        .PRESETn(P_rst), 
        .ss(ss), 
        .send_data(send_data), 
        .receive_data(receive_data), 
        .lsbfe(lsbfe), 
        .cpha(cpha), 
        .cpol(cpol), 
        .flag_low(flag_low), 
        .flag_high(flag_high), 
        .flags_low(flags_low), 
        .flags_high(flags_high), 
        .data_mosi(data_mosi), 
        .miso(miso), 
        .mosi(mosi), 
        .data_miso(data_miso));
endmodule
