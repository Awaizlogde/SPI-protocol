`timescale 1ns/1ps

module tb_slave();

    parameter DATA_WIDTH = 8;
    
    // Simulate Master driving these wires
    reg SCLK;
    reg rst_n;
    reg SS;
    reg MOSI;
    
    // Slave data interface
    reg [DATA_WIDTH-1:0] tx_data;
    wire [DATA_WIDTH-1:0] rx_data;
    wire MISO;
    wire done;

    // Instantiate your Slave
    spi_slave #(
        .DATA_WIDTH(DATA_WIDTH),
        .CPOL(0),
        .CPHA(0)
    ) uut (
        .SCLK(SCLK),
        .rst_n(rst_n),
        .SS(SS),
        .MOSI(MOSI),
        .tx_data(tx_data),
        .MISO(MISO),
        .rx_data(rx_data),
        .done(done)
    );

    // Testbench variables
    reg [7:0] master_send_data = 8'b11001010; // 10100101
    reg [7:0] master_rec_data  = 8'h00;
    integer i;

    initial begin
        // Setup initial state
        SCLK = 0; rst_n = 0; SS = 1; MOSI = 0; 
        tx_data = 8'b11101010; // 00111100 (What the slave should send to us)
        
        $display("--- Starting Slave-Only Test ---");
        #20 rst_n = 1; #20;

        $display("Master sending: %h | Expecting Slave to send: %h", master_send_data, tx_data);
        
        // 1. Wake up the slave
        SS = 0; 
        #10; 

        // 2. Clock out 8 bits (Simulating a perfect Master in Mode 0)
        for (i = 7; i >= 0; i = i - 1) begin
            // Master puts data on MOSI
            MOSI = master_send_data[i];
            #10;
            
            // Master raises clock (Slave should sample MOSI now)
            SCLK = 1;
            // Master samples MISO from the Slave
            master_rec_data[i] = MISO;
            #10;
            
            // Master drops clock (Slave should shift next bit to MISO now)
            SCLK = 0;
        end

        #10;
        // 3. End transaction
        SS = 1; 
        #20;

        // Check the Results!
        $display("---------------------------------");
        $display("Slave Received: %b (Expected: 11001010)", rx_data);
        $display("Master Received (from MISO): %b (Expected: b11101010)", master_rec_data);
        
        if (rx_data  && master_rec_data)
            $display(">>> SLAVE IS PERFECT! <<<");
        else
            $display(">>> SLAVE FAILED! <<<");
        $display("---------------------------------");

        $finish;
    end
endmodule
