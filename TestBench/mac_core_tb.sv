`timescale 1ns/1ps
module mac_core_tb;

//Parameters
parameter DATA_WIDTH = 8;
parameter ACC_WIDTH = 32;

//TestBench Signals
logic clk;
logic rst_n;

logic enable;
logic start;

logic [DATA_WIDTH-1 :0] a;
logic [DATA_WIDTH-1 :0] b;
logic [ACC_WIDTH-1 : 0] result;
logic done;

//DUT: Device Under Test
mac_core #(
.DATA_WIDTH(DATA_WIDTH),
.ACC_WIDTH(ACC_WIDTH)
)
 dut (
.clk (clk),
.rst_n (rst_n),
.enable (enable),
.start (start),
.a (a),
.b (b),
.result (result),
.done (done)
);

//CLOCK GENERATION 10 NS clock Period
initial begin
clk = 1'b0;
forever #5 clk = ~clk;
end

//Test Sequence
initial begin
//waveform Generation
$dumpfile ("mac_core.vcd");
$dumpvars (0, mac_core_tb);

//Initial Values
rst_n = 1'b0;
enable = 1'b0;
start = 1'b0;
a = 8'd0;
b = 8'd0;

//Test 1 

$display("------------------------------------------------------------------------------------------------------------------------------------");
$display("TEST1: Reset");
$display("------------------------------------------------------------------------------------------------------------------------------------");

#12;

if (result == 32'd0)
$display ("PASS: Reset cleared accumulator");
else
$display("FAIL: Reset did not clear accumulator");

rst_n = 1'b1;

//Test 2: First MAC operation 3 x 4 = 12

$display ("------------------------------------------------------------------------------------------------------------------------------------");
$display("TEST2: First MAC Operation");
$display ("------------------------------------------------------------------------------------------------------------------------------------");

enable = 1'b1;
start = 1'b1;
a = 8'd3;
b = 8'd4;

@(posedge clk);
#1;
if (result == 32'd12)
$display("PASS: 3 x 4 = 12");
else 
$display("FAIL: Expected 12 , got%0d", result);

if (done == 1'b1)
$display("PASS: Done asserted");
else
$display("FAIL: Done not asserted");

//Test 3: Accumulation (Previous result =12, 5 x 6 = 30 ,Expected 12 + 30 = 42 )

$display ("------------------------------------------------------------------------------------------------------------------------------------");
$display("TEST3: Accumulation");
$display ("------------------------------------------------------------------------------------------------------------------------------------");

a = 8'd5;
b = 8'd6;

@(posedge clk);
#1;

if (result == 32'd42)
$display("PASS: Accumulatiion = 42");
else
$display("FAIL: Expected 42, got %0d", result);

// Test 4 : Disable MAC

$display ("------------------------------------------------------------------------------------------------------------------------------------");
$display ("TEST4: Enable Control");
$display ("------------------------------------------------------------------------------------------------------------------------------------");

enable = 1'b0;
a = 8'd10;
b = 8'd10;

@(posedge clk);
#1;

if (result == 32'd42)
$display ("PASS: MAC disabled Correctly");
else 
$display ("FAIL: MAC operated while disabled");

//Test 5: Start Control
$display ("------------------------------------------------------------------------------------------------------------------------------------");
$display ("TEST 5: Start Control");
$display ("------------------------------------------------------------------------------------------------------------------------------------");

enable =1'b1;
start = 1'b0;
a = 8'd7;
b = 8'd8;

@(posedge clk);
#1;

if (result == 32'd42)
$display ("PASS: MAC did not operated without Start");
else 
$display ("FAIL: MAC operated without Start");

//Test 6: Another MAC Operation
$display ("------------------------------------------------------------------------------------------------------------------------------------");
$display ("TEST 6: Another MAC Operation");
$display ("------------------------------------------------------------------------------------------------------------------------------------");

start = 1'b1;

@(posedge clk);
#1;

if (result == 32'd98)
$display ("PASS: Accumulated result = 98"); 
else 
$display ("FAIL: Expected 98, got%0d", result);

//FINISH

$display("------------------------------------------------------------------------------------------------------------------------------------");
$display("ALL TESTS COMPLETED");
$display("------------------------------------------------------------------------------------------------------------------------------------");

#10;

$finish;

end

endmodule
