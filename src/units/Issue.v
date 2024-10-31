// `include "../common/fifo/fifo.v"
module Issue(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low

    input  wire                 _clear,

    input  wire [31:0]          _inst_in,
    input  wire                 _inst_ready_in,
    input  wire [31:0]          _inst_addr,
    output wire                 _InstFetcher_need_inst,

    //RegisterFile outputs
    output wire [4:0]           _get_register_id_dependency_1,
    output wire [4:0]           _get_register_id_dependency_2,
    //RegisterFile inputs
    input wire                  _register_id_has_dependency_1,
    input wire [4:0]            _register_id_dependency_1,
    input wire [31:0]           _register_value_1,
    input wire                  _register_id_has_dependency_2,
    input wire [4:0]            _register_id_dependency_2,
    input wire [31:0]           _register_value_2,

    //ROB outputs with dependencies
    output wire [4:0]           _get_register_status_1,
    output wire [4:0]           _get_register_status_2,
    //ROB inputs with dependencies
    input wire                  _rob_register_ready_1,
    input wire [31:0]           _rob_register_value_1,
    input wire                  _rob_register_ready_2,
    input wire [31:0]           _rob_register_value_2,

    //ROB inputs
    input  wire                 _rob_full,
    input  wire [4:0]           _rob_tail_id,
    //ROB outputs
    output wire                  _rob_ready,
    output wire [4:0]            _rob_type,
    output wire [31:0]          _rob_inst_addr,
    output wire [4:0]            _rob_rd,
    output wire [31:0]           _rob_value,
    output wire [31:0]           _rob_jump_imm,


    //ReservationStation inputs
    input  wire                 _rs_full,
    //ReservationStation outputs
    output wire                  _rs_ready,
    output wire [4:0]            _rs_type,
    output wire [4:0]           _rs_rob_id,
    output wire [31:0]          _rs_r1,
    output wire [31:0]          _rs_r2,
    output wire [31:0]          _rs_imm,
    output wire                 _rs_has_dep1,
    output wire [4:0]           _rs_dep1,
    output wire                 _rs_has_dep2,
    output wire [4:0]           _rs_dep2,

    //LoadStoreBuffer inputs
    input  wire                 _lsb_full,
    //LoadStoreBuffer outputs
    output wire                 _lsb_ready,
    output wire [4:0]           _lsb_type,
    output wire [2:0]           _word_length,
    output wire [4:0]           _lsb_rob_id,

    //LoadStoreBufferRS inputs
    input  wire                 _lsb_rs_full,
    //LoadStoreBufferRS outputs
    output reg                  _lsb_rs_ready,
    output reg [4:0]            _lsb_rs_type,
    output wire [4:0]           _lsb_rs_rob_id,
    output wire [31:0]          _lsb_rs_r1,
    output wire [31:0]          _lsb_rs_sv,
    output wire [31:0]          _lsb_rs_imm,
    output wire                 _lsb_rs_has_dep1,
    output wire [4:0]           _lsb_rs_dep1,
    output wire                 _lsb_rs_has_dep2,
    output wire [4:0]           _lsb_rs_dep2
);
wire _pop_valid;
reg [31:0] _top_inst;
reg [31:0] _top_inst_addr;
wire _queue_full;
reg[31:0] inst_queue[0:31];
reg[31:0] addr_queue[0:31];
reg[4:0] head,tail,size;
assign _queue_full=size==32;
always @(posedge clk_in or posedge rst_in) begin
    if(rst_in || !rdy_in) begin
        head <= 0;
        tail <= 0;
        size <= 0;
    end else begin
        if(_clear)begin: clean
        head<=0;
        tail<=0;
        size<=0;
        end
        else begin
            if(!_queue_full && _inst_ready_in && _inst_in[6:0]!=7'b0010111)begin: _push
            inst_queue[tail]<=_inst_in;
            addr_queue[tail]<=_inst_addr;
            tail<=tail==31?0:tail+1;
            size<=size+1;
            end if(_pop_valid)begin: _pop
                _top_inst<=inst_queue[head];
                _top_inst_addr<=addr_queue[head];
                head<=head==31?0:head+1;
                size<=size-1;
            end
        end
    end
end

assign _InstFetcher_need_inst=!_queue_full;
assign _pop_valid = size!=0 && !_rob_full && !_rs_full && !_lsb_full && !_lsb_rs_full;

//Decode
wire[6:0] opcode=_top_inst[6:0];
wire[11:7] rd=_top_inst[11:7];
wire[14:12] op=_top_inst[14:12];
wire[19:15] rs1=_top_inst[19:15];
wire[24:20] rs2=_top_inst[24:20];
wire[12:0] immB={_top_inst[31],_top_inst[7],_top_inst[30:25],_top_inst[11:8],1'b0};
wire[11:0] immI=_top_inst[31:20];
wire[31:0] immU={_top_inst[31:12],{12{1'b0}}};
wire[11:0] immS={_top_inst[31:25],_top_inst[11:7]};
wire[20:0] immJal={_top_inst[31],_top_inst[19:12],_top_inst[20],_top_inst[30:21],1'b0};
wire[31:0] immJalr=_top_inst[31:20];

wire predict = 1'b1;//no predictor
//ROB
assign _rob_ready=_pop_valid;
assign _rob_type=opcode;
assign _rob_inst_addr=_top_inst_addr;
assign _rob_rd = (opcode == 7'b1100011) ? {4'b0000, predict} : (opcode == 7'b0100011) ? 5'b00000 : rd;
assign _rob_value=(opcode==7'b0110111)?immU:{31{1'b0}};
assign _rob_jump_imm=(opcode == 7'b1100011) ? immB : (opcode == 7'b1101111) ? immJal : (opcode == 7'b0010111) ? immU : (opcode == 7'b1100111) ? immJalr : 32'b0;


assign _get_register_id_dependency_1=rs1;
assign _get_register_id_dependency_2=rs2;
assign _get_register_status_1=_register_id_dependency_1;
assign _get_register_status_2=_register_id_dependency_2;


//ReservationStation
assign _rs_ready=_pop_valid && opcode!=7'b0000011 && opcode!=7'b0100011 && opcode!=7'b0110111;
assign _rs_type=opcode;
assign _rs_rob_id=_rob_tail_id;
assign _rs_r1=_register_id_has_dependency_1?_rob_register_value_1:_register_value_1;
assign _rs_r2=_register_id_has_dependency_2?_rob_register_value_2:_register_value_2;
assign _rs_imm=(opcode == 7'b1100011) ? immB : (opcode == 7'b1101111) ? immJal : (opcode == 7'b1100111) ? immJalr : (opcode == 7'b0000011 || opcode == 7'b0010011) ? immI : immS;
assign _rs_has_dep1=_register_id_has_dependency_1&&!_rob_register_ready_1;
assign _rs_dep1=_rs_has_dep1?_register_id_dependency_1:5'b00000;
assign _rs_has_dep2=_register_id_has_dependency_2&&!_rob_register_ready_2;
assign _rs_dep2=_rs_has_dep2?_register_id_dependency_2:5'b00000;

//LoadStoreBuffer
assign _lsb_ready=_pop_valid && (opcode==7'b0000011 || opcode==7'b0100011);
assign _lsb_type=opcode;
assign _lsb_rob_id=_rob_tail_id;

endmodule