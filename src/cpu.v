// RISCV32 CPU top module
// port modification allowed for debugging purposes
`include "units/ALU.v"
`include "units/CDB.v"
`include "units/InstFetcher.v"
`include "units/Decoder.v"
`include "units/Issue.v"
`include "common/fifo/fifo.v"
`include "units/LoadStoreBuffer.v"
`include "units/LoadStoreBufferRS.v"
`include "units/MemControl.v"
`include "units/ReorderBuffer.v"
`include "units/RegisterFile.v"
`include "units/ReservationStation.v"
`include "units/LoadStoreBufferALU.v"

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			    dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

wire _clear;

//CDB
wire _cdb_ready;
wire [4:0]          _cdb_rob_id;
wire [31:0]         _cdb_value;
wire                _cdb_ls_ready;
wire [4:0]          _cdb_ls_rob_id;
wire [31:0]         _cdb_ls_value;


//Mem & Fetcher
wire _inst_ready_in_Mem2Fetcher;
wire [31:0] _inst_in_Mem2Fetcher;
wire _stall_set_Fetcher2Mem;
wire [31:0] _pc_Fetcher2Mem;
wire        _InstFetcher_need_inst;
wire _mem_busy;

//Fetcher & ReservationStation
wire _rs_full_Fetcher2ReservationStation;
wire _rs_ready_ReservationStation2Fetcher;
wire [6:0] _rs_type_ReservationStation2Fetcher;
wire [3:0] _rs_op_ReservationStation2Fetcher;
wire [4:0] _rs_rob_id_ReservationStation2Fetcher;
wire [31:0] _rs_r1_ReservationStation2Fetcher;
wire [31:0] _rs_r2_ReservationStation2Fetcher;
wire [31:0] _rs_imm_ReservationStation2Fetcher;
wire               _rs_has_dep1_ReservationStation2Fetcher;
wire [4:0]         _rs_dep1_ReservationStation2Fetcher;
wire               _rs_has_dep2_ReservationStation2Fetcher;
wire [4:0]         _rs_dep2_ReservationStation2Fetcher;

//Fetcher & LoadStoreBuffer
wire                 _lsb_full_Fetcher2LoadStoreBuffer;
wire                 _lsb_ready_LoadStoreBuffer2Fetcher;
wire [6:0]           _lsb_type_LoadStoreBuffer2Fetcher;
wire [2:0]           _lsb_op_LoadStoreBuffer2Fetcher;
wire [4:0]           _lsb_rob_id_LoadStoreBuffer2Fetcher;

//Fetcher & LoadStoreBufferRS
wire                 _lsb_rs_full_Fetcher2LoadStoreBufferRS;
wire                 _lsb_rs_ready_Fetcher2LoadStoreBufferRS;
wire [6:0]           _lsb_rs_type_Fetcher2LoadStoreBufferRS;
wire [4:0]           _lsb_rs_rob_id_Fetcher2LoadStoreBufferRS;
wire [31:0]          _lsb_rs_r1_Fetcher2LoadStoreBufferRS;
wire [31:0]          _lsb_rs_sv_Fetcher2LoadStoreBufferRS;
wire [31:0]          _lsb_rs_imm_Fetcher2LoadStoreBufferRS;
wire                 _lsb_rs_has_dep1_Fetcher2LoadStoreBufferRS;
wire [4:0]           _lsb_rs_dep1_Fetcher2LoadStoreBufferRS;
wire                 _lsb_rs_has_dep2_Fetcher2LoadStoreBufferRS;
wire [4:0]           _lsb_rs_dep2_Fetcher2LoadStoreBufferRS;

//Fetcher & ROB
wire [4:0] _get_register_status_1_Fetcher2ROB;
wire [4:0] _get_register_status_2_Fetcher2ROB;
wire [4:0]_rob_register_dep_1_Fetcher2ROB;
wire [31:0] _register_value_1_Fetcher2ROB;
wire [4:0]_rob_register_dep_2_Fetcher2ROB;
wire [31:0] _register_value_2_Fetcher2ROB;

wire _rob_full_Fetcher2ROB;
wire [4:0] _rob_tail_id_Fetcher2ROB;
wire _rob_ready_ROB2Fetcher;
wire [6:0] _rob_type_ROB2Fetcher;
wire [31:0] _rob_inst_addr_ROB2Fetcher;
wire [4:0] _rob_rd_ROB2Fetcher;
wire [31:0] _rob_value_ROB2Fetcher;
wire [31:0] _rob_jump_imm_ROB2Fetcher;

wire _br_rob_ROB2Fetcher;
wire [31:0] _rob_new_pc_ROB2Fetcher;
wire [31:0] _rob_imm_ROB2Fetcher;

//ReservationStation & ROB
wire _rob_msg_ready_1_RS2ROB;
wire [4:0] _rob_msg_rob_id_1_RS2ROB;
wire [31:0] _rob_msg_value_1_RS2ROB;
wire _rob_msg_ready_2_RS2ROB;
wire [4:0] _rob_msg_rob_id_2_RS2ROB;
wire [31:0] _rob_msg_value_2_RS2ROB;

//ReservationStation & RegisterFile
wire _rf_msg_ready_RS2RegisterFile;
wire [4:0] _rf_msg_rob_id_RS2RegisterFile;
wire [31:0] _rf_msg_value_RS2RegisterFile;

//ReservationStation & ALU
wire _alu_full_ReservationStation2ALU;
wire _alu_ready_ALU2ReservationStation;
wire [4:0] _alu_rob_id_ALU2ReservationStation;
wire [6:0] _alu_type_ALU2ReservationStation;
wire [3:0] _alu_op_ALU2ReservationStation;
wire [31:0] _alu_v1_ALU2ReservationStation;
wire [31:0] _alu_v2_ALU2ReservationStation;

//ROB & MEN
wire _stall_recover_ROB2Mem;

//ROB & RegisterFile
wire _rf_launch_ready_ROB2RegisterFile;
wire [4:0] _rf_launch_rob_id_ROB2RegisterFile;
wire [4:0] _rf_launch_register_id_ROB2RegisterFile;
wire _rf_commit_ready_ROB2RegisterFile;
wire [4:0] _rf_commit_rob_id_ROB2RegisterFile;
wire [4:0] _rf_commit_register_id_ROB2RegisterFile;
wire [31:0] _rf_commit_value_ROB2RegisterFile;
//launch后下一个周期改dependency
//transmit
wire [4:0] _ask_rd_1_ROB2RegisterFile;
wire [4:0] _ask_rd_2_ROB2RegisterFile;
wire [4:0] _dep_rd_1_ROB2RegisterFile;
wire [4:0] _dep_rd_2_ROB2RegisterFile;
wire [31:0] _dep_value_1_ROB2RegisterFile;
wire [31:0] _dep_value_2_ROB2RegisterFile;

//Store Control
wire _store_ready_ROB2LSB;

//LoadStoreBufferRS & LoadStoreBuffer
wire _lsb_rs_ready_LoadStoreBuffer2LoadStoreBufferRS;
wire [4:0] _lsb_rob_id_LoadStoreBuffer2LoadStoreBufferRS;
wire [31:0] _lsb_st_value_LoadStoreBuffer2LoadStoreBufferRS;
wire [31:0] _lsb_ptr_value_LoadStoreBuffer2LoadStoreBufferRS;

//LoadStoreBufferRS & ROB
wire _rob_msg_ready_1_LSRS2ROB;
wire [4:0] _rob_msg_rob_id_1_LSRS2ROB;
wire [31:0] _rob_msg_value_1_LSRS2ROB;
wire _rob_msg_ready_2_LSRS2ROB;
wire [4:0] _rob_msg_rob_id_2_LSRS2ROB;
wire [31:0] _rob_msg_value_2_LSRS2ROB;

// LoadStoreBufferRS & RegisterFile
// use the same as ReservationStation & RegisterFile

//LoadStoreBuffer & Mem
wire [1:0] _work_type;
wire _lsb_mem_ready_LoadStoreBuffer2Mem;
wire _r_nw_in_LoadStoreBuffer2Mem;
wire [31:0] _addr_LoadStoreBuffer2Mem;
wire [31:0] _data_in_LoadStoreBuffer2Mem;
wire _lsb_mem_ready_Mem2LoadStoreBuffer;
wire [31:0] _data_out_Mem2LoadStoreBuffer;

MemControl MEM(
  .clk_in(clk_in),
  .rst_in(rst_in),
  .rdy_in(rdy_in),
  .mem_din(mem_din),
  .mem_dout(mem_dout),
  .mem_a(mem_a),
  .mem_wr(mem_wr),
  .io_buffer_full(io_buffer_full),
  ._mem_busy(_mem_busy),
  ._clear(_clear),
  ._inst_ready_in_Mem2Fetcher(_inst_ready_in_Mem2Fetcher),
  ._inst_in_Mem2Fetcher(_inst_in_Mem2Fetcher),
  ._pc_Fetcher2Mem(_pc_Fetcher2Mem),
  ._stall_set(_stall_set_Fetcher2Mem),
  ._InstFetcher_need_inst(_InstFetcher_need_inst),
  ._stall_recover(_stall_recover_ROB2Mem),
  ._work_type(_work_type),
  ._lsb_mem_ready_LoadStoreBuffer2Mem(_lsb_mem_ready_LoadStoreBuffer2Mem),
  ._r_nw_in_LoadStoreBuffer2Mem(_r_nw_in_LoadStoreBuffer2Mem),
  ._addr_LoadStoreBuffer2Mem(_addr_LoadStoreBuffer2Mem),
  ._data_in_LoadStoreBuffer2Mem(_data_in_LoadStoreBuffer2Mem),
  ._lsb_mem_ready_Mem2LoadStoreBuffer(_lsb_mem_ready_Mem2LoadStoreBuffer),
  ._data_out_Mem2LoadStoreBuffer(_data_out_Mem2LoadStoreBuffer)
);

InstFetcher Fetcher(
  .clk_in(clk_in),
  .rst_in(rst_in),
  .rdy_in(rdy_in),
  ._clear(_clear),
  ._stall(_stall_set_Fetcher2Mem),
  ._mem_busy(_mem_busy),
  ._inst_ready_in(_inst_ready_in_Mem2Fetcher),
  ._inst_in(_inst_in_Mem2Fetcher),
  ._InstFetcher_need_inst(_InstFetcher_need_inst),
  ._next_pc(_pc_Fetcher2Mem),
  ._br_rob(_br_rob_ROB2Fetcher),
  ._rob_new_pc(_rob_new_pc_ROB2Fetcher),
  ._rob_imm(_rob_imm_ROB2Fetcher),
  ._get_register_status_1(_get_register_status_1_Fetcher2ROB),
  ._get_register_status_2(_get_register_status_2_Fetcher2ROB),
  ._rob_register_dep_1(_rob_register_dep_1_Fetcher2ROB),
  ._rob_register_value_1(_register_value_1_Fetcher2ROB),
  ._rob_register_dep_2(_rob_register_dep_2_Fetcher2ROB),
  ._rob_register_value_2(_register_value_2_Fetcher2ROB),
  ._rob_full(_rob_full_Fetcher2ROB),
  ._rob_tail_id(_rob_tail_id_Fetcher2ROB),
  ._rob_ready(_rob_ready_ROB2Fetcher),
  ._rob_type(_rob_type_ROB2Fetcher),
  ._rob_inst_addr(_rob_inst_addr_ROB2Fetcher),
  ._rob_rd(_rob_rd_ROB2Fetcher),
  ._rob_value(_rob_value_ROB2Fetcher),
  ._rob_jump_imm(_rob_jump_imm_ROB2Fetcher),
  ._rs_full(_rs_full_Fetcher2ReservationStation),
  ._rs_ready(_rs_ready_ReservationStation2Fetcher),
  ._rs_type(_rs_type_ReservationStation2Fetcher),
  ._rs_op(_rs_op_ReservationStation2Fetcher),
  ._rs_rob_id(_rs_rob_id_ReservationStation2Fetcher),
  ._rs_r1(_rs_r1_ReservationStation2Fetcher),
  ._rs_r2(_rs_r2_ReservationStation2Fetcher),
  ._rs_imm(_rs_imm_ReservationStation2Fetcher),
  ._rs_has_dep1(_rs_has_dep1_ReservationStation2Fetcher),
  ._rs_dep1(_rs_dep1_ReservationStation2Fetcher),
  ._rs_has_dep2(_rs_has_dep2_ReservationStation2Fetcher),
  ._rs_dep2(_rs_dep2_ReservationStation2Fetcher),
  ._lsb_full(_lsb_full_Fetcher2LoadStoreBuffer),
  ._lsb_ready(_lsb_ready_LoadStoreBuffer2Fetcher),
  ._lsb_type(_lsb_type_LoadStoreBuffer2Fetcher),
  ._lsb_op(_lsb_op_LoadStoreBuffer2Fetcher),
  ._lsb_rob_id(_lsb_rob_id_LoadStoreBuffer2Fetcher),
  ._lsb_rs_full(_lsb_rs_full_Fetcher2LoadStoreBufferRS),
  ._lsb_rs_ready(_lsb_rs_ready_Fetcher2LoadStoreBufferRS),
  ._lsb_rs_type(_lsb_rs_type_Fetcher2LoadStoreBufferRS),
  ._lsb_rs_rob_id(_lsb_rs_rob_id_Fetcher2LoadStoreBufferRS),
  ._lsb_rs_r1(_lsb_rs_r1_Fetcher2LoadStoreBufferRS),
  ._lsb_rs_sv(_lsb_rs_sv_Fetcher2LoadStoreBufferRS),
  ._lsb_rs_imm(_lsb_rs_imm_Fetcher2LoadStoreBufferRS),
  ._lsb_rs_has_dep1(_lsb_rs_has_dep1_Fetcher2LoadStoreBufferRS),
  ._lsb_rs_dep1(_lsb_rs_dep1_Fetcher2LoadStoreBufferRS),
  ._lsb_rs_has_dep2(_lsb_rs_has_dep2_Fetcher2LoadStoreBufferRS),
  ._lsb_rs_dep2(_lsb_rs_dep2_Fetcher2LoadStoreBufferRS)
);

ReservationStation RS(
  .clk_in(clk_in),
  .rst_in(rst_in),
  .rdy_in(rdy_in),
  ._clear(_clear),
  ._rs_ready(_rs_ready_ReservationStation2Fetcher),
  ._rs_type(_rs_type_ReservationStation2Fetcher),
  ._rs_op(_rs_op_ReservationStation2Fetcher),
  ._rs_rob_id(_rs_rob_id_ReservationStation2Fetcher),
  ._rs_r1(_rs_r1_ReservationStation2Fetcher),
  ._rs_r2(_rs_r2_ReservationStation2Fetcher),
  ._rs_imm(_rs_imm_ReservationStation2Fetcher),
  ._rs_has_dep1(_rs_has_dep1_ReservationStation2Fetcher),
  ._rs_dep1(_rs_dep1_ReservationStation2Fetcher),
  ._rs_has_dep2(_rs_has_dep2_ReservationStation2Fetcher),
  ._rs_dep2(_rs_dep2_ReservationStation2Fetcher),
  ._rs_full(_rs_full_Fetcher2ReservationStation),
  ._cdb_ready(_cdb_ready),
  ._cdb_rob_id(_cdb_rob_id),
  ._cdb_value(_cdb_value),
  ._cdb_ls_ready(_cdb_ls_ready),
  ._cdb_ls_rob_id(_cdb_ls_rob_id),
  ._cdb_ls_value(_cdb_ls_value),
  ._rob_msg_ready_1(_rob_msg_ready_1_RS2ROB),
  ._rob_msg_rob_id_1(_rob_msg_rob_id_1_RS2ROB),
  ._rob_msg_value_1(_rob_msg_value_1_RS2ROB),
  ._rob_msg_ready_2(_rob_msg_ready_2_RS2ROB),
  ._rob_msg_rob_id_2(_rob_msg_rob_id_2_RS2ROB),
  ._rob_msg_value_2(_rob_msg_value_2_RS2ROB),
  ._rf_msg_ready(_rf_msg_ready_RS2RegisterFile),
  ._rf_msg_rob_id(_rf_msg_rob_id_RS2RegisterFile),
  ._rf_msg_value(_rf_msg_value_RS2RegisterFile),
  ._alu_full(_alu_full_ReservationStation2ALU),
  ._alu_ready(_alu_ready_ALU2ReservationStation),
  ._alu_rob_id(_alu_rob_id_ALU2ReservationStation),
  ._alu_type(_alu_type_ALU2ReservationStation),
  ._alu_op(_alu_op_ALU2ReservationStation),
  ._alu_v1(_alu_v1_ALU2ReservationStation),
  ._alu_v2(_alu_v2_ALU2ReservationStation)
);

ALU CommonALU(
  .clk_in(clk_in),
  .rst_in(rst_in),
  .rdy_in(rdy_in),
  ._clear(_clear),
  ._alu_ready(_alu_ready_ALU2ReservationStation),
  ._alu_rob_id(_alu_rob_id_ALU2ReservationStation),
  ._alu_type(_alu_type_ALU2ReservationStation),
  ._alu_op(_alu_op_ALU2ReservationStation),
  ._alu_v1(_alu_v1_ALU2ReservationStation),
  ._alu_v2(_alu_v2_ALU2ReservationStation),
  ._alu_full(_alu_full_ReservationStation2ALU),
  ._cdb_ready(_cdb_ready),
  ._cdb_rob_id(_cdb_rob_id),
  ._cdb_value(_cdb_value)
);

LoadStoreBufferRS LSRS(
  .clk_in(clk_in),
  .rst_in(rst_in),
  .rdy_in(rdy_in),
  ._clear(_clear),
  ._rs_ready(_lsb_rs_ready_Fetcher2LoadStoreBufferRS),
  ._rs_type(_lsb_rs_type_Fetcher2LoadStoreBufferRS),
  ._rs_rob_id(_lsb_rs_rob_id_Fetcher2LoadStoreBufferRS),
  ._rs_r1(_lsb_rs_r1_Fetcher2LoadStoreBufferRS),
  ._rs_sv(_lsb_rs_sv_Fetcher2LoadStoreBufferRS),
  ._rs_imm(_lsb_rs_imm_Fetcher2LoadStoreBufferRS),
  ._rs_has_dep1(_lsb_rs_has_dep1_Fetcher2LoadStoreBufferRS),
  ._rs_dep1(_lsb_rs_dep1_Fetcher2LoadStoreBufferRS),
  ._rs_has_dep2(_lsb_rs_has_dep2_Fetcher2LoadStoreBufferRS),
  ._rs_dep2(_lsb_rs_dep2_Fetcher2LoadStoreBufferRS),
  ._rs_full(_lsb_rs_full_Fetcher2LoadStoreBufferRS),
  ._cdb_ready(_cdb_ready),
  ._cdb_rob_id(_cdb_rob_id),
  ._cdb_value(_cdb_value),
  ._cdb_ls_ready(_cdb_ls_ready),
  ._cdb_ls_rob_id(_cdb_ls_rob_id),
  ._cdb_ls_value(_cdb_ls_value),
  ._rob_msg_ready_1(_rob_msg_ready_1_LSRS2ROB),
  ._rob_msg_rob_id_1(_rob_msg_rob_id_1_LSRS2ROB),
  ._rob_msg_value_1(_rob_msg_value_1_LSRS2ROB),
  ._rob_msg_ready_2(_rob_msg_ready_2_LSRS2ROB),
  ._rob_msg_rob_id_2(_rob_msg_rob_id_2_LSRS2ROB),
  ._rob_msg_value_2(_rob_msg_value_2_LSRS2ROB),
  ._rf_msg_ready(_rf_msg_ready_RS2RegisterFile),
  ._rf_msg_rob_id(_rf_msg_rob_id_RS2RegisterFile),
  ._rf_msg_value(_rf_msg_value_RS2RegisterFile),
  ._lsb_rs_ready(_lsb_rs_ready_LoadStoreBuffer2LoadStoreBufferRS),
  ._lsb_rob_id(_lsb_rob_id_LoadStoreBuffer2LoadStoreBufferRS),
  ._lsb_st_value(_lsb_st_value_LoadStoreBuffer2LoadStoreBufferRS),
  ._lsb_ptr_value(_lsb_ptr_value_LoadStoreBuffer2LoadStoreBufferRS)
);

LoadStoreBuffer LSB(
  .clk_in(clk_in),
  .rst_in(rst_in),
  .rdy_in(rdy_in),
  ._clear(_clear),
  ._ls_ready(_lsb_ready_LoadStoreBuffer2Fetcher),
  ._ls_type(_lsb_type_LoadStoreBuffer2Fetcher),
  ._ls_op(_lsb_op_LoadStoreBuffer2Fetcher),
  ._ls_rob_id(_lsb_rob_id_LoadStoreBuffer2Fetcher),
  ._ls_full(_lsb_full_Fetcher2LoadStoreBuffer),
  ._lsb_rs_ready(_lsb_rs_ready_LoadStoreBuffer2LoadStoreBufferRS),
  ._lsb_rs_rob_id(_lsb_rob_id_LoadStoreBuffer2LoadStoreBufferRS),
  ._lsb_rs_st_value(_lsb_st_value_LoadStoreBuffer2LoadStoreBufferRS),
  ._lsb_rs_ptr_value(_lsb_ptr_value_LoadStoreBuffer2LoadStoreBufferRS),
  ._work_type(_work_type),
  ._lsb_mem_ready(_lsb_mem_ready_LoadStoreBuffer2Mem),
  ._r_nw_in(_r_nw_in_LoadStoreBuffer2Mem),
  ._addr(_addr_LoadStoreBuffer2Mem),
  ._data_in(_data_in_LoadStoreBuffer2Mem),
  ._mem_busy(_mem_busy),
  ._mem_lsb_ready(_lsb_mem_ready_Mem2LoadStoreBuffer),
  ._data_out(_data_out_Mem2LoadStoreBuffer),
  ._lsb_cdb_ready(_cdb_ls_ready),
  ._lsb_cdb_rob_id(_cdb_ls_rob_id),
  ._lsb_cdb_value(_cdb_ls_value)
);

ReorderBuffer ROB(
  .clk_in(clk_in),
  .rst_in(rst_in),
  .rdy_in(rdy_in),
  ._clear(_clear),
  ._stall(_stall_recover_ROB2Mem),
  ._get_register_status_1(_get_register_status_1_Fetcher2ROB),
  ._get_register_status_2(_get_register_status_2_Fetcher2ROB),
  ._register_dep_1(_rob_register_dep_1_Fetcher2ROB),
  ._register_value_1(_register_value_1_Fetcher2ROB),
  ._register_dep_2(_rob_register_dep_2_Fetcher2ROB),
  ._register_value_2(_register_value_2_Fetcher2ROB),
  ._rob_ready(_rob_ready_ROB2Fetcher),
  ._rob_type(_rob_type_ROB2Fetcher),
  ._rob_inst_addr(_rob_inst_addr_ROB2Fetcher),
  ._rob_rd(_rob_rd_ROB2Fetcher),
  ._rob_value(_rob_value_ROB2Fetcher),
  ._rob_jump_imm(_rob_jump_imm_ROB2Fetcher),
  ._rob_full(_rob_full_Fetcher2ROB),
  ._rob_tail_id(_rob_tail_id_Fetcher2ROB),
  ._br_rob(_br_rob_ROB2Fetcher),
  ._rob_new_pc(_rob_new_pc_ROB2Fetcher),
  ._rob_imm(_rob_imm_ROB2Fetcher),
  ._rob_msg_ready_1(_rob_msg_ready_1_RS2ROB),
  ._rob_msg_rob_id_1(_rob_msg_rob_id_1_RS2ROB),
  ._rob_msg_value_1(_rob_msg_value_1_RS2ROB),
  ._rob_msg_ready_2(_rob_msg_ready_2_RS2ROB),
  ._rob_msg_rob_id_2(_rob_msg_rob_id_2_RS2ROB),
  ._rob_msg_value_2(_rob_msg_value_2_RS2ROB),
  ._cdb_ready(_cdb_ready),
  ._cdb_rob_id(_cdb_rob_id),
  ._cdb_value(_cdb_value),
  ._cdb_ls_ready(_cdb_ls_ready),
  ._cdb_ls_rob_id(_cdb_ls_rob_id),
  ._cdb_ls_value(_cdb_ls_value),
  ._rf_launch_ready(_rf_launch_ready_ROB2RegisterFile),
  ._rf_launch_rob_id(_rf_launch_rob_id_ROB2RegisterFile),
  ._rf_launch_register_id(_rf_launch_register_id_ROB2RegisterFile),
  ._rf_commit_ready(_rf_commit_ready_ROB2RegisterFile),
  ._rf_commit_rob_id(_rf_commit_rob_id_ROB2RegisterFile),
  ._rf_commit_register_id(_rf_commit_register_id_ROB2RegisterFile),
  ._rf_commit_value(_rf_commit_value_ROB2RegisterFile),
  ._ask_rd_1(_ask_rd_1_ROB2RegisterFile),
  ._ask_rd_2(_ask_rd_2_ROB2RegisterFile),
  ._dep_rd_1(_dep_rd_1_ROB2RegisterFile),
  ._dep_rd_2(_dep_rd_2_ROB2RegisterFile),
  ._dep_value_1(_dep_value_1_ROB2RegisterFile),
  ._dep_value_2(_dep_value_2_ROB2RegisterFile),
  ._store_ready(_store_ready_ROB2LSB)
);

RegisterFile RF(
  .clk_in(clk_in),
  .rst_in(rst_in),
  .rdy_in(rdy_in),
  ._rob_launch_ready(_rf_launch_ready_ROB2RegisterFile),
  ._rob_launch_rob_id(_rf_launch_rob_id_ROB2RegisterFile),
  ._rob_launch_register_id(_rf_launch_register_id_ROB2RegisterFile),
  ._rob_commit_ready(_rf_commit_ready_ROB2RegisterFile),
  ._rob_commit_rob_id(_rf_commit_rob_id_ROB2RegisterFile),
  ._rob_commit_register_id(_rf_commit_register_id_ROB2RegisterFile),
  ._rob_commit_value(_rf_commit_value_ROB2RegisterFile),
  ._ask_rd_1(_ask_rd_1_ROB2RegisterFile),
  ._ask_rd_2(_ask_rd_2_ROB2RegisterFile),
  ._dep_rd_1(_dep_rd_1_ROB2RegisterFile),
  ._dep_rd_2(_dep_rd_2_ROB2RegisterFile),
  ._dep_value_1(_dep_value_1_ROB2RegisterFile),
  ._dep_value_2(_dep_value_2_ROB2RegisterFile),
  ._rf_msg_ready(_rf_msg_ready_RS2RegisterFile),
  ._rf_msg_rob_id(_rf_msg_rob_id_RS2RegisterFile),
  ._rf_msg_value(_rf_msg_value_RS2RegisterFile)
);

endmodule