`timescale 1ns/1ps

module tb_spi_soc_top();
    
parameter DATA_WIDTH = 8;

// --- System Inputs ---
reg clk;
reg rst_n;
    
 // --- Master Control Inputs ---
reg start;
reg [1:0] slave_sel;
reg [DATA_WIDTH-1:0] master_tx_data;
    
// --- Slave Data Inputs ---
reg [DATA_WIDTH-1:0] slv0_tx_data;
reg [DATA_WIDTH-1:0] slv1_tx_data;
reg [DATA_WIDTH-1:0] slv2_tx_data;
reg [DATA_WIDTH-1:0] slv3_tx_data;

// --- System Outputs ---
 wire [DATA_WIDTH-1:0] master_rx_data;
wire master_done;
wire [DATA_WIDTH-1:0] slv0_rx_data;
wire [DATA_WIDTH-1:0] slv1_rx_data;
wire [DATA_WIDTH-1:0] slv2_rx_data;
wire [DATA_WIDTH-1:0] slv3_rx_data;

// --- Instantiate the DUT (Device Under Test) ---
spi_soc_top #(.DATA_WIDTH(DATA_WIDTH)) dut (
.clk(clk),
.rst_n(rst_n),
.start(start),
.slave_sel(slave_sel),
.master_tx_data(master_tx_data),
.master_rx_data(master_rx_data),
.master_done(master_done),
.slv0_tx_data(slv0_tx_data),
.slv1_tx_data(slv1_tx_data),
.slv2_tx_data(slv2_tx_data),
.slv3_tx_data(slv3_tx_data),
.slv0_rx_data(slv0_rx_data),
.slv1_rx_data(slv1_rx_data),
.slv2_rx_data(slv2_rx_data),
.slv3_rx_data(slv3_rx_data)
);

// --- Generate 100MHz System Clock ---
always #5 clk = ~clk;

// --- Test Variables ---
integer i;
integer errors;
reg [DATA_WIDTH-1:0] expected_rx;

initial begin
// Initialize Inputs
clk = 0;
rst_n = 0;
start = 0;
slave_sel = 0;
master_tx_data = 0;
        
// Give each slave unique data to send back
slv0_tx_data = 8'hA1; 
slv1_tx_data = 8'hB2;
slv2_tx_data = 8'hC3;
slv3_tx_data = 8'hD4;
        
errors = 0;

$display("===========================================");
$display("   STARTING SoC TOP LEVEL VERIFICATION     ");
$display("===========================================");

// Release Reset
#20 rst_n = 1; #20;

// Loop through all 4 slaves
for (i = 0; i < 4; i = i + 1) begin
slave_sel = i;
master_tx_data = $random % 256; // Generate random data for master
            
 // Determine expected data based on selected slave
if (i == 0) expected_rx = slv0_tx_data;
if (i == 1) expected_rx = slv1_tx_data;
if (i == 2) expected_rx = slv2_tx_data;
if (i == 3) expected_rx = slv3_tx_data;

$display("\n--- Initiating Transfer with Slave %0d ---", i);
$display("Master sending: %h | Expecting back: %h", master_tx_data, expected_rx);

// Trigger the start signal for one clock cycle
@(posedge clk);
start = 1;
@(posedge clk);
start = 0;

// Wait for the master to flag completion
wait(master_done == 1'b1);
@(posedge clk); // Give registers one cycle to settle

// --- Verification Phase ---
            
// 1. Did the Master receive the correct Slave data?
if (master_rx_data !== expected_rx) begin
$display("❌ ERROR: Master received %h, expected %h", master_rx_data, expected_rx);
errors = errors + 1;
end else begin
$display("✅ SUCCESS: Master received correct data (%h)", master_rx_data);
end

// 2. Did the targeted Slave receive the correct Master data?
if (i == 0 && slv0_rx_data !== master_tx_data) begin
$display("❌ ERROR: Slave 0 received %h, expected %h", slv0_rx_data, master_tx_data);
errors = errors + 1;
end
if (i == 1 && slv1_rx_data !== master_tx_data) begin
$display("❌ ERROR: Slave 1 received %h, expected %h", slv1_rx_data, master_tx_data);
errors = errors + 1;
end
if (i == 2 && slv2_rx_data !== master_tx_data) begin
$display("❌ ERROR: Slave 2 received %h, expected %h", slv2_rx_data, master_tx_data);
errors = errors + 1;
end
if (i == 3 && slv3_rx_data !== master_tx_data) begin
$display("❌ ERROR: Slave 3 received %h, expected %h", slv3_rx_data, master_tx_data);
errors = errors + 1;
end

#50; // Pause between slave transactions
end

// Final Result Generation
$display("\n===========================================");
if (errors == 0)
$display(">>> PERFECT! ALL TESTS PASSED FLAWLESSLY! <<<");
else
$display(">>> SYSTEM FAILED WITH %0d ERRORS <<<", errors);
$display("===========================================");
        
$finish;
end
endmodule
