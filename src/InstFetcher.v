module InstFetcher(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low
    
    input  wire                 _clear,
    input  wire _stall,
    input  wire [31:0] _inst_in,
    input  wire                 _inst_ready_in,

    output wire [31:0] _pc,
    output wire [31:0] _inst_out,
    output wire                 _inst_ready_out,

    input  wire _br_dc,
    input  wire _br_rob,
    input  wire [31:0] _dc_new_pc,
    input  wire [31:0] _rob_new_pc
);
endmodule