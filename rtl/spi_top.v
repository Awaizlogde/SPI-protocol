module spi_soc_top #(parameter DATA_WIDTH = 8) (
input  wire clk,
input  wire rst_n,
    
input  wire start,
input  wire [1:0] slave_sel,
input  wire [DATA_WIDTH-1:0] master_tx_data,
output wire [DATA_WIDTH-1:0] master_rx_data,
output wire master_done,
    
// --- Slave Data Interfaces ---
// (In a real SoC, these might connect to internal memory/registers.
// For a test chip, we expose them to the outside world).
//Can't use parameter to have multiple slave tx/rx lines ..
input  wire [DATA_WIDTH-1:0] slv0_tx_data,
input  wire [DATA_WIDTH-1:0] slv1_tx_data,
input  wire [DATA_WIDTH-1:0] slv2_tx_data,
input  wire [DATA_WIDTH-1:0] slv3_tx_data,
    
output wire [DATA_WIDTH-1:0] slv0_rx_data,
output wire [DATA_WIDTH-1:0] slv1_rx_data,
output wire [DATA_WIDTH-1:0] slv2_rx_data,
output wire [DATA_WIDTH-1:0] slv3_rx_data
);

// Internal SPI Bus Wires
wire SCLK;
wire MOSI;
wire [3:0] SS;
    
    // Individual MISO outputs from each slave
wire miso_slv0, miso_slv1, miso_slv2, miso_slv3;
    
    // The final MUXed MISO going back to the master
wire master_miso;


    // The MISO Multiplexer (Crucial for ASIC)
  
    // Instead of tri-states, we MUX the MISO based on which Slave Select is active (active low).
assign master_miso = (~SS[0]) ? miso_slv0 :
                         (~SS[1]) ? miso_slv1 :
                         (~SS[2]) ? miso_slv2 :
                         (~SS[3]) ? miso_slv3 : 1'b0; // Default to 0 if none selected

    // ==========================================
    // Core Instantiations
    // ==========================================
    
spi_master #(
.DATA_WIDTH(DATA_WIDTH), 
.SLAVES(4), 
.CLK_DIV(4), 
.CPOL(0), 
.CPHA(0)
) u_master (
.clk(clk), 
.rst_n(rst_n),
.mosi_data_reg(master_tx_data), 
.miso_data_reg(master_rx_data),
.MISO(master_miso),   // Connects to the MUX output
.MOSI(MOSI), 
.SCLK(SCLK), 
.SS(SS),
.start(start), 
.slave_sel(slave_sel), 
.done(master_done)
);

spi_slave #(
.DATA_WIDTH(DATA_WIDTH), .CPOL(0), .CPHA(0)
) u_slave0 (
.SCLK(SCLK), .rst_n(rst_n), .SS(SS[0]), .MOSI(MOSI),
.tx_data(slv0_tx_data), .MISO(miso_slv0), .rx_data(slv0_rx_data), .done()
);

spi_slave #(
.DATA_WIDTH(DATA_WIDTH), .CPOL(0), .CPHA(0)
) u_slave1 (
.SCLK(SCLK), .rst_n(rst_n), .SS(SS[1]), .MOSI(MOSI),
.tx_data(slv1_tx_data), .MISO(miso_slv1), .rx_data(slv1_rx_data), .done()
);

spi_slave #(
.DATA_WIDTH(DATA_WIDTH), .CPOL(0), .CPHA(0)
) u_slave2 (
.SCLK(SCLK), .rst_n(rst_n), .SS(SS[2]), .MOSI(MOSI),
.tx_data(slv2_tx_data), .MISO(miso_slv2), .rx_data(slv2_rx_data), .done()
);

spi_slave #(
.DATA_WIDTH(DATA_WIDTH), .CPOL(0), .CPHA(0)
) u_slave3 (
.SCLK(SCLK), .rst_n(rst_n), .SS(SS[3]), .MOSI(MOSI),
.tx_data(slv3_tx_data), .MISO(miso_slv3), .rx_data(slv3_rx_data), .done()
);

endmodule
