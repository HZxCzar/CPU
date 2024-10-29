module Decoder(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low
    
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
wire[7:0] br_imm={_inst_in[31],_inst_in[7],_inst_in[30:25],_inst_in[11:8],1'b0};
wire[11:0] jalr_imm=_inst_in[31:20];
wire[20:0] jal_imm={_inst_in[31],_inst_in[30:21],_inst_in[20],_inst_in[19:12]};
wire[31:0] auipc_imm={_inst_in[31:12],12'b0};
wire predict = 1'b1;
assign _stall = _inst_ready_in & opcode==OPJALR;
assign _next_pc = !_inst_ready_in ? _inst_addr : opcode == OPJAL ? _inst_addr+jal_imm : opcode == OPJALR ? _inst_addr : opcode==OPAUIPC?_inst_addr+auipc_imm:opcode==OPBRANCH ? predict? _inst_addr+br_imm:_inst_addr+4 : _inst_addr+4;
endmodule