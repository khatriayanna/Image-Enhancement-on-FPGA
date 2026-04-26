module gaussian_5x5 (
    input clk,
    input rst,
    input [7:0] w00,w01,w02,w03,w04,
    input [7:0] w10,w11,w12,w13,w14,
    input [7:0] w20,w21,w22,w23,w24,
    input [7:0] w30,w31,w32,w33,w34,
    input [7:0] w40,w41,w42,w43,w44,
    input valid_in,
    output reg [7:0] pixel_out,
    output reg valid_out
);
reg [31:0] sum;
always @(posedge clk) begin
    if (rst) begin
        pixel_out <= 0;
        valid_out <= 0;
        sum <= 0;
    end
    else begin
        if(valid_in) begin
            sum <=
              1*w00 + 4*w01 + 6*w02 + 4*w03 + 1*w04 +
              4*w10 +16*w11 +24*w12 +16*w13 + 4*w14 +
              6*w20 +24*w21 +36*w22 +24*w23 + 6*w24 +
              4*w30 +16*w31 +24*w32 +16*w33 + 4*w34 +
              1*w40 + 4*w41 + 6*w42 + 4*w43 + 1*w44;
            pixel_out <= sum >> 8;
            valid_out <= 1;
        end
        else begin
            valid_out <= 0;
        end
    end
end
endmodule


module linebuffer_5x5 #(
    parameter WIDTH = 256
)(
    input clk,
    input rst,
    input [7:0] pixel_in,
    input valid_in,
    output reg [7:0] w00,w01,w02,w03,w04,
    output reg [7:0] w10,w11,w12,w13,w14,
    output reg [7:0] w20,w21,w22,w23,w24,
    output reg [7:0] w30,w31,w32,w33,w34,
    output reg [7:0] w40,w41,w42,w43,w44,
    output reg valid_out
);
reg [7:0] line1 [0:WIDTH-1];
reg [7:0] line2 [0:WIDTH-1];
reg [7:0] line3 [0:WIDTH-1];
reg [7:0] line4 [0:WIDTH-1];
integer i;
reg [15:0] col;
always @(posedge clk) begin
    if (rst) begin
        col <= 0;
        valid_out <= 0;
        for(i=0;i<WIDTH;i=i+1) begin
            line1[i] <= 0;
            line2[i] <= 0;
            line3[i] <= 0;
            line4[i] <= 0;
        end
        {w00,w01,w02,w03,w04} <= 0;
        {w10,w11,w12,w13,w14} <= 0;
        {w20,w21,w22,w23,w24} <= 0;
        {w30,w31,w32,w33,w34} <= 0;
        {w40,w41,w42,w43,w44} <= 0;
    end
    else begin
        if(valid_in) begin
            // vertical shift
            line4[col] <= line3[col];
            line3[col] <= line2[col];
            line2[col] <= line1[col];
            line1[col] <= pixel_in;
            // horizontal shift
            {w00,w01,w02,w03,w04} <= {w01,w02,w03,w04,line4[col]};
            {w10,w11,w12,w13,w14} <= {w11,w12,w13,w14,line3[col]};
            {w20,w21,w22,w23,w24} <= {w21,w22,w23,w24,line2[col]};
            {w30,w31,w32,w33,w34} <= {w31,w32,w33,w34,line1[col]};
            {w40,w41,w42,w43,w44} <= {w41,w42,w43,w44,pixel_in};
            // column update
            if(col == WIDTH-1)
                col <= 0;
            else
                col <= col + 1;
        end
        // FORCE VALID (DEBUG)
        valid_out <= valid_in;
    end
end
endmodule






module linebuffer_3x3 #(
    parameter WIDTH = 256
)(
    input clk,
    input rst,
    input [7:0] pixel_in,
    input valid_in,
    output reg [7:0] w11,w12,w13,
    output reg [7:0] w21,w22,w23,
    output reg [7:0] w31,w32,w33,
    output reg valid_out
);
reg [7:0] line1 [0:WIDTH-1];
reg [7:0] line2 [0:WIDTH-1];
integer i;
reg [15:0] col;
always @(posedge clk) begin
    if (rst) begin
        col <= 0;
        valid_out <= 0;
        for(i=0;i<WIDTH;i=i+1) begin
            line1[i] <= 0;
            line2[i] <= 0;
        end
        {w11,w12,w13} <= 0;
        {w21,w22,w23} <= 0;
        {w31,w32,w33} <= 0;
    end
    else begin
        if(valid_in) begin
            // vertical shift
            line2[col] <= line1[col];
            line1[col] <= pixel_in;
            // horizontal shift
            {w11,w12,w13} <= {w12,w13,line2[col]};
            {w21,w22,w23} <= {w22,w23,line1[col]};
            {w31,w32,w33} <= {w32,w33,pixel_in};
            if(col == WIDTH-1)
                col <= 0;
            else
                col <= col + 1;
        end
        valid_out <= valid_in;
    end
end
endmodule






module log_3x3 (
    input clk,
    input rst,
    input [7:0] w11,w12,w13,
    input [7:0] w21,w22,w23,
    input [7:0] w31,w32,w33,
    input valid_in,
    output reg [7:0] pixel_out,
    output reg valid_out
);
reg signed [15:0] lap;
always @(posedge clk) begin
    if (rst) begin
        pixel_out <= 0;
        valid_out <= 0;
    end
    else begin
        if(valid_in) begin
            // Laplacian
            lap = (w12 + w21 + w23 + w32) - (4 * w22);
            // Absolute value
            if (lap < 0)
                lap = -lap;
            // SCALE (CRITICAL FIX)
            lap = lap << 2;   // amplify edges
            // Clamp to 8-bit
            if (lap > 255)
                pixel_out <= 8'd255;
            else
                pixel_out <= lap[7:0];
            valid_out <= 1;
        end
        else begin
            valid_out <= 0;
        end
    end
end
endmodule


module gaussian_top #(
    parameter WIDTH = 256
)(
    input clk,
    input rst,
    input [7:0] pixel_in,
    input valid_in,
    output [7:0] pixel_out,
    output valid_out
);
wire [7:0] w00,w01,w02,w03,w04;
wire [7:0] w10,w11,w12,w13,w14;
wire [7:0] w20,w21,w22,w23,w24;
wire [7:0] w30,w31,w32,w33,w34;
wire [7:0] w40,w41,w42,w43,w44;
wire valid_lb;
linebuffer_5x5 #(.WIDTH(WIDTH)) lb (
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
gaussian_5x5 gf (
    .clk(clk),
    .rst(rst),
    .w00(w00),.w01(w01),.w02(w02),.w03(w03),.w04(w04),
    .w10(w10),.w11(w11),.w12(w12),.w13(w13),.w14(w14),
    .w20(w20),.w21(w21),.w22(w22),.w23(w23),.w24(w24),
    .w30(w30),.w31(w31),.w32(w32),.w33(w33),.w34(w34),
    .w40(w40),.w41(w41),.w42(w42),.w43(w43),.w44(w44),
    .valid_in(valid_lb),
    .pixel_out(pixel_out),
    .valid_out(valid_out)
);
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
//// ---------- LoG Stage ----------
wire [7:0] lw11,lw12,lw13;
wire [7:0] lw21,lw22,lw23;
wire [7:0] lw31,lw32,lw33;
wire valid_lb2;
linebuffer_3x3 lb3 (
    .clk(clk),
    .rst(rst),
    .pixel_in(g_out),
    .valid_in(g_valid),
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
