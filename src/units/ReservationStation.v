module ReservationStation(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low
    
    input  wire                 _clear,

    // InstFetcher inputs
    input wire                  _rs_ready,
    input wire [6:0]            _rs_type,
    input wire [3:0]            _rs_op,
    input wire [4:0]            _rs_rob_id,
    input wire [31:0]           _rs_r1,
    input wire [31:0]           _rs_r2,
    input wire [31:0]           _rs_imm,
    input wire                  _rs_has_dep1,
    input wire [4:0]            _rs_dep1,
    input wire                  _rs_has_dep2,
    input wire [4:0]            _rs_dep2,
    // InstFetcher outputs
    output wire                 _rs_full,

    //CDB inputs
    input wire                  _cdb_ready,
    input wire [4:0]            _cdb_rob_id,
    input wire [31:0]           _cdb_value,
    input wire                  _cdb_ls_ready,
    input wire [4:0]            _cdb_ls_rob_id,
    input wire [31:0]           _cdb_ls_value,

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
    input wire                  _alu_full,
    //ALU outputs
    output wire                 _alu_ready,
    output wire [4:0]           _alu_rob_id,
    output wire [6:0]           _alu_type,
    output wire [3:0]           _alu_op,
    output wire [31:0]          _alu_v1,
    output wire [31:0]          _alu_v2
);
reg busy[0:31];
reg[6:0] rss_type[0:31];
reg[3:0] rss_op[0:31];
reg[4:0] rss_rob_id[0:31];
reg[31:0] rss_r1[0:31];
reg[31:0] rss_r2[0:31];
reg[31:0] rss_imm[0:31];
reg[4:0] rss_dep1[0:31];
reg[4:0] rss_dep2[0:31];
wire[4:0] _space;
wire _pop_valid;
wire[4:0] _pop_pos;
reg[4:0] size;
assign _rs_full=size==32;
always @(posedge clk_in) begin: MainBlock
    integer i;
    if(rst_in | !rdy_in | _clear) begin
        size <= 5'b0;
        if(rst_in)begin
            for(i=0;i<32;i=i+1)begin
                busy[i] <= 0;
                rss_type[i] <= 7'b0;
                rss_op[i] <= 3'b0;
                rss_rob_id[i] <= 5'b0;
                rss_r1[i] <= 32'b0;
                rss_r2[i] <= 32'b0;
                rss_imm[i] <= 32'b0;
                rss_dep1[i] <= 5'b0;
                rss_dep2[i] <= 5'b0;
            end
        end
    end else begin
        if(_rs_ready) begin
            busy[_space] <= 1 ;
            rss_type[_space] <= _rs_type;
            rss_op[_space] <= _rs_op;
            rss_rob_id[_space] <= _rs_rob_id;
            rss_r1[_space] <= _rs_r1;
            rss_r2[_space] <= _rs_r2;
            rss_imm[_space] <= _rs_imm;
            rss_dep1[_space] <= _rs_has_dep1?_rs_dep1:0;
            rss_dep2[_space] <= _rs_has_dep2?_rs_dep2:0;
            size <= size + 1;
        end
        
        for (i = 0;i<32;i=i+1) begin
            if(busy[i])begin
                if(_cdb_ready)begin
                    if(rss_dep1[i]==_cdb_rob_id) begin
                        rss_r1[i] <= _cdb_value;
                        rss_dep1[i] <= 0;
                    end
                    if(rss_dep2[i]==_cdb_rob_id) begin
                        rss_r2[i] <= _cdb_value;
                        rss_dep2[i] <= 0;
                    end
                end
                if(_cdb_ls_ready)begin
                    if(rss_dep1[i]==_cdb_ls_rob_id) begin
                        rss_r1[i] <= _cdb_ls_value;
                        rss_dep1[i] <= 0;
                    end
                    if(rss_dep2[i]==_cdb_ls_rob_id) begin
                        rss_r2[i] <= _cdb_ls_value;
                        rss_dep2[i] <= 0;
                    end
                end
                if(_rob_msg_ready_1)begin
                    if(rss_dep1[i]==_rob_msg_rob_id_1) begin
                        rss_r1[i] <= _rob_msg_value_1;
                        rss_dep1[i] <= 0;
                    end
                    if(rss_dep2[i]==_rob_msg_rob_id_1) begin
                        rss_r2[i] <= _rob_msg_value_1;
                        rss_dep2[i] <= 0;
                    end
                end
                if(_rob_msg_ready_2)begin
                    if(rss_dep1[i]==_rob_msg_rob_id_2) begin
                        rss_r1[i] <= _rob_msg_value_2;
                        rss_dep1[i] <= 0;
                    end
                    if(rss_dep2[i]==_rob_msg_rob_id_2) begin
                        rss_r2[i] <= _rob_msg_value_2;
                        rss_dep2[i] <= 0;
                    end
                end
                if(_rf_msg_ready)begin
                    if(rss_dep1[i]==_rf_msg_rob_id) begin
                        rss_r1[i] <= _rf_msg_value;
                        rss_dep1[i] <= 0;
                    end
                    if(rss_dep2[i]==_rf_msg_rob_id) begin
                        rss_r2[i] <= _rf_msg_value;
                        rss_dep2[i] <= 0;
                    end
                end
            end
        end
        if(_pop_valid)begin
            busy[_pop_pos] <= 0;
        end
    end
end

wire _ready[0:31];
// pop
generate
    genvar i;
    for(i=0;i<32;i=i+1)begin: PopBlock
        assign _ready[i] = busy[i] && rss_dep1[i]==0 && rss_dep2[i]==0;
    end
endgenerate
assign _space= !busy[0]?5'd0:!busy[1]?5'd1:!busy[2]?5'd2:!busy[3]?5'd3:!busy[4]?5'd4:!busy[5]?5'd5:!busy[6]?5'd6:!busy[7]?5'd7:!busy[8]?5'd8:!busy[9]?5'd9:!busy[10]?5'd10:!busy[11]?5'd11:!busy[12]?5'd12:!busy[13]?5'd13:!busy[14]?5'd14:!busy[15]?5'd15:!busy[16]?5'd16:!busy[17]?5'd17:!busy[18]?5'd18:!busy[19]?5'd19:!busy[20]?5'd20:!busy[21]?5'd21:!busy[22]?5'd22:!busy[23]?5'd23:!busy[24]?5'd24:!busy[25]?5'd25:!busy[26]?5'd26:!busy[27]?5'd27:!busy[28]?5'd28:!busy[29]?5'd29:!busy[30]?5'd30:!busy[31]?5'd31:5'd0;
assign _pop_pos = (_ready[0] ? 5'd0 :_ready[1] ? 5'd1 : _ready[2]? 5'd2 : _ready[3]? 5'd3 : _ready[4]? 5'd4 : _ready[5]? 5'd5 : _ready[6]? 5'd6 : _ready[7]? 5'd7 : _ready[8]? 5'd8 : _ready[9]? 5'd9 : _ready[10]? 5'd10 : _ready[11]? 5'd11 : _ready[12]? 5'd12 : _ready[13]? 5'd13 : _ready[14]? 5'd14 : _ready[15]? 5'd15 : _ready[16]? 5'd16 : _ready[17]? 5'd17 : _ready[18]? 5'd18 : _ready[19]? 5'd19 : _ready[20]? 5'd20 : _ready[21]? 5'd21 : _ready[22]? 5'd22 : _ready[23]? 5'd23 : _ready[24]? 5'd24 : _ready[25]? 5'd25 : _ready[26]? 5'd26 : _ready[27]? 5'd27 : _ready[28]? 5'd28 : _ready[29]? 5'd29 : _ready[30]? 5'd30 : _ready[31]? 5'd31 : 5'd0);
assign _pop_valid=_alu_full && (_ready[0] || _ready[1] || _ready[2] || _ready[3] || _ready[4] || _ready[5] || _ready[6] || _ready[7] || _ready[8] || _ready[9] || _ready[10] || _ready[11] || _ready[12] || _ready[13] || _ready[14] || _ready[15] || _ready[16] || _ready[17] || _ready[18] || _ready[19] || _ready[20] || _ready[21] || _ready[22] || _ready[23] || _ready[24] || _ready[25] || _ready[26] || _ready[27] || _ready[28] || _ready[29] || _ready[30] || _ready[31]);
assign _alu_ready=_pop_valid;
assign _alu_rob_id=rss_rob_id[_pop_pos];
assign _alu_type=rss_type[_pop_pos];
assign _alu_op=rss_op[_pop_pos];
assign _alu_v1=rss_r1[_pop_pos];
assign _alu_v2=(rss_type[_pop_pos]==7'b0110011||rss_type[_pop_pos]==7'b1100011)?rss_r2[_pop_pos]:rss_imm[_pop_pos];
endmodule