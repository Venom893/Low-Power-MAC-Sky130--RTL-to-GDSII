module mac_core #(
parameter int DATA_WIDTH = 8,
parameter int ACC_WIDTH  = 32
) (
input logic
clk,
input logic
rst_n,

//Low-power control
input logic
enable,

//MAC control
input logic
start,

//Operands
input logic [DATA_WIDTH-1:0]
a,
input logic [DATA_WIDTH-1:0]
b,

//Result Interface
output logic [ACC_WIDTH-1:0]
result,
output logic
done
);

// Internal DATAPATH
//

//Accumulator Stores the Running MAC Result
logic [ACC_WIDTH-1:0] 
accumulator;

//Product width for DATA_WIDTH x DATA_WIDTH multiplication
logic [(2*DATA_WIDTH)-1:0]
product;

//Operand- isolated signals for low-power operations
logic [DATA_WIDTH-1:0]
a_gated;
logic [DATA_WIDTH-1:0]
b_gated;

//Low-Power Operand Isolation
assign a_gated = (enable && start) ? a : '0;
assign b_gated = (enable && start) ? b : '0;

//Multiplier
assign product = a_gated * b_gated;

//Accumulator and Control logic
always_ff @(posedge clk or negedge rst_n) begin

if (!rst_n) begin
accumulator <= '0;
done        <= 1'b0;

end
else begin
//done is a one cycle pulse
done <= 1'b0;

//Perform MAC operation only when enabled 
if (enable && start)
begin

accumulator <= accumulator + product;
done <=1'b1;

end
end
end

//RESULT Output
assign result = accumulator;

endmodule
