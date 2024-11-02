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
    output wire [4:0]           _register_dep_1,
    output wire [31:0]          _register_value_1,
    output wire [4:0]           _register_dep_2,
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
    input wire [31:0]           _dep_value_2
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

assign _rob_full=size==31;
assign _rob_tail_id=tail;

wire _launch_has_rd=(_rob_type==7'b0110011||_rob_type==7'b0010011||_rob_type==7'b0000011||_rob_type==7'b1101111||_rob_type==7'b1100111||_rob_type==7'b0010111||_rob_type==7'b0110111);
assign _rf_launch_ready=_rob_ready && _launch_has_rd;
assign _rf_launch_rob_id=tail;
assign _rf_launch_register_id=_rob_rd;

assign _ask_rd_1=_get_register_status_1;
assign _ask_rd_2=_get_register_status_2;
assign _register_dep_1=(_dep_rd_1==0 || rob_status[_dep_rd_1]==2);
assign _register_dep_2=(_dep_rd_2==0 || rob_status[_dep_rd_2]==2);
assign _register_value_1=_dep_rd_1?rob_value[_dep_rd_1]:_dep_value_1;
assign _register_value_2=_dep_rd_2?rob_value[_dep_rd_2]:_dep_value_2;

always @(posedge clk_in)begin:MainBlock
    integer i;
    if(rst_in | !rdy_in)begin
        head<=0;
        tail<=0;
        size<=0;
        for(i=1;i<=31;i=i+1)begin
        busy[i]<=0;
        rob_type[i]<=0;
        inst_addr[i]<=0;
        rob_rd[i]<=0;
        rob_value[i]<=0;
        rob_jump_imm[i]<=0;
        rob_status[i]<=0;
        end
    end else if(_clear)begin
        head<=0;
        tail<=0;
        size<=0;
        for(i=1;i<=31;i=i+1)begin
        busy[i]<=0;
        rob_type[i]<=0;
        inst_addr[i]<=0;
        rob_rd[i]<=0;
        rob_value[i]<=0;
        rob_jump_imm[i]<=0;
        rob_status[i]<=0;
        end
    end else begin
        if(_rob_ready)begin
            busy[tail]<=1;
            rob_type[tail]<=_rob_type;
            inst_addr[tail]<=_rob_inst_addr;
            rob_rd[tail]<=_rob_rd;
            rob_value[tail]<=_rob_value;
            rob_jump_imm[tail]<=_rob_jump_imm;
            rob_status[tail]<=(_rob_type==7'b0110111)?2'b10:2'b0;
            tail<=(tail==31)?1:tail+1;
            size<=size+1;
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
        if(_cdb_ls_ready)begin
            rob_status[_cdb_ls_rob_id]<=2'b10;
            rob_value[_cdb_ls_rob_id]<=_cdb_ls_value;
            _rob_msg_ready_2<=1;
            _rob_msg_rob_id_2<=_cdb_ls_rob_id;
            _rob_msg_value_2<=_cdb_ls_value;
        end
        if(commit_valid)begin
            busy[head]<=0;
            head<=(head==31)?1:head+1;
            size<=size-1;
        end
    end
end
wire commit_valid=busy[head] && rob_status[head]==2'b10;
wire _commit_has_rd=(_rob_type==7'b0110011||_rob_type==7'b0010011||_rob_type==7'b0000011||_rob_type==7'b1101111||_rob_type==7'b1100111||_rob_type==7'b0010111||_rob_type==7'b0110111);
assign _rf_commit_ready=commit_valid && _commit_has_rd;
assign _rf_commit_rob_id=head;
assign _rf_commit_register_id=rob_rd[head];
assign _rf_commit_value=rob_value[head];

assign _br_rob=(_clear || (commit_valid && rob_type[head]==7'b1100111));
assign _clear=commit_valid && (rob_rd[head]==7'b1100011) && (rob_rd[head]!=rob_value[head]);
assign _stall=commit_valid && (rob_rd[head]==7'b1100111);
assign _rob_new_pc=(rob_type[head]==7'b1100111)?32'b0:inst_addr[head];
assign _rob_imm=rob_jump_imm[head];


endmodule