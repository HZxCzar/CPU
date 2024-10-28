module Decoder(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low
    
    // InstFetcher inputs
    input  wire                 _clear,
    input  wire                 _stall,
    input  wire [31:0]          _inst_in,
    input  wire                 _inst_ready_in,
    input  wire [31:0]          _inst_addr,
    // InstFetcher outputs
    output wire [31:0]          _next_pc
    // output wire                 _inst_decode_ready,
    // output wire [31:0]          _inst_decode_addr,
    // output wire [4:0]           _inst_type,
    // output wire [4:0]           _inst_rd,
    // output wire [4:0]           _inst_rs1,
    // output wire [4:0]           _inst_rs2,
    // output wire [31:0]          _inst_imm

    // //RegisterFile outputs
    // output wire [4:0]           _get_register_id_dependency_1,
    // output wire [4:0]           _get_register_id_dependency_2,
    // //RegisterFile inputs
    // input wire                  _register_id_has_dependency_1,
    // input wire [4:0]            _register_id_dependency_1,
    // input wire [31:0]           _register_value_1,
    // input wire                  _register_id_has_dependency_2,
    // input wire [4:0]            _register_id_dependency_2,
    // input wire [31:0]           _register_value_2,

    // //ROB outputs with dependencies
    // output wire [4:0]           _get_register_status_1,
    // output wire [4:0]           _get_register_status_2,
    // //ROB inputs with dependencies
    // input wire                  _rob_register_ready_1,
    // input wire [31:0]           _rob_register_value_1,
    // input wire                  _rob_register_ready_2,
    // input wire [31:0]           _rob_register_value_2,

    // //ROB inputs
    // input  wire                 _rob_full,
    // input  wire [4:0]           _rob_tail_id,
    // //ROB outputs
    // output reg                  _rob_ready,
    // output reg [4:0]            _rob_type,
    // output wire [31:0]          _rob_inst_addr,
    // output reg [4:0]            _rob_rd,
    // output reg [31:0]           _rob_value,


    // //ReservationStation inputs
    // input  wire                 _rs_full,
    // //ReservationStation outputs
    // output reg                 _rs_ready,
    // output reg [4:0]           _rs_type,
    // output wire [4:0]         _rs_rob_id,
    // output wire [31:0]          _rs_r1,
    // output wire [31:0]           _rs_r2,
    // output wire [31:0]           _rs_imm,
    // output wire               _rs_has_dep1,
    // output wire [4:0]         _rs_dep1,
    // output wire               _rs_has_dep2,
    // output wire [4:0]         _rs_dep2,

    // //LoadStoreBuffer inputs
    // input  wire                 _lsb_full,
    // //LoadStoreBuffer outputs
    // output wire                 _lsb_ready,
    // output wire [4:0]           _lsb_type,
    // output wire [4:0]           _lsb_rob_id,

    // //LoadStoreBufferRS inputs
    // input  wire                 _lsb_rs_full,
    // //LoadStoreBufferRS outputs
    // output reg                 _lsb_rs_ready,
    // output reg [4:0]        _lsb_rs_type,
    // output wire [4:0]         _lsb_rs_rob_id,
    // output wire [31:0]          _lsb_rs_r1,
    // output wire [31:0]          _lsb_rs_sv,
    // output wire [31:0]        _lsb_rs_imm,
    // output wire               _lsb_rs_has_dep1,
    // output wire [4:0]         _lsb_rs_dep1,
    // output wire               _lsb_rs_has_dep2,
    // output wire [4:0]         _lsb_rs_dep2
);
endmodule