module gamma_correction (
    input clk,
    input rst,
    input [7:0] pixel_in,
    input valid_in,
    output reg [7:0] pixel_out,
    output reg valid_out
);
reg [7:0] gamma_lut [0:255];
integer i;
initial begin
    for(i=0; i<256; i=i+1) begin
        if (i < 64)
            gamma_lut[i] = i + (i >> 1);   // strong boost (dark region)
        else if (i < 128)
            gamma_lut[i] = i + (i >> 2);   // mild boost
        else
            gamma_lut[i] = i;              // preserve highlights
    end
end
always @(posedge clk) begin
    if (rst) begin
        pixel_out <= 0;
        valid_out <= 0;
    end
    else begin
        if (valid_in) begin
            pixel_out <= gamma_lut[pixel_in];
            valid_out <= 1;
        end
        else begin
            pixel_out <= 0;
            valid_out <= 0;
        end
    end
end
endmodule
