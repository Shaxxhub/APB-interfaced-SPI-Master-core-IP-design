module spi_slave_control (
    input  P_clk,                  // System clock
    input  P_rst,                  // Active-low reset
    input  mstr,                   // Master mode enable
    input  spiswai,                // SPI software wait inhibit
    input  [1:0] spi_mode,         // SPI mode (CPOL, CPHA)
    input  send_data,              // Start data transmission
    input  [11:0] baudratedivisor, // Baud rate divisor

    output reg receive_data,       // Pulse when a byte is received
    output reg ss,                 // Slave Select (active low)
    output tip                     // Transfer In Progress
);

    reg rcv;
    reg [15:0] count;
    wire [15:0] target;

    // Compute target value = baudratedivisor * 16
    assign target = baudratedivisor << 4;

    // SPI enabled condition: master mode, SPI mode 0 or 1, and not in wait state
    wire w1 = mstr & ((spi_mode == 2'b00) || (spi_mode == 2'b01)) & (~spiswai);

    // -------------------------------
    // Receive Data Output Logic
    // -------------------------------
    always @(posedge P_clk or negedge P_rst) begin
        if (!P_rst)
            receive_data <= 1'b0;
        else
            receive_data <= rcv;
    end

    // -------------------------------
    // RCV Internal Signal Logic
    // -------------------------------
    always @(posedge P_clk or negedge P_rst) begin
        if (!P_rst)
            rcv <= 1'b0;
        else if (w1) begin
            if (send_data)
                rcv <= 1'b0;
            else if (count <= target - 1) begin
                if (count == target - 1)
                    rcv <= 1'b1;
                else
                    rcv <= 1'b0;
            end else
                rcv <= 1'b0;
        end else
            rcv <= 1'b0;
    end

    // -------------------------------
    // Slave Select (SS) Control
    // -------------------------------
    always @(posedge P_clk or negedge P_rst) begin
        if (!P_rst)
            ss <= 1'b1;
        else if (w1) begin
            if (send_data || (count <= target - 1))
                ss <= 1'b0;  // Assert SS (active low)
            else
                ss <= 1'b1;  // Deassert SS (inactive)
        end else
            ss <= 1'b1;
    end

    // -------------------------------
    // Transfer In Progress (TIP)
    // -------------------------------
    assign tip = ~ss;

    // -------------------------------
    // Count Logic
    // -------------------------------
    always @(posedge P_clk or negedge P_rst) begin
        if (!P_rst)
            count <= 16'hFFFF;
        else if (w1) begin
            if (send_data)
                count <= 16'b0;
            else if (count <= target - 1)
                count <= count + 1'b1;
            else
                count <= 16'hFFFF;
        end else
            count <= 16'hFFFF;
    end

endmodule

