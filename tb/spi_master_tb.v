`timescale 1ns/1ps

module spi_tb;

parameter DATA_WIDTH = 8;
parameter SLAVES = 4;

reg clk;
reg rst_n;
reg start;
reg [DATA_WIDTH-1:0] mosi_data_reg;
reg [$clog2(SLAVES)-1:0] slave_sel;

wire [DATA_WIDTH-1:0] miso_data_reg;
wire MOSI;
wire MISO;
wire SCLK;
wire [SLAVES-1:0] SS;
wire done;

wire MISO0, MISO1, MISO2, MISO3;

wire [DATA_WIDTH-1:0] rx0, rx1, rx2, rx3;
wire done0, done1, done2, done3;

reg [DATA_WIDTH-1:0] tx0, tx1, tx2, tx3;

spi_master #(
.DATA_WIDTH(DATA_WIDTH),
.SLAVES(SLAVES)
) 
master_inst (
.clk(clk),
.rst(rst_n),
.mosi_data_reg(mosi_data_reg),
.miso_data_reg(miso_data_reg),
.MISO(MISO),
.MOSI(MOSI),
.SCLK(SCLK),
.SS(SS),
.start(start),
.slave_sel(slave_sel),
 .done(done)
);

spi_slave #(.DATA_WIDTH(DATA_WIDTH)) 
slave0 (
.SCLK(SCLK),
.rst_n(rst_n),
.SS(SS[0]),
.MOSI(MOSI),
.MISO(MISO0),

.tx_data(tx0),
.rx_data(rx0),
.done(done0) 
);

spi_slave #(.DATA_WIDTH(DATA_WIDTH)) 
slave1 (
.SCLK(SCLK),
.rst_n(rst_n),
.SS(SS[1]),
.MOSI(MOSI),
.MISO(MISO1),

.tx_data(tx1),
.rx_data(rx1),
.done(done1)
);

spi_slave #(.DATA_WIDTH(DATA_WIDTH)) 
slave2 (
.SCLK(SCLK),
.rst_n(rst_n),
.SS(SS[2]),
.MOSI(MOSI),
.MISO(MISO2),
.tx_data(tx2),
.rx_data(rx2),
.done(done2)
);

spi_slave #(.DATA_WIDTH(DATA_WIDTH)) 
slave3 (
.SCLK(SCLK),
.rst_n(rst_n),
.SS(SS[3]),
.MOSI(MOSI),
.MISO(MISO3),
.tx_data(tx3),
.rx_data(rx3),
.done(done3)
);

assign MISO =
(SS[0] == 0) ? MISO0 :
(SS[1] == 0) ? MISO1 :
(SS[2] == 0) ? MISO2 :
(SS[3] == 0) ? MISO3 :
1'b0;

always #5 clk = ~clk;

initial begin
clk = 0;
rst_n = 0;
start = 0;

tx0 = 8'd95;
tx1 = 8'd108;
tx2 = 8'd10;
tx3 = 8'd30;

repeat(2) @(posedge clk);
rst_n = 1;

repeat(4) begin
    
slave_sel = 3;
mosi_data_reg = 8'b11100011;
    
@(posedge clk);
start = 1;

@(posedge clk);    
start = 0;
    
wait(done);
    
$display("Slave %0d | Sent: %h | Received: %h", slave_sel, mosi_data_reg, miso_data_reg);
    
#20;

end
$display("================================");
$display("All SPI transactions completed");
$display("================================");
$finish;
end
endmodule
