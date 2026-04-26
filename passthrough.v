module passthrough (
    input clk,
    input [7:0] pixel_in,
    input valid_in,
    output reg [7:0] pixel_out,
    output reg valid_out
);
always @(posedge clk) begin
    pixel_out <= pixel_in;
    valid_out <= valid_in;
end
endmodule
