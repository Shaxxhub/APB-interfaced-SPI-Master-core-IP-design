module shift_reg (
    input         PCLK,
    input         PRESETn,
    input         ss,
    input         send_data,
    input         receive_data,
    input         lsbfe,
    input         cpha,
    input         cpol,
    input         flag_low,
    input         flag_high,
    input         flags_low,
    input         flags_high,
    input  [7:0]  data_mosi,
    input         miso,

    output reg    mosi,
    output [7:0] data_miso
);

reg [2:0]count;
reg [2:0]count1;
reg [2:0]count2;
reg [2:0]count3;


reg [7:0] shift_register;
reg [7:0] temp_reg;


wire w1;

xor xor1(w1,cpha,cpol);

assign data_miso = receive_data ? (temp_reg):(8'h00);

//shift register 

always@(posedge PCLK or negedge PRESETn) begin 

if(!PRESETn) 
	shift_register <= 8'b0;
else 
	shift_register <= send_data ? (data_mosi):(shift_register);
end 

//mosi serial data transmisson 

always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        mosi <= 1'b0;
    end else begin
        if (!ss) begin
            if (lsbfe) begin
                // LSB-first
                if (count <= 3'd7) begin
                    if (w1) begin
                        if (flags_high)
                            mosi <= shift_register[count];
                    end else begin
                        if (flags_low)
                            mosi <= shift_register[count];
                    end
                end
            end else begin
                // MSB-first
                if (count1 >= 3'd0) begin
                    if (w1) begin
                        if (flags_high)
                            mosi <= shift_register[count1];
                    end else begin
                        if (flags_low)
                            mosi <= shift_register[count1];
                    end
                end
            end
        end else begin
            // Slave deselected ? idle mosi
            mosi <= 1'b0;
        end
    end
end



//count,count1 logic
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        count  <= 3'b000;
        count1 <= 3'b111;
    end else begin
        if (!ss) begin
            if (lsbfe) begin
                // LSB-first shifting
                if (w1) begin
                    if (flags_high) begin
                        count <= (count <= 3'd7) ? (count + 1'b1) : 3'd0;
                    end
                end else begin
                    if (flags_low) begin
                        count <= (count <= 3'd7) ? (count + 1'b1) : 3'd0;
                    end
                end
            end else begin
                // MSB-first shifting
                if (w1) begin
                    if (flags_high) begin
                        count1 <= (count1 > 3'd0) ? (count1 - 1'b1) : 3'd7;
                    end
                end else begin
                    if (flags_low) begin
                        count1 <= (count1 > 3'd0) ? (count1 - 1'b1) : 3'd7;
                    end
                end
            end
        end else begin
            // ss deasserted ? reset counters
            count  <= 3'b000;
            count1 <= 3'b111;
        end
    end
end


always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        count2 <= 3'b000;
        count3 <= 3'b111;
    end else begin
        if (!ss) begin
            if (lsbfe) begin
                // LSB-first shifting
                if (w1) begin
                    if (flag_high) begin
                        count2 <= (count2 <= 3'd7) ? (count2 + 1'b1) : 3'd0;
                    end
                end else begin
                    if (flag_low) begin
                        count2 <= (count2 <= 3'd7) ? (count2 + 1'b1) : 3'd0;
                    end
                end
            end else begin
                // MSB-first shifting
                if (w1) begin
                    if (flag_high) begin
                        count3 <= (count3 > 3'd0) ? (count3 - 1'b1) : 3'd7;
                    end
                end else begin
                    if (flag_low) begin
                        count3 <= (count3 > 3'd0) ? (count3 - 1'b1) : 3'd7;
                    end
                end
            end
        end else begin
            // ss deasserted ? reset counters
            count2 <= 3'b000;
            count3 <= 3'b111;
        end
    end
end

// logic to update the temp_register
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        temp_reg <= 8'b0;
    end else begin
        if (!ss) begin
            // Sampling condition based on CPHA and CPOL
            if ((flag_high || flag_low)) begin
                if (lsbfe) begin
                    // LSB-first data sampling
                    if (flag_high && (count2 <= 3'd7))
                        temp_reg[count2] <= miso;
                    else if (flag_low && (count2 <= 3'd7))
                        temp_reg[count2] <= miso;
                end else begin
                    // MSB-first data sampling
                    if (flag_high && (count3 >= 3'd0))
                        temp_reg[count3] <= miso;
                    else if (flag_low && (count3 >= 3'd0))
                        temp_reg[count3] <= miso;
                end
            end
        end
    end
end







endmodule
