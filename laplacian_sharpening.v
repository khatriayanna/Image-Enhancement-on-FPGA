module laplacian_sharpen (
    input clk,
    input rst,
    input [7:0] base_in,
    input [7:0] edge_in,
    input valid_in,
    output reg [7:0] pixel_out,
    output reg valid_out
);
reg [15:0] temp;
reg [7:0] edge_scaled;
always @(posedge clk) begin
    if (rst) begin
        pixel_out <= 0;
        valid_out <= 0;
    end
    else begin
        if(valid_in) begin
            // REDUCE EDGE STRENGTH (CRITICAL FIX)
            edge_scaled = edge_in >> 1;   // divide by 2
            // Sharpen
            temp = base_in + edge_scaled;
            // Clamp
            if (temp > 255)
                pixel_out <= 8'd255;
            else
                pixel_out <= temp[7:0];
            valid_out <= 1;
        end
        else begin
            valid_out <= 0;
        end
    end
end
endmodule
