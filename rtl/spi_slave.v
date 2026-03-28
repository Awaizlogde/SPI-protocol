
module spi_slave #(parameter DATA_WIDTH = 8, CPOL = 0, CPHA = 0) (
input wire SCLK,
input wire rst_n,
input wire SS, 
input wire MOSI,
input wire [DATA_WIDTH-1:0] tx_data,
output wire MISO,
output reg [DATA_WIDTH-1:0] rx_data,
output reg  done  
);

reg [$clog2(DATA_WIDTH):0] bit_cnt;

reg [DATA_WIDTH-1:0] rx_reg;
reg [DATA_WIDTH-1:0] tx_reg;

reg [1:0] state;

reg tx_loaded;

localparam 
IDLE = 2'b00,
TRANSFER = 2'b10,
DONE = 2'b11;

wire sclk_sample = (CPOL ^ CPHA ) ? ~SCLK : SCLK;
wire sclk_shift = (CPOL ^ CPHA ) ? SCLK : ~SCLK;

assign MISO = (!SS) ? ((state == IDLE)) ? tx_data[DATA_WIDTH-1] : tx_reg[DATA_WIDTH-1] :1'bz;

always@(posedge sclk_sample or negedge rst_n) begin
if(!rst_n)begin
bit_cnt <= 0;
rx_data <= 0;
done <= 0;
rx_reg <= 0;
state <= IDLE;
end 
else begin
case(state)

IDLE: begin
done <= 0;
if(!SS)begin
rx_reg <= {rx_reg[DATA_WIDTH-2:0], MOSI};
bit_cnt <= 1;
state <= TRANSFER;

end
end

TRANSFER: begin 
if(bit_cnt == DATA_WIDTH-1) begin
state <= DONE;
rx_data <= {rx_reg[DATA_WIDTH-2:0], MOSI};
done <= 1;
bit_cnt <= 0;
end else begin
rx_reg <= {rx_reg[DATA_WIDTH-2:0], MOSI};
bit_cnt <= bit_cnt + 1;
end
end

DONE: begin
done <= 1;
if(SS) begin
state <= IDLE;
done <= 0;
end
end

default  : state<= IDLE;
endcase
end
end

always@(posedge sclk_shift or negedge rst_n)begin
if(!rst_n)begin
tx_reg <= 0;
tx_loaded <= 0;
end else begin
if(SS) begin 
tx_reg <= 0;
tx_loaded <= 0;
end else begin
if(!tx_loaded)begin
tx_reg <= {tx_data[DATA_WIDTH-2:0], 1'b0};
tx_loaded <= 1;
end else if (state == TRANSFER) begin
tx_reg <= {tx_reg[DATA_WIDTH-2:0],1'b0};
end
end
end
end
endmodule 

