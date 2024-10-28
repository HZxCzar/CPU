module ReservationStation(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low
    
    input  wire                 _clear,

    // InstFetcher inputs
    input wire                 _rs_ready,
    input wire [4:0]           _rs_type,
    input wire [4:0]         _rs_rob_id,
    input wire [31:0]          _rs_r1,
    input wire [31:0]           _rs_r2,
    input wire [31:0]           _rs_imm,
    input wire               _rs_has_dep1,
    input wire [4:0]         _rs_dep1,
    input wire               _rs_has_dep2,
    input wire [4:0]         _rs_dep2,
    // InstFetcher outputs
    output wire              _rs_full,

    //CDB inputs
    input wire                _cdb_ready,
    input wire [4:0]          _cdb_rob_id,
    input wire [31:0]         _cdb_value,
    input wire                _cdb_ls_ready,
    input wire [4:0]          _cdb_ls_rob_id,
    input wire [31:0]         _cdb_ls_value,

    //ROB inputs
    input  wire                 _rob_msg_ready_1,
    input  wire [4:0]           _rob_msg_rob_id_1,
    input  wire [31:0]          _rob_msg_value_1,
    input  wire                 _rob_msg_ready_2,
    input  wire [4:0]           _rob_msg_rob_id_2,
    input  wire [31:0]          _rob_msg_value_2,

    //RegisterFile inputs
    input  wire                 _rf_msg_ready,
    input  wire [4:0]           _rf_msg_rob_id,
    input  wire [31:0]          _rf_msg_value,

    //ALU inputs
    input wire          _alu_full,
    //ALU outputs
    output wire          _alu_ready,
    output wire [4:0]    _alu_rob_id,
    output wire [31:0]   _alu_value
);
endmodule