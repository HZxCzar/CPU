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
    output reg [4:0]           _register_dep_1,
    output reg [31:0]          _register_value_1,
    output reg [4:0]           _register_dep_2,
    output reg [31:0]          _register_value_2,
    //Decoder inputs
    input wire                  _rob_ready,
    input wire [6:0]            _rob_type,
    input wire [31:0]           _rob_inst_addr,
    input wire [4:0]            _rob_rd,
    input wire [31:0]           _rob_value,
    input wire [31:0]           _rob_jump_imm,
    input wire                  _rvc_rob,
    //Decoder outputs
    output  wire                _rob_full,
    output  wire [4:0]          _rob_tail_id,
    //setPC
    output  wire                _br_rob,
    output  wire [31:0]         _rob_new_pc,
    output  wire [31:0]         _rob_imm,

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
    output wire [31:0]          _rf_commit_value,
    //transmit
    output wire [4:0]           _ask_rd_1,
    output wire [4:0]           _ask_rd_2, 
    input wire [4:0]            _dep_rd_1,
    input wire [4:0]            _dep_rd_2,
    input wire [31:0]           _dep_value_1,
    input wire [31:0]           _dep_value_2,

    //Store Control
    output wire                 _store_ready,
    output wire [4:0]           _work_rob_id
);
//编号从1开始
//特判lui
reg [4:0] head,tail,size;
reg busy[1:31];
reg[6:0] rob_type[1:31];
reg[31:0] inst_addr[1:31];
reg[4:0] rob_rd[1:31];
reg[31:0] rob_value[1:31];
reg[31:0] rob_jump_imm[1:31];
reg[1:0] rob_status[1:31];
reg      rvc[1:31];

assign _rob_full=size>=5'd30;
assign _rob_tail_id=tail;

wire _launch_has_rd=(_rob_type==7'b0110011||_rob_type==7'b0010011||_rob_type==7'b0000011||_rob_type==7'b1101111||_rob_type==7'b1100111||_rob_type==7'b0010111||_rob_type==7'b0110111);
assign _rf_launch_ready=_rob_ready && _launch_has_rd;
assign _rf_launch_rob_id=tail;
assign _rf_launch_register_id=_rob_rd;

assign _ask_rd_1=_get_register_status_1;
assign _ask_rd_2=_get_register_status_2;
// assign _register_dep_1=(rob_status[_dep_rd_1]==2)?1'b0:_dep_rd_1;
// assign _register_dep_2=(rob_status[_dep_rd_2]==2)?1'b0:_dep_rd_2;
// assign _register_value_1=_dep_rd_1?rob_value[_dep_rd_1]:_dep_value_1;
// assign _register_value_2=_dep_rd_2?rob_value[_dep_rd_2]:_dep_value_2;

always @(posedge clk_in)begin:MainBlock
    integer i;
    if(rst_in)begin
        head<=1;
        tail<=1;
        size<=0;
        for(i=1;i<=31;i=i+1)begin
        busy[i]<=0;
        rob_type[i]<=0;
        inst_addr[i]<=0;
        rob_rd[i]<=0;
        rob_value[i]<=0;
        rob_jump_imm[i]<=0;
        rob_status[i]<=0;
        rvc[i]<=0;
        end
    end else if(_clear && rdy_in)begin
        head<=1;
        tail<=1;
        size<=0;
        for(i=1;i<=31;i=i+1)begin
        busy[i]<=0;
        rob_type[i]<=0;
        inst_addr[i]<=0;
        rob_rd[i]<=0;
        rob_value[i]<=0;
        rob_jump_imm[i]<=0;
        rob_status[i]<=0;
        rvc[i]<=0;
        end
    end else if(rdy_in)begin
        _register_dep_1<=(rob_status[_dep_rd_1]==2)?1'b0:_dep_rd_1;
        _register_dep_2<=(rob_status[_dep_rd_2]==2)?1'b0:_dep_rd_2;
        _register_value_1<=_dep_rd_1?rob_value[_dep_rd_1]:_dep_value_1;
        _register_value_2<=_dep_rd_2?rob_value[_dep_rd_2]:_dep_value_2;
        if(_rob_ready)begin
            busy[tail]<=1;
            rob_type[tail]<=_rob_type;
            inst_addr[tail]<=_rob_inst_addr;
            rob_rd[tail]<=_rob_rd;
            rob_value[tail]<=_rob_value;
            rob_jump_imm[tail]<=_rob_jump_imm;
            rob_status[tail]<=(_rob_type==7'b0110111)?2'b10:2'b0;
            rvc[tail]<=_rvc_rob;
            tail<=(tail==5'd31)?1:tail+1;
            // size<=size+1;
        end
        if(_cdb_ready)begin
            rob_status[_cdb_rob_id]<=2'b10;
            if(rob_type[_cdb_rob_id]==7'b1100111)begin
                rob_jump_imm[_cdb_rob_id]<=_cdb_value;
            end
            else begin
                rob_value[_cdb_rob_id]<=_cdb_value;
            end
            _rob_msg_ready_1<=1;
            _rob_msg_rob_id_1<=_cdb_rob_id;
            _rob_msg_value_1<=_cdb_value;
        end
        else begin
            _rob_msg_ready_1<=0;
        end
        if(_cdb_ls_ready)begin
            rob_status[_cdb_ls_rob_id]<=2'b10;
            rob_value[_cdb_ls_rob_id]<=_cdb_ls_value;
            _rob_msg_ready_2<=1;
            _rob_msg_rob_id_2<=_cdb_ls_rob_id;
            _rob_msg_value_2<=_cdb_ls_value;
        end
        else begin
            _rob_msg_ready_2<=0;
        end
        if(commit_valid)begin
            busy[head]<=0;
            rob_status[head]<=0;
            head<=next_head;
            // size<=size-1;
        end

        if(_rob_ready && !commit_valid)begin
            size<=size+1;
        end
        else if(!_rob_ready && commit_valid)begin
            size<=size-1;
        end
    end
end
wire [4:0] next_head=(head==5'd31)?5'd1:head+1;
wire commit_valid=busy[head] && rob_status[head]==2'b10;
wire _commit_has_rd=(rob_type[head]==7'b0110011||rob_type[head]==7'b0010011||rob_type[head]==7'b0000011||rob_type[head]==7'b1101111||rob_type[head]==7'b1100111||rob_type[head]==7'b0010111||rob_type[head]==7'b0110111);
assign _rf_commit_ready=commit_valid && _commit_has_rd;
assign _rf_commit_rob_id=head;
assign _rf_commit_register_id=rob_rd[head];
assign _rf_commit_value=rob_value[head];
assign _br_rob=(_clear || _stall);
assign _clear=commit_valid && (rob_type[head]==7'b1100011) && (rob_rd[head][0]!=rob_value[head][0]);
assign _stall=commit_valid && (rob_type[head]==7'b1100111);
assign _rob_new_pc=(rob_type[head]==7'b1100111)?32'b0:inst_addr[head];
assign _rob_imm=(rob_type[head]==7'b1100111 || rob_value[head][0]==1)?rob_jump_imm[head]:rvc[head]?32'd2:32'd4;
assign _store_ready=(rob_type[head]==7'b0100011 || rob_type[head]==7'b0000011);
assign _work_rob_id=head;

wire[4:0] _debug_rob_rd=rob_rd[head];
wire[31:0] _debug_rob_value=rob_value[head];
wire[31:0] _debug_inst_addr=inst_addr[head];
wire[6:0] _debug_rob_type=rob_type[head];

// wire debug_float152=_debug_inst_addr==32'h152;
// wire debug_float142=_debug_inst_addr==32'h142;
// wire debug_float15e=_debug_inst_addr==32'h15e;
// wire debug_float16a=_debug_inst_addr==32'h16a;
// wire debug_float172=_debug_inst_addr==32'h172;
// wire _debug_queens=_debug_inst_addr==32'hbe||_debug_inst_addr==32'hd0 ||_debug_inst_addr==32'hd4;

// wire [31:0] _debug_addr_1=inst_addr[1];
// wire [31:0] _debug_addr_2=inst_addr[2];
// wire [31:0] _debug_addr_3=inst_addr[3];
// wire [31:0] _debug_addr_4=inst_addr[4];
// wire [31:0] _debug_addr_5=inst_addr[5];
// wire [31:0] _debug_addr_6=inst_addr[6];
// wire [31:0] _debug_addr_7=inst_addr[7];
// wire [31:0] _debug_addr_8=inst_addr[8];
// wire [31:0] _debug_addr_9=inst_addr[9];
// wire [31:0] _debug_addr_10=inst_addr[10];
// wire [31:0] _debug_addr_11=inst_addr[11];
// wire [31:0] _debug_addr_12=inst_addr[12];
// wire [31:0] _debug_addr_13=inst_addr[13];
// wire [31:0] _debug_addr_14=inst_addr[14];
// wire [31:0] _debug_addr_15=inst_addr[15];
// wire [31:0] _debug_addr_16=inst_addr[16];
// wire [31:0] _debug_addr_17=inst_addr[17];
// wire [31:0] _debug_addr_18=inst_addr[18];
// wire [31:0] _debug_addr_19=inst_addr[19];
// wire [31:0] _debug_addr_20=inst_addr[20];
// wire [31:0] _debug_addr_21=inst_addr[21];
// wire [31:0] _debug_addr_22=inst_addr[22];
// wire [31:0] _debug_addr_23=inst_addr[23];
// wire [31:0] _debug_addr_24=inst_addr[24];
// wire [31:0] _debug_addr_25=inst_addr[25];
// wire [31:0] _debug_addr_26=inst_addr[26];
// wire [31:0] _debug_addr_27=inst_addr[27];
// wire [31:0] _debug_addr_28=inst_addr[28];
// wire [31:0] _debug_addr_29=inst_addr[29];
// wire [31:0] _debug_addr_30=inst_addr[30];
// wire [31:0] _debug_addr_31=inst_addr[31];

endmodule