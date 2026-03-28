`timescale 1ns/1ps

module tb_top_spi_();

    parameter DATA_WIDTH = 8;
    
    // System Clock & Reset
    reg clk;
    reg rst_n;
    
    // Master Control
    reg start;
    reg [1:0] slave_sel;
    reg [DATA_WIDTH-1:0] master_tx;
    wire [DATA_WIDTH-1:0] master_rx;
    wire master_done;
    
    // The SPI Bus (Shared across all devices)
    wire SCLK;
    wire MOSI;
    wire MISO;     // All 4 slaves will connect to this single wire!
    wire [3:0] SS; // Individual Chip Selects
    
    // Slave TX Data Registers
    reg [DATA_WIDTH-1:0] slv0_tx, slv1_tx, slv2_tx, slv3_tx;
    
    // Slave RX Data Wires
    wire [DATA_WIDTH-1:0] slv0_rx, slv1_rx, slv2_rx, slv3_rx;
    
    // -----------------------------------------------------------
    // 1. Instantiate The Processor (Master)
    // -----------------------------------------------------------
    spi_master #(.DATA_WIDTH(DATA_WIDTH), .SLAVES(4), .CLK_DIV(4), .CPOL(0), .CPHA(0)) 
    processor_core (
        .clk(clk), .rst_n(rst_n),
        .mosi_data_reg(master_tx), .miso_data_reg(master_rx),
        .MISO(MISO), .MOSI(MOSI), .SCLK(SCLK), .SS(SS),
        .start(start), .slave_sel(slave_sel), .done(master_done)
    );

    // -----------------------------------------------------------
    // 2. Instantiate The Peripherals (4 Slaves)
    // -----------------------------------------------------------
    // Slave 0: Temperature Sensor
    spi_slave #(.DATA_WIDTH(DATA_WIDTH), .CPOL(0), .CPHA(0)) temp_sensor (
        .SCLK(SCLK), .rst_n(rst_n), .SS(SS[0]), .MOSI(MOSI),
        .tx_data(slv0_tx), .MISO(MISO), .rx_data(slv0_rx)
    );

    // Slave 1: Fan Throttle Controller
    spi_slave #(.DATA_WIDTH(DATA_WIDTH), .CPOL(0), .CPHA(0)) fan_throttle (
        .SCLK(SCLK), .rst_n(rst_n), .SS(SS[1]), .MOSI(MOSI),
        .tx_data(slv1_tx), .MISO(MISO), .rx_data(slv1_rx)
    );

    // Slave 2: OLED Display Driver
    spi_slave #(.DATA_WIDTH(DATA_WIDTH), .CPOL(0), .CPHA(0)) display_driver (
        .SCLK(SCLK), .rst_n(rst_n), .SS(SS[2]), .MOSI(MOSI),
        .tx_data(slv2_tx), .MISO(MISO), .rx_data(slv2_rx)
    );

    // Slave 3: System Memory (EEPROM)
    spi_slave #(.DATA_WIDTH(DATA_WIDTH), .CPOL(0), .CPHA(0)) system_memory (
        .SCLK(SCLK), .rst_n(rst_n), .SS(SS[3]), .MOSI(MOSI),
        .tx_data(slv3_tx), .MISO(MISO), .rx_data(slv3_rx)
    );

    // Generate 100MHz System Clock
    always #5 clk = ~clk; 

    // Test sequence variables
    integer i;
    integer errors = 0;
    reg [7:0] expected_slave_tx;

    initial begin
        // Initialize
        clk = 0; rst_n = 0; start = 0; slave_sel = 0;
        master_tx = 0; 
        slv0_tx = 8'b11001100; slv1_tx = 8'b10101010; slv2_tx = 8'b11100010; slv3_tx = 8'b00110011;
        
        $display("===========================================");
        $display("   STARTING 4-SLAVE INTEGRATION TEST   ");
        $display("===========================================");
        
        #20 rst_n = 1; #20;

        // Loop through all 4 slaves one by one
        for (i = 0; i < 4; i = i + 1) begin
            
            slave_sel = i;
            master_tx = $random % 256; // Give the master something new to say
            
            // Determine which slave data we EXPECT to get back
            if (i == 0) expected_slave_tx = slv0_tx;
            if (i == 1) expected_slave_tx = slv1_tx;
            if (i == 2) expected_slave_tx = slv2_tx;
            if (i == 3) expected_slave_tx = slv3_tx;

            $display("\n--- Selecting slave %0d ---", i);
            $display("Master sending: %b | Expecting back: %b", master_tx, expected_slave_tx);

            // Fire the transaction
            start = 1;
            #10 start = 0;

            // Wait for it to finish
            wait(master_done == 1'b1);
            #20; 

            // Verify the Master received the correct data from the targeted slave
            if (master_rx !== expected_slave_tx) begin
                $display("? COLLISION OR FAILURE! Master received %b instead of %b", master_rx, expected_slave_tx);
                errors = errors + 1;
            end else begin
                $display("? SUCCESS! Master safely received %h from SLAVE %0d", master_rx, i);
            end
            
            // Verify the targeted Slave actually received the Master's message
            if (i == 0 && slv0_rx !== master_tx) errors = errors + 1;
            if (i == 1 && slv1_rx !== master_tx) errors = errors + 1;
            if (i == 2 && slv2_rx !== master_tx) errors = errors + 1;
            if (i == 3 && slv3_rx !== master_tx) errors = errors + 1;

            #50; // Pause before talking to the next slave
        end

        // Final Report
        $display("\n===========================================");
        if (errors == 0)
            $display(">>> PERFECT! ALL 4 SLAVES RESPONDED FLAWLESSLY! <<<");
        else
            $display(">>> SYSTEM FAILED WITH %0d ERRORS <<<", errors);
        $display("===========================================");
        
        $finish;
    end
endmodule
