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
    output  wire                _rob_msg_ready_1,
    output  wire [4:0]          _rob_msg_rob_id_1,
    output  wire [31:0]         _rob_msg_value_1,
    output  wire                _rob_msg_ready_2,
    output  wire [4:0]          _rob_msg_rob_id_2,
    output  wire [31:0]         _rob_msg_value_2,

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
endmodule