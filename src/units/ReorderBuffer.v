module ReorderBuffer(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low
    
    output  wire                _clear,
    output  wire                _stall,

    //from InstFetcher
    //Decoder inputs with dependencies
    input wire [4:0]            _get_register_status_1,
    input wire [4:0]            _get_register_status_2,
    //Decoder outputs with dependencies
    output wire                 _register_ready_1,
    output wire [31:0]          _register_value_1,
    output wire                 _register_ready_2,
    output wire [31:0]          _register_value_2,
    //Decoder inputs
    input wire                  _rob_ready,
    input wire [4:0]            _rob_type,
    input wire [31:0]           _rob_inst_addr,
    input wire [4:0]            _rob_rd,
    input wire [31:0]           _rob_value,
    input wire [31:0]           _rob_jump_imm,
    //Decoder outputs
    output  wire                _rob_full,
    output  wire [4:0]          _rob_tail_id,
    //setPC
    output  wire                _br_rob,
    output  wire [31:0]         _rob_new_pc,

    //from ReservationStation
    //ReservationStation outputs
    output  reg                _rob_msg_ready_1,
    output  reg [4:0]          _rob_msg_rob_id_1,
    output  reg [31:0]         _rob_msg_value_1,
    output  reg                _rob_msg_ready_2,
    output  reg [4:0]          _rob_msg_rob_id_2,
    output  reg [31:0]         _rob_msg_value_2,

    //CDB inputs
    input  wire                 _cdb_ready,
    input  wire [4:0]           _cdb_rob_id,
    input  wire [31:0]          _cdb_value,
    input  wire                 _cdb_ls_ready,
    input  wire [4:0]           _cdb_ls_rob_id,
    input  wire [31:0]          _cdb_ls_value,

    //RegisterFile outputs with launch
    output wire                 _rf_launch_ready,
    output wire [4:0]           _rf_launch_rob_id,
    output wire [4:0]           _rf_launch_register_id,
    //RegisterFile outputs with commit
    output wire                 _rf_commit_ready,
    output wire [4:0]           _rf_commit_rob_id,
    output wire [4:0]           _rf_commit_register_id,
    output wire [31:0]          _rf_commit_value
);
//编号从1开始
//特判lui
reg [4:0] head,tail,size;
reg busy[1:31];
reg[4:0] rob_type[1:31];
reg[31:0] inst_addr[1:31];
reg[4:0] rob_rd[1:31];
reg[31:0] rob_value[1:31];
reg[31:0] rob_jump_imm[1:31];
reg[1:0] rob_status[1:31];
assign _register_ready_1=rob_status[_get_register_status_1]==2;
assign _register_value_1=rob_value[_get_register_status_1];
assign _register_ready_2=rob_status[_get_register_status_2]==2;
assign _register_value_2=rob_value[_get_register_status_2];

assign _rob_full=size==31;
assign _rob_tail_id=tail;

wire has_rd=(_rob_type==7'b0110011||_rob_type==7'b0010011||_rob_type==7'b0000011||_rob_type==7'b1101111||_rob_type==7'b1100111||_rob_type==7'b0010111||_rob_type==7'b0110111);
assign _rf_launch_ready=_rob_ready && has_rd;
assign _rf_launch_rob_id=tail;
assign _rf_launch_register_id=_rob_rd;
endmodule