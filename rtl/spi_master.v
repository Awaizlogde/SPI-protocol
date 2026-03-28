module spi_master #(parameter DATA_WIDTH = 8, SLAVES = 4, CLK_DIV = 5, CPOL = 0, CPHA = 0)(
input wire clk,
input wire rst_n,
input wire [DATA_WIDTH-1:0] mosi_data_reg,
output reg [DATA_WIDTH-1:0] miso_data_reg,
input wire MISO,
output reg MOSI,
output reg SCLK,
output reg [SLAVES-1:0]SS,                   
input wire start,                           
input wire [$clog2(SLAVES)-1:0] slave_sel,    
output reg  done                              
);

reg [$clog2(DATA_WIDTH):0] bit_cnt;

reg [$clog2(CLK_DIV)-1:0] clk_cnt;
reg [DATA_WIDTH-1:0] tx_reg;
reg [DATA_WIDTH-1:0] rx_reg;

reg [1:0] state;

localparam 
IDLE = 2'b00,
START = 2'b01,
TRANSFER = 2'b10,
DONE = 2'b11;

wire sclk_posedge = (clk_cnt == CLK_DIV-1) && (SCLK == 1'b0);
wire sclk_negedge = (clk_cnt == CLK_DIV-1) && (SCLK == 1'b1);

wire lead_edge = (CPOL==0) ? sclk_posedge : sclk_negedge;
wire trail_edge = (CPOL==0) ? sclk_negedge : sclk_posedge;

wire sample_edge = (CPHA == 0) ? lead_edge : trail_edge;
wire shift_edge = (CPHA == 0) ? trail_edge : lead_edge;

always @(posedge clk) begin
if (!rst_n) begin
SCLK <= CPOL;
SS <= {SLAVES{1'b1}};
MOSI <= 0;
state <= IDLE;
miso_data_reg <= 0;
tx_reg <= 0;
rx_reg <= 0;
bit_cnt <= 0;
done <= 0;
clk_cnt <= 0;
end 
else 
begin
case(state)

IDLE: begin
done <= 0;
SS <= {SLAVES{1'b1}};
clk_cnt <= 0;
SCLK <= CPOL;
if(start)begin
state <= START;
end
end

START: begin 
SCLK <= CPOL;
SS[slave_sel] <= 0;
bit_cnt <= 0;
clk_cnt <= 0;
tx_reg <= mosi_data_reg;
if(CPHA == 0) begin
MOSI <= mosi_data_reg[DATA_WIDTH-1];
end else begin 
MOSI <= 1'b0;
end
state <= TRANSFER;
end 


TRANSFER: begin
if (clk_cnt == CLK_DIV-1) begin 
clk_cnt <= 0; 
SCLK <= ~SCLK; 

//SHIFT LOGIC
if (shift_edge) begin
if (bit_cnt == DATA_WIDTH) begin
state <= DONE;
end else begin
tx_reg <= {tx_reg[DATA_WIDTH-2:0], 1'b0};
MOSI <= tx_reg[DATA_WIDTH-2];
end
end
//  SAMPLE LOGIC 
if (sample_edge) begin
rx_reg <= {rx_reg[DATA_WIDTH-2:0], MISO};
bit_cnt <= bit_cnt + 1;
            
if (CPHA == 1 && bit_cnt == DATA_WIDTH-1) begin
state <= DONE;
end
end
end else begin
clk_cnt <= clk_cnt + 1; 
end
end

DONE: begin 
SS <= {SLAVES{1'b1}};
SCLK <= CPOL;
MOSI <= 1'b0;
miso_data_reg <= rx_reg;
state <= IDLE;
done <= 1'b1;
end
default : state <= IDLE;
endcase
end
end
endmodule

