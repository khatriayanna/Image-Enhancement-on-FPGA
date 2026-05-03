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
//// ---------- Gaussian ----------
wire [7:0] w00,w01,w02,w03,w04;
wire [7:0] w10,w11,w12,w13,w14;
wire [7:0] w20,w21,w22,w23,w24;
wire [7:0] w30,w31,w32,w33,w34;
wire [7:0] w40,w41,w42,w43,w44;
wire valid_lb;
linebuffer_5x5 lb5 (
    .clk(clk), .rst(rst),
    .pixel_in(pixel_in), .valid_in(valid_in),
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
    .clk(clk), .rst(rst),
    .w00(w00),.w01(w01),.w02(w02),.w03(w03),.w04(w04),
    .w10(w10),.w11(w11),.w12(w12),.w13(w13),.w14(w14),
    .w20(w20),.w21(w21),.w22(w22),.w23(w23),.w24(w24),
    .w30(w30),.w31(w31),.w32(w32),.w33(w33),.w34(w34),
    .w40(w40),.w41(w41),.w42(w42),.w43(w43),.w44(w44),
    .valid_in(valid_lb),
    .pixel_out(g_out),
    .valid_out(g_valid)
);
//// ---------- Guided Filter ----------
wire [7:0] gw11,gw12,gw13;
wire [7:0] gw21,gw22,gw23;
wire [7:0] gw31,gw32,gw33;
wire valid_lb_g;
linebuffer_3x3 lb_g (
    .clk(clk), .rst(rst),
    .pixel_in(g_out), .valid_in(g_valid),
    .w11(gw11),.w12(gw12),.w13(gw13),
    .w21(gw21),.w22(gw22),.w23(gw23),
    .w31(gw31),.w32(gw32),.w33(gw33),
    .valid_out(valid_lb_g)
);
wire [7:0] gf_out;
wire gf_valid;
guided_filter_3x3 gf_stage (
    .clk(clk), .rst(rst),
    .w11(gw11),.w12(gw12),.w13(gw13),
    .w21(gw21),.w22(gw22),.w23(gw23),
    .w31(gw31),.w32(gw32),.w33(gw33),
    .valid_in(valid_lb_g),
    .pixel_out(gf_out),
    .valid_out(gf_valid)
);
//// ---------- LoG ----------
wire [7:0] lw11,lw12,lw13;
wire [7:0] lw21,lw22,lw23;
wire [7:0] lw31,lw32,lw33;
wire valid_lb2;
linebuffer_3x3 lb3 (
    .clk(clk), .rst(rst),
    .pixel_in(gf_out), .valid_in(gf_valid),
    .w11(lw11),.w12(lw12),.w13(lw13),
    .w21(lw21),.w22(lw22),.w23(lw23),
    .w31(lw31),.w32(lw32),.w33(lw33),
    .valid_out(valid_lb2)
);
wire [7:0] log_out;
wire log_valid;
log_3x3 log (
    .clk(clk), .rst(rst),
    .w11(lw11),.w12(lw12),.w13(lw13),
    .w21(lw21),.w22(lw22),.w23(lw23),
    .w31(lw31),.w32(lw32),.w33(lw33),
    .valid_in(valid_lb2),
    .pixel_out(log_out),
    .valid_out(log_valid)
);
//// ---------- Laplacian Sharpen ----------
wire [7:0] sharp_out;
wire sharp_valid;
laplacian_sharpen sharp_stage (
    .clk(clk), .rst(rst),
    .base_in(gf_out),
    .edge_in(log_out),
    .valid_in(log_valid),
    .pixel_out(sharp_out),
    .valid_out(sharp_valid)
);
//// ---------- Unsharp Mask ----------
wire [7:0] us_out;
wire us_valid;
unsharp_mask us_stage (
    .clk(clk), .rst(rst),
    .sharp_in(sharp_out),
    .blur_in(g_out),
    .valid_in(sharp_valid),
    .pixel_out(us_out),
    .valid_out(us_valid)
);
//// ---------- Gamma Correction ----------
wire [7:0] gamma_out;
wire gamma_valid;
gamma_correction gamma_stage (
    .clk(clk),
    .rst(rst),
    .pixel_in(us_out),
    .valid_in(us_valid),
    .pixel_out(gamma_out),
    .valid_out(gamma_valid)
);
//// ---------- FINAL OUTPUT ----------
assign pixel_out = gamma_out;
assign valid_out = gamma_valid;
endmodule
