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
    output wire [31:0]          _next_pc,
    output reg                  _pc_sel,
    output wire [31:0]          _formalized_inst,
    output wire                 _rvc
);
localparam OPBRANCH = 7'b1100011,OPJALR = 7'b1100111,OPJAL = 7'b1101111,OPAUIPC=7'b0010111;
wire[6:0] opcode=_inst_in[6:0];
wire[4:0] Cop5={_inst_in[15:13],_inst_in[1:0]};
wire[10:0] CopJalr={_inst_in[15:12],_inst_in[6:0]};
wire[1:0] Ctype=(Cop5==5'b01010|| Cop5==5'b11010 || Cop5==5'b01000 || Cop5==5'b11000)?2'd0:(Cop5==5'b10101 || Cop5==5'b00101 || CopJalr==11'b10000000010 ||CopJalr==11'b10010000010)?2'd1:(Cop5==5'b11001||Cop5==5'b11101)?2'd2:2'd3;
wire[2:0] funct3=_inst_in[14:12];
wire[31:0] br_imm=RVC?{{24{_inst_in[12]}},_inst_in[6:5],_inst_in[2],_inst_in[11:10],_inst_in[4:3],1'b0}:{{20{_inst_in[31]}},_inst_in[31],_inst_in[7],_inst_in[30:25],_inst_in[11:8],1'b0};
wire[31:0] jalr_imm=RVC?{32'b0}:{_inst_in[31:20],20'b0};
wire[31:0] jal_imm=RVC?{{21{_inst_in[12]}},_inst_in[8],_inst_in[10:9],_inst_in[6],_inst_in[7],_inst_in[2],_inst_in[11],_inst_in[5:3],1'b0}:{{12{_inst_in[31]}},_inst_in[19:12],_inst_in[20],_inst_in[30:21],1'b0};
wire[31:0] auipc_imm={_inst_in[31:12],12'b0};
wire jal=opcode==OPJAL || (RVC&&(Cop5==5'b00101 || Cop5==5'b10101));
wire jalr=opcode==OPJALR || (RVC&&(CopJalr==11'b10000000010 ||CopJalr==11'b10010000010));
wire branch=opcode==OPBRANCH || (RVC&&(Cop5==5'b11001 || Cop5==5'b11101));

wire [31:0] _CLS=(Cop5==5'b01010)?{4'b0,_inst_in[3],_inst_in[2],_inst_in[12],_inst_in[6:4],2'b0,5'd2,3'b010,_inst_in[11:7],7'b0000011}:
                 (Cop5==5'b11010)?{4'b0,_inst_in[8],_inst_in[7],_inst_in[12],_inst_in[6:2],5'd2,3'b010,_inst_in[11:9],2'b0,7'b0100011}:
                 (Cop5==5'b01000)?{5'b0,_inst_in[5],_inst_in[12:10],_inst_in[6],2'b0,2'b01,_inst_in[9:7],3'b010,2'b01,_inst_in[4:2],7'b0000011}:
                 (Cop5==5'b11000)?{5'b0,_inst_in[5],_inst_in[12],2'b01,_inst_in[4:2],2'b01,_inst_in[9:7],3'b010,_inst_in[11:10],_inst_in[6],2'b0,7'b0100011}:32'b0;
wire [31:0] _CJ=(Cop5==5'b10101)?{_inst_in[12],_inst_in[8],_inst_in[10:9],_inst_in[6],_inst_in[7],_inst_in[2],_inst_in[11],_inst_in[5:3],_inst_in[12],{8{_inst_in[12]}},5'd0,7'b1101111}:
                (Cop5==5'b00101)?{_inst_in[12],_inst_in[8],_inst_in[10:9],_inst_in[6],_inst_in[7],_inst_in[2],_inst_in[11],_inst_in[5:3],_inst_in[12],{8{_inst_in[12]}},5'd1,7'b1101111}:
                (CopJalr==11'b10000000010)?{12'b0,_inst_in[11:7],3'b0,5'd0,7'b1100111}:
                (CopJalr==11'b10010000010)?{12'b0,_inst_in[11:7],3'b0,5'd1,7'b1100111}:32'b0;
wire [31:0] _CB=(Cop5==5'b11001)?{{4{_inst_in[12]}},_inst_in[6:5],_inst_in[2],5'd0,2'b01,_inst_in[9:7],3'b0,_inst_in[11:10],_inst_in[4:3],_inst_in[12],7'b1100011}:
                (Cop5==5'b11101)?{{4{_inst_in[12]}},_inst_in[6:5],_inst_in[2],5'd0,2'b01,_inst_in[9:7],3'b1,_inst_in[11:10],_inst_in[4:3],_inst_in[12],7'b1100011}:32'b0;
wire [31:0] _CI=(Cop5==5'b01001)?{{7{_inst_in[12]}},_inst_in[6:2],5'd0,3'b0,_inst_in[11:7],7'b0010011}:
                (Cop5==5'b01101 && _inst_in[11:7]!=5'd2 && {{15{_inst_in[12]}},_inst_in[6:2],12'b0}!=31'b0)?{{15{_inst_in[12]}},_inst_in[6:2],_inst_in[11:7],7'b0110111}:
                (Cop5==5'b00001)?{{7{_inst_in[12]}},_inst_in[6:2],_inst_in[11:7],3'b0,_inst_in[11:7],7'b0010011}:
                (Cop5==5'b01101 && {{3{_inst_in[12]}},_inst_in[4:3],_inst_in[5],_inst_in[2],_inst_in[6],4'b0}!=11'b0)?{{3{_inst_in[12]}},_inst_in[4:3],_inst_in[5],_inst_in[2],_inst_in[6],4'b0,5'd2,3'b0,5'd2,7'b0010011}:
                (Cop5==5'b00000 && _inst_in[12:5]!=8'b0)?{2'b0,_inst_in[10],_inst_in[9:7],_inst_in[12:11],_inst_in[5],_inst_in[6],2'b0,5'd2,3'b0,2'b01,_inst_in[4:2],7'b0010011}:
                (Cop5==5'b00010)?{5'b0,1'b1,_inst_in[12],_inst_in[6:2],_inst_in[11:7],3'b001,_inst_in[11:7],7'b0010011}:
                (Cop5==5'b10001 && _inst_in[11:10]==2'b00)?{5'b0,1'b1,_inst_in[12],_inst_in[6:2],2'b01,_inst_in[9:7],3'b101,2'b01,_inst_in[9:7],7'b0010011}:
                (Cop5==5'b10001 && _inst_in[11:10]==2'b01)?{5'd8,1'b1,_inst_in[12],_inst_in[6:2],2'b01,_inst_in[9:7],3'b101,2'b01,_inst_in[9:7],7'b0010011}:
                (Cop5==5'b10001 && _inst_in[11:10]==2'b10)?{{7{_inst_in[12]}},_inst_in[6:2],2'b01,_inst_in[9:7],3'b111,2'b01,_inst_in[9:7],7'b0010011}:
                (Cop5==5'b10010 && _inst_in[12]==1'b0 && _inst_in[6:2]!=5'd0)?{11'b0,_inst_in[6:2],3'b0,_inst_in[11:7],7'b0010011}:
                (Cop5==5'b10010 && _inst_in[12]==1'b1 && _inst_in[11:7]!=5'd0 && _inst_in[6:2]!=5'd0)?{7'b0,_inst_in[11:7],_inst_in[6:2],3'b0,_inst_in[11:7],7'b0110011}:
                (_inst_in[15:10]==6'b100011 && _inst_in[6:5]==2'b11 && _inst_in[1:0]==2'b01)?{7'b0,2'b01,_inst_in[4:2],2'b01,_inst_in[9:7],3'b111,2'b01,_inst_in[9:7],7'b0110011}:
                (_inst_in[15:10]==6'b100011 && _inst_in[6:5]==2'b10 && _inst_in[1:0]==2'b01)?{7'b0,2'b01,_inst_in[4:2],2'b01,_inst_in[9:7],3'b110,2'b01,_inst_in[9:7],7'b0110011}:
                (_inst_in[15:10]==6'b100011 && _inst_in[6:5]==2'b01 && _inst_in[1:0]==2'b01)?{7'b0,2'b01,_inst_in[4:2],2'b01,_inst_in[9:7],3'b100,2'b01,_inst_in[9:7],7'b0110011}:
                (_inst_in[15:10]==6'b100011 && _inst_in[6:5]==2'b00 && _inst_in[1:0]==2'b01)?{7'd32,2'b01,_inst_in[4:2],2'b01,_inst_in[9:7],3'b000,2'b01,_inst_in[9:7],7'b0110011}:32'b0;

wire predict = 1'b1;
wire RVC=_inst_in[1:0]!=2'b11;
assign _rvc=RVC;
wire[3:0] pc_imm=RVC?32'd2:32'd4;
assign _formalized_inst = RVC?((Ctype==2'd0)?_CLS:(Ctype==2'd1)?_CJ:(Ctype==2'd2)?_CB:(Ctype==2'd3)?_CI:_inst_in):_inst_in;
reg[31:0] rob_pc;
wire[31:0] step_pc;
pc_adder adder(
    ._pc(_inst_addr),
    ._imm((!_inst_ready_in?32'd0:jal?jal_imm:jalr?pc_imm:branch?predict?br_imm:pc_imm:pc_imm)),
    .step_pc(step_pc)
);
assign _stall = !_pc_sel && _inst_ready_in && jalr;
assign _next_pc=(_pc_sel)?rob_pc:step_pc;
always @(posedge clk_in) begin
    if(_br_rob) begin
        _pc_sel<=1'b1;
        rob_pc<=_rob_new_pc+_rob_imm;
    end
    else begin
        _pc_sel<=1'b0;
    end
end
endmodule

module pc_adder(
    input wire [31:0] _pc,
    input wire [31:0] _imm,
    output wire [31:0] step_pc
);
assign step_pc= _pc + _imm;
endmodule