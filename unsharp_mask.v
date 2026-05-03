module unsharp_mask (
    input clk,
    input rst,
    input [7:0] sharp_in,
    input [7:0] blur_in,
    input valid_in,
    output reg [7:0] pixel_out,
    output reg valid_out
);
reg signed [15:0] mask;
reg signed [15:0] temp;
always @(posedge clk) begin
    if (rst) begin
        pixel_out <= 0;
        valid_out <= 0;
    end
    else begin
        if (valid_in) begin
            // Mask
            mask = $signed({1'b0, sharp_in}) - $signed({1'b0, blur_in});
            // Reduced gain (stable)
            temp = $signed({1'b0, sharp_in}) + (mask >>> 2);
            // Clamp
            if (temp < 0)
                pixel_out <= 0;
            else if (temp > 255)
                pixel_out <= 8'd255;
            else
                pixel_out <= temp[7:0];
            valid_out <= 1;
        end
        else begin
            pixel_out <= 0;
            valid_out <= 0;
        end
    end
end
endmodule
