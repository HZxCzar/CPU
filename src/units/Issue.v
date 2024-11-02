// `include "../common/fifo/fifo.v"
module Issue(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low

    input  wire                 _clear,

    input  wire [31:0]          _inst_in,
    input  wire                 _inst_ready_in,
    input  wire [31:0]          _inst_addr,
    input  wire [31:0]          _jalr_rd, 
    output wire                 _InstFetcher_need_inst,

    //ROB outputs with dependencies
    output wire [4:0]           _get_register_status_1,
    output wire [4:0]           _get_register_status_2,
    //ROB inputs with dependencies
    input wire [4:0]            _rob_register_dep_1,
    input wire [31:0]           _rob_register_value_1,
    input wire [4:0]            _rob_register_dep_2,
    input wire [31:0]           _rob_register_value_2,

    //ROB inputs
    input  wire                 _rob_full,
    input  wire [4:0]           _rob_tail_id,
    //ROB outputs
    output wire                  _rob_ready,
    output wire [6:0]            _rob_type,
    output wire [31:0]          _rob_inst_addr,
    output wire [4:0]            _rob_rd,
    output wire [31:0]           _rob_value,
    output wire [31:0]           _rob_jump_imm,


    //ReservationStation inputs
    input  wire                 _rs_full,
    //ReservationStation outputs
    output wire                  _rs_ready,
    output wire [6:0]            _rs_type,
    output wire [3:0]            _rs_op,
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
    output wire [6:0]           _lsb_type,
    output wire [2:0]           _lsb_op,
    output wire [4:0]           _lsb_rob_id,

    //LoadStoreBufferRS inputs
    input  wire                 _lsb_rs_full,
    //LoadStoreBufferRS outputs
    output wire                  _lsb_rs_ready,
    output wire [6:0]            _lsb_rs_type,
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
always @(posedge clk_in) begin
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
            if(_inst_ready_in)begin
            inst_queue[tail]<=_inst_in;
            addr_queue[tail]<=_inst_addr;
            tail<=tail==31?0:tail+1;
            size<=size+1;
            end if(_pop_valid)begin
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
wire[14:12] funct3=_top_inst[14:12];
wire[31:25] funct7=_top_inst[31:25];
wire[19:15] rs1=_top_inst[19:15];
wire[24:20] rs2=_top_inst[24:20];
wire[31:0] immB={{20{_top_inst[31]}},_top_inst[7],_top_inst[30:25],_top_inst[11:8],1'b0};
wire[31:0] immI={{20{_top_inst[31]}},_top_inst[31:20]};
wire[31:0] immU={_top_inst[31:12],{12{1'b0}}};
wire[31:0] immS={{20{_top_inst[31]}},_top_inst[31:25],_top_inst[11:7]};
wire[31:0] immJal={{12{_top_inst[31]}},_top_inst[19:12],_top_inst[20],_top_inst[30:21],1'b0};
wire[31:0] immJalr={_top_inst[31:20],20'b0};

wire predict = 1'b1;//no predictor
//ROB
assign _rob_ready=_pop_valid;
assign _rob_type=opcode;
assign _rob_inst_addr=_top_inst_addr;
assign _rob_rd = (opcode == 7'b1100011) ? {4'b0000, predict} : (opcode == 7'b0100011) ? 5'b00000 : rd;
assign _rob_value=(opcode==7'b0110111)?immU:(opcode==7'b1100111)?_jalr_rd:{31{1'b0}};
assign _rob_jump_imm=(opcode == 7'b1100011) ? immB : (opcode==7'b1101111)?immJal:32'b0;//immJal未来在ROB用不到,只是记录


// assign _get_register_id_dependency_1=rs1;
// assign _get_register_id_dependency_2=rs2;
assign _get_register_status_1=rs1;
assign _get_register_status_2=rs2;

wire _need_rs1=(opcode==7'b0110011) || (opcode==7'b0010011) || (opcode==7'b0000011) || (opcode==7'b0100011) || (opcode==7'b1100011) || (opcode==7'b1100111);
wire _need_rs2=(opcode==7'b0110011) || (opcode==7'b1100011);
//ReservationStation
assign _rs_ready=_pop_valid && opcode!=7'b0000011 && opcode!=7'b0100011 && opcode!=7'b0110111;
assign _rs_type=opcode;
assign _rs_op=(opcode==7'b0110011)?((funct3==3'b000)?((funct7==7'b0)?4'd0:4'd1):(funct3==3'b111)?4'd2:(funct3==3'b110)?4'd3:(funct3==3'b100)?4'd4:(funct3==3'b001)?4'd5:(funct3==3'b101)?((funct7==7'b0)?4'd6:4'd7):(funct3==3'b010)?4'd8:4'd9):
              (opcode==7'b0010011)?((funct3==3'b000)?4'd0:(funct3==3'b111)?4'd1:(funct3==3'b110)?4'd2:(funct3==3'b100)?4'd3:(funct3==3'b001)?4'd4:(funct3==3'b101)?((funct7==7'b0)?4'd5:4'd6):(funct3==3'b010)?4'd7:4'd8):
              (opcode==7'b1100011)?((funct3==3'b000)?4'd0:(funct3==3'b101)?4'd1:(funct3==3'b111)?4'd2:(funct3==3'b100)?4'd3:(funct3==3'b110)?4'd4:4'd5):4'd0;
assign _rs_rob_id=_rob_tail_id;
assign _rs_r1=(opcode == 7'b1101111 || opcode==7'b0010111) ? _top_inst_addr:_rob_register_dep_1?0:_rob_register_value_1;
assign _rs_r2=_rob_register_dep_2?0:_rob_register_value_2;
assign _rs_imm=(opcode == 7'b1100011) ? immB : (opcode == 7'b1101111) ? {29'b0,3'd4} : (opcode == 7'b1100111) ? immJalr : (opcode == 7'b0000011 || opcode == 7'b0010011) ? immI :(opcode==7'b0010111)?immU: immS;
assign _rs_has_dep1=_need_rs1?(_rob_register_dep_1):1'b0;
assign _rs_dep1=_rs_has_dep1?_rob_register_dep_1:5'b0;
assign _rs_has_dep2=_need_rs2?(_rob_register_dep_2):1'b0;
assign _rs_dep2=_rs_has_dep2?_rob_register_dep_2:5'b0;

//LoadStoreBuffer
assign _lsb_ready=_pop_valid && (opcode==7'b0000011 || opcode==7'b0100011);
assign _lsb_type=opcode;
assign _lsb_rob_id=_rob_tail_id;
assign _lsb_op=funct3;

//LoadStoreBufferRS
assign _lsb_rs_ready=_pop_valid && (opcode==7'b0000011 || opcode==7'b0100011);
assign _lsb_rs_type=opcode;
assign _lsb_rs_rob_id=_rob_tail_id;
assign _lsb_rs_r1=_rob_register_dep_1?0:_rob_register_value_1;
assign _lsb_rs_sv=_rob_register_dep_2?0:_rob_register_value_2;
assign _lsb_rs_imm=(opcode == 7'b0000011) ? immI :
                   (opcode == 7'b0100011) ? immS : 32'b0; 
assign _lsb_rs_has_dep1=_need_rs1?(_rob_register_dep_1):1'b0;
assign _lsb_rs_dep1=_lsb_rs_has_dep1?_rob_register_dep_1:5'b0;
assign _lsb_rs_has_dep2=_need_rs2?(_rob_register_dep_2):1'b0;
assign _lsb_rs_dep2=_lsb_rs_has_dep2?_rob_register_dep_2:5'b0;

endmodule