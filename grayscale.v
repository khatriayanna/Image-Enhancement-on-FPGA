module grayscale (
    input clk,
    input [23:0] pixel_in,   // RGB: [23:16]=R, [15:8]=G, [7:0]=B
    input valid_in,
    output reg [7:0] pixel_out,
    output reg valid_out
);
wire [7:0] R, G, B;
assign R = pixel_in[23:16];
assign G = pixel_in[15:8];
assign B = pixel_in[7:0];
reg [15:0] gray_temp;
always @(posedge clk) begin
    gray_temp <= (77*R + 150*G + 29*B);
    pixel_out <= gray_temp >> 8;   // divide by 256
    valid_out <= valid_in;
end
endmodule
