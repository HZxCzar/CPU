// `include "Decoder.v"
// `include "Issue.v"

module InstFetcher(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low
    
    input  wire                 _clear,
    output  wire                _stall,

    //Mem
    // input  wire                  _mem_busy,
    input  wire                  _inst_ready_in,
    input  wire [31:0]           _inst_in,
    output wire                  _InstFetcher_need_inst,
    output wire [31:0]           _next_pc,

    //ROB Branch
    input  wire                 _br_rob,
    input  wire [31:0]          _rob_new_pc,
    input  wire [31:0]          _rob_imm,

    //ROB outputs with dependencies
    output wire [4:0]           _get_register_status_1,
    output wire [4:0]           _get_register_status_2,
    //ROB inputs with dependencies
    // input wire [4:0]            _rob_register_dep_1,
    // input wire [31:0]           _rob_register_value_1,
    // input wire [4:0]            _rob_register_dep_2,
    // input wire [31:0]           _rob_register_value_2,

    //ROB inputs
    input  wire                 _rob_full,
    input  wire [4:0]           _rob_tail_id,
    //ROB outputs
    output wire                 _rob_ready,
    output wire [6:0]           _rob_type,
    output wire [31:0]          _rob_inst_addr,
    output wire [4:0]           _rob_rd,
    output wire [31:0]          _rob_value,
    output wire [31:0]          _rob_jump_imm,
    output wire                 _rvc_rob,

    //ReservationStation inputs
    input  wire                 _rs_full,
    //ReservationStation outputs
    output wire                 _rs_ready,
    output wire [6:0]           _rs_type,
    output wire [3:0]           _rs_op,
    output wire [4:0]           _rs_rob_id,
    output wire                  _rs_need_1,
    output wire                  _rs_need_2,
    output wire [31:0]           _rs_r1_addr,
    output wire [31:0]          _rs_imm,
    // output wire [31:0]          _rs_r1,
    // output wire [31:0]          _rs_r2,
    // output wire [31:0]          _rs_imm,
    // output wire                 _rs_has_dep1,
    // output wire [4:0]           _rs_dep1,
    // output wire                 _rs_has_dep2,
    // output wire [4:0]           _rs_dep2,

    //LoadStoreBuffer inputs
    input  wire                 _lsb_full,
    //LoadStoreBuffer outputs
    output wire                 _lsb_ready,
    output wire [6:0]           _lsb_type,
    output wire [2:0]           _lsb_op,
    output wire [4:0]           _lsb_rob_id,

    //LoadStoreBufferRS inputs
    input  wire                 _lsb_rs_full,
    //LoadStoreBufferRS outputs
    output wire                 _lsb_rs_ready,
    output wire [6:0]           _lsb_rs_type,
    output wire [4:0]           _lsb_rs_rob_id,
    output wire                  _lsb_rs_need_1,
    output wire                  _lsb_rs_need_2,
    output wire [31:0]          _lsb_rs_imm
    // output wire [31:0]          _lsb_rs_r1,
    // output wire [31:0]          _lsb_rs_sv,
    // output wire [31:0]          _lsb_rs_imm,
    // output wire                 _lsb_rs_has_dep1,
    // output wire [4:0]           _lsb_rs_dep1,
    // output wire                 _lsb_rs_has_dep2,
    // output wire [4:0]           _lsb_rs_dep2
);
reg[31:0] _pc;
wire _pc_sel;
wire _queue_not_full;
reg [31:0] _jalr_rd;
wire[31:0] _formalized_inst;
wire _rvc;
Decoder dc(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    ._br_rob(_br_rob),
    ._rob_new_pc(_rob_new_pc),
    ._rob_imm(_rob_imm),
    ._clear(_clear),
    ._stall(_stall),
    ._inst_in(_inst_in),
    ._inst_ready_in(_inst_ready_in),
    ._inst_addr(_pc),
    ._next_pc(_next_pc),
    ._pc_sel(_pc_sel),
    ._formalized_inst(_formalized_inst),
    ._rvc(_rvc)
);

Issue launcher(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    ._clear(_clear),
    ._pc_sel(_pc_sel),
    ._inst_in(_formalized_inst),
    ._inst_ready_in(_inst_ready_in),
    ._inst_addr(_pc),
    ._jalr_rd(_jalr_rd),
    ._rvc(_rvc),
    ._InstFetcher_need_inst(_queue_not_full),
    ._get_register_status_1(_get_register_status_1),
    ._get_register_status_2(_get_register_status_2),
    // ._rob_register_dep_1(_rob_register_dep_1),
    // ._rob_register_value_1(_rob_register_value_1),
    // ._rob_register_dep_2(_rob_register_dep_2),
    // ._rob_register_value_2(_rob_register_value_2),
    ._rob_full(_rob_full),
    ._rob_tail_id(_rob_tail_id),
    ._rob_ready(_rob_ready),
    ._rob_type(_rob_type),
    ._rob_inst_addr(_rob_inst_addr),
    ._rob_rd(_rob_rd),
    ._rob_value(_rob_value),
    ._rob_jump_imm(_rob_jump_imm),
    ._rvc_rob(_rvc_rob),
    ._rs_full(_rs_full),
    ._rs_ready(_rs_ready),
    ._rs_type(_rs_type),
    ._rs_op(_rs_op),
    ._rs_rob_id(_rs_rob_id),
    // ._rs_r1(_rs_r1),
    // ._rs_r2(_rs_r2),
    ._rs_need_1(_rs_need_1),
    ._rs_need_2(_rs_need_2),
    ._rs_r1_addr(_rs_r1_addr),
    ._rs_imm(_rs_imm),
    // ._rs_has_dep1(_rs_has_dep1),
    // ._rs_dep1(_rs_dep1),
    // ._rs_has_dep2(_rs_has_dep2),
    // ._rs_dep2(_rs_dep2),
    ._lsb_full(_lsb_full),
    ._lsb_ready(_lsb_ready),
    ._lsb_type(_lsb_type),
    ._lsb_op(_lsb_op),
    ._lsb_rob_id(_lsb_rob_id),
    ._lsb_rs_full(_lsb_rs_full),
    ._lsb_rs_ready(_lsb_rs_ready),
    ._lsb_rs_type(_lsb_rs_type),
    ._lsb_rs_rob_id(_lsb_rs_rob_id),
    // ._lsb_rs_r1(_lsb_rs_r1),
    // ._lsb_rs_sv(_lsb_rs_sv),
    ._lsb_rs_need_1(_lsb_rs_need_1),
    ._lsb_rs_need_2(_lsb_rs_need_2),
    ._lsb_rs_imm(_lsb_rs_imm)
    // ._lsb_rs_has_dep1(_lsb_rs_has_dep1),
    // ._lsb_rs_dep1(_lsb_rs_dep1),
    // ._lsb_rs_has_dep2(_lsb_rs_has_dep2),
    // ._lsb_rs_dep2(_lsb_rs_dep2)
);

always @(posedge clk_in) begin
    if(rst_in) begin
        _jalr_rd <= 0;
        _pc <= 0;
    end else if(rdy_in)begin
        if(_stall) begin
            _jalr_rd <= _next_pc;
        end else begin
            _pc<=_next_pc;
        end
    end
end

assign _InstFetcher_need_inst = _queue_not_full ; //!_stall && !_mem_busy;
// assign _pc = _next_pc;
//adder若stall则计算_jalr_rd

wire _debug_000=_pc==32'h64;
endmodule