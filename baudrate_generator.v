module baudrate_generator(
    input P_clk,
    input P_rst,
    input ss,
    input [2:0] sppr,
    input [2:0] spr,
    input [1:0]spi_mode,
    input cpha,
    input cpol,
    input spiswai,
    output reg [11:0] baudratedivisor, 
    output reg sclk, 
    output reg flag_low, 
    output reg flag_high,
    output reg flags_low, 
    output reg flags_high 
);

reg [11:0] count;

wire w1, w2;
assign w1 = (~ss) & (~spiswai) & ((spi_mode == 2'b00) | (spi_mode == 2'b01));
xor g0(w2, cpol, cpha);

always @(*) begin
    baudratedivisor = (sppr + 1) * (1 << (spr + 1));// Generate baudrate divisor as per SPI specs: divisor = (SPPR+1) * 2^(SPR+1)

end

// count
always @(posedge P_clk or negedge P_rst) begin
    if (!P_rst)
        count <= 12'b0;
    else
        count <= w1 ? ((count == (baudratedivisor - 1)) ? 12'b0 : (count + 1)) : count;
end

// SCLK
always @(posedge P_clk or negedge P_rst) begin
    if (!P_rst) 
        sclk <= cpol; 
    else 
        sclk <= w1 ? ((count == (baudratedivisor - 1'b1)) ? ~sclk : sclk) : cpol; 
end

// flags_low 
always @(posedge P_clk or negedge P_rst) begin
    if (!P_rst) 
        flags_low <= 1'b0;
    else 
        flags_low <= ~w2 ? (sclk ? 1'b0 : ((count == (baudratedivisor - 2)) ? 1'b1 : 1'b0)) : flags_low; 
end

// flags_high
always @(posedge P_clk or negedge P_rst) begin
    if (!P_rst) 
        flags_high <= 1'b0;
    else 
        flags_high <= w2 ? ((~sclk) ? 1'b0 : ((count == (baudratedivisor - 2)) ? 1'b1 : 1'b0)) : flags_high; 
end

// flag_low 
always @(posedge P_clk or negedge P_rst) begin
    if (!P_rst) 
        flag_low <= 1'b0;
    else 
        flag_low <= ~w2 ? (sclk ? 1'b0 : ((count == (baudratedivisor - 1)) ? 1'b1 : 1'b0)) : flag_low; 
end

// flag_high
always @(posedge P_clk or negedge P_rst) begin
    if (!P_rst) 
        flag_high <= 1'b0;
    else 
        flag_high <= w2 ? ((~sclk) ? 1'b0 : ((count == (baudratedivisor - 1)) ? 1'b1 : 1'b0)) : flag_high; 
end

endmodule
