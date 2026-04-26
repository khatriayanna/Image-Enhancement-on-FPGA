module tb;
reg clk;
reg rst;
reg [7:0] pixel_in;
reg valid_in;
wire [7:0] pixel_out;
wire valid_out;
integer file_in, file_out;
integer r;
integer temp;
// Instantiate DUT
image_pipeline uut (
    .clk(clk),
    .rst(rst),
    .pixel_in(pixel_in),
    .valid_in(valid_in),
    .pixel_out(pixel_out),
    .valid_out(valid_out)
);
// Clock
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end
// Reset
initial begin
    rst = 1;
    #20;
    rst = 0;
end
// File read + write
initial begin
    file_in  = $fopen("C:/Users/HP/OneDrive/Desktop/Imp Documents/Capstone/pepperscolored.txt","r");
    file_out = $fopen("pepperscoloredoutput3.txt","w");
    if (file_in == 0) begin
        $display("Error opening input file");
        $finish;
    end
    if (file_out == 0) begin
        $display("Error opening output file");
        $finish;
    end
    valid_in = 0;
    #30;
    while (!$feof(file_in)) begin
        r = $fscanf(file_in,"%d\n", temp);
        pixel_in = temp[7:0];
        valid_in = 1;
        @(posedge clk);
        if (valid_out) begin
                $fwrite(file_out,"%d\n", pixel_out);
        end
    end
    valid_in = 0;
    // Allow pipeline to flush remaining data
    repeat (500) begin
        @(posedge clk);
        if (valid_out) begin
                $fwrite(file_out,"%d\n", pixel_out);
        end
    end
    $fclose(file_in);
    $fclose(file_out);
    $finish;
end
endmodule
