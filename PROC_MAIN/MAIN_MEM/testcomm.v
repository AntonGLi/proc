module tb();
reg [31:0] upr;
wire [31:0] out;
command_memory meme1 (.upr(upr), .out(out));
initial begin
	$dumpfile("test.vcd");
	$dumpvars(0, tb);
	upr = 32'd0; #10
	upr = 32'd1; #10
	upr = 32'd2; #10
	upr = 32'd3; #10
	upr = upr + 4; #10
	upr = upr + 4; #10
	upr = upr + 4; #10
	upr = upr + 4;
end
endmodule
 
