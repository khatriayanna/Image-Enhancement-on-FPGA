module guided_filter_3x3 (
    input clk,
    input rst,
    input [7:0] w11,w12,w13,
    input [7:0] w21,w22,w23,
    input [7:0] w31,w32,w33,
    input valid_in,
    output reg [7:0] pixel_out,
    output reg valid_out
);
reg [15:0] sum;
reg [7:0] mean;
reg [15:0] var_sum;
reg [15:0] var;
reg [15:0] a;
reg [15:0] b;
reg [15:0] temp_out;
parameter EPS = 16'd16;
always @(posedge clk) begin
    if (rst) begin
        pixel_out <= 0;
        valid_out <= 0;
    end
    else begin
        if(valid_in) begin
            // Mean
            sum = w11+w12+w13+w21+w22+w23+w31+w32+w33;
            mean = sum / 9;
            // Variance
            var_sum =
                (w11-mean)*(w11-mean) +
                (w12-mean)*(w12-mean) +
                (w13-mean)*(w13-mean) +
                (w21-mean)*(w21-mean) +
                (w22-mean)*(w22-mean) +
                (w23-mean)*(w23-mean) +
                (w31-mean)*(w31-mean) +
                (w32-mean)*(w32-mean) +
                (w33-mean)*(w33-mean);
            var = var_sum / 9;
            // a ≈ var/(var + eps)
            a = (var << 4) / (var + EPS);
            // b = mean*(1 - a)
            b = (mean << 4) - ((a * mean) >> 4);
            // Output
            temp_out = ((a * w22) >> 4) + b;
            // Clamp
            if (temp_out > 255)
                pixel_out <= 8'd255;
            else
                pixel_out <= temp_out[7:0];
            valid_out <= 1;
        end
        else begin
            valid_out <= 0;
        end
    end
end
endmodule



module image_pipeline #(
    parameter WIDTH = 256
)(
    input clk,
    input rst,
    input [7:0] pixel_in,
    input valid_in,
    output [7:0] pixel_out,
    output valid_out
);
//// ---------- Gaussian Stage ----------
wire [7:0] w00,w01,w02,w03,w04;
wire [7:0] w10,w11,w12,w13,w14;
wire [7:0] w20,w21,w22,w23,w24;
wire [7:0] w30,w31,w32,w33,w34;
wire [7:0] w40,w41,w42,w43,w44;
wire valid_lb;
linebuffer_5x5 lb5 (
    .clk(clk),
    .rst(rst),
    .pixel_in(pixel_in),
    .valid_in(valid_in),
    .w00(w00),.w01(w01),.w02(w02),.w03(w03),.w04(w04),
    .w10(w10),.w11(w11),.w12(w12),.w13(w13),.w14(w14),
    .w20(w20),.w21(w21),.w22(w22),.w23(w23),.w24(w24),
    .w30(w30),.w31(w31),.w32(w32),.w33(w33),.w34(w34),
    .w40(w40),.w41(w41),.w42(w42),.w43(w43),.w44(w44),
    .valid_out(valid_lb)
);
wire [7:0] g_out;
wire g_valid;
gaussian_5x5 gf (
    .clk(clk),
    .rst(rst),
    .w00(w00),.w01(w01),.w02(w02),.w03(w03),.w04(w04),
    .w10(w10),.w11(w11),.w12(w12),.w13(w13),.w14(w14),
    .w20(w20),.w21(w21),.w22(w22),.w23(w23),.w24(w24),
    .w30(w30),.w31(w31),.w32(w32),.w33(w33),.w34(w34),
    .w40(w40),.w41(w41),.w42(w42),.w43(w43),.w44(w44),
    .valid_in(valid_lb),
    .pixel_out(g_out),
    .valid_out(g_valid)
);
//// ---------- Guided Filter Stage ----------
wire [7:0] gw11,gw12,gw13;
wire [7:0] gw21,gw22,gw23;
wire [7:0] gw31,gw32,gw33;
wire valid_lb_g;
linebuffer_3x3 lb_g (
    .clk(clk),
    .rst(rst),
    .pixel_in(g_out),
    .valid_in(g_valid),
    .w11(gw11),.w12(gw12),.w13(gw13),
    .w21(gw21),.w22(gw22),.w23(gw23),
    .w31(gw31),.w32(gw32),.w33(gw33),
    .valid_out(valid_lb_g)
);
wire [7:0] gf_out;
wire gf_valid;
guided_filter_3x3 gf_stage (
    .clk(clk),
    .rst(rst),
    .w11(gw11),.w12(gw12),.w13(gw13),
    .w21(gw21),.w22(gw22),.w23(gw23),
    .w31(gw31),.w32(gw32),.w33(gw33),
    .valid_in(valid_lb_g),
    .pixel_out(gf_out),
    .valid_out(gf_valid)
);
//// ---------- LoG Stage ----------
wire [7:0] lw11,lw12,lw13;
wire [7:0] lw21,lw22,lw23;
wire [7:0] lw31,lw32,lw33;
wire valid_lb2;
linebuffer_3x3 lb3 (
    .clk(clk),
    .rst(rst),
    .pixel_in(gf_out),
    .valid_in(gf_valid),
    .w11(lw11),.w12(lw12),.w13(lw13),
    .w21(lw21),.w22(lw22),.w23(lw23),
    .w31(lw31),.w32(lw32),.w33(lw33),
    .valid_out(valid_lb2)
);
wire [7:0] log_out;
wire log_valid;
log_3x3 log (
    .clk(clk),
    .rst(rst),
    .w11(lw11),.w12(lw12),.w13(lw13),
    .w21(lw21),.w22(lw22),.w23(lw23),
    .w31(lw31),.w32(lw32),.w33(lw33),
    .valid_in(valid_lb2),
    .pixel_out(log_out),
    .valid_out(log_valid)
);
assign pixel_out = log_out;
assign valid_out = log_valid;
endmodule
