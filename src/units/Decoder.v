module Decoder(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low
    
    input  wire                 _br_rob,
    input  wire [31:0]          _rob_new_pc,
    input  wire [31:0]          _rob_imm,      
    // InstFetcher inputs
    input  wire                 _clear,
    input  wire [31:0]          _inst_in,
    input  wire                 _inst_ready_in,
    input  wire [31:0]          _inst_addr,
    // InstFetcher outputs
    output  wire                _stall,
    output wire [31:0]          _next_pc
);
localparam OPBRANCH = 7'b1100011,OPJALR = 7'b1100111,OPJAL = 7'b1101111,OPAUIPC=7'b0010111;
wire[6:0] opcode=_inst_in[6:0];
wire[2:0] funct3=_inst_in[14:12];
wire[31:0] br_imm={{20{_inst_in[31]}},_inst_in[31],_inst_in[7],_inst_in[30:25],_inst_in[11:8],1'b0};
wire[31:0] jalr_imm={_inst_in[31:20],20'b0};
wire[31:0] jal_imm={{12{_inst_in[31]}},_inst_in[19:12],_inst_in[20],_inst_in[30:21],1'b0};
wire[31:0] auipc_imm={_inst_in[31:12],12'b0};
wire predict = 1'b1;
pc_adder adder(
    ._pc(_br_rob?_rob_new_pc:_inst_addr),
    ._imm(_br_rob?_rob_imm:(!_inst_ready_in?32'd0:opcode==OPJAL?jal_imm:opcode==OPJALR?32'd4:opcode==OPBRANCH?predict?br_imm:32'd4:32'd4)),
    ._next_pc(_next_pc)
);
assign _stall = !_br_rob && _inst_ready_in && opcode==OPJALR;
endmodule

module pc_adder(
    input wire [31:0] _pc,
    input wire [31:0] _imm,
    output wire [31:0] _next_pc
);
assign _next_pc = _pc + _imm;
endmodule