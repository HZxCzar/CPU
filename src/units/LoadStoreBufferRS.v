module LoadStoreBufferRS(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low
    
    input  wire                 _clear,

    // InstFetcher inputs
    input wire                  _rs_ready,
    input wire [6:0]            _rs_type,
    input wire [4:0]            _rs_rob_id,
    input wire                  _lsb_rs_need_1,
    input wire                  _lsb_rs_need_2,
    input wire [31:0]           _lsb_rs_imm,
    // input wire [31:0]           _rs_r1,
    // input wire [31:0]           _rs_sv,
    // input wire [31:0]           _rs_imm,
    // input wire                  _rs_has_dep1,
    // input wire [4:0]            _rs_dep1,
    // input wire                  _rs_has_dep2,
    // input wire [4:0]            _rs_dep2,
    // InstFetcher outputs
    output wire                 _rs_full,

    //DEP&VAL
    input wire [4:0]            _rob_register_dep_1,
    input wire [31:0]           _rob_register_value_1,
    input wire [4:0]            _rob_register_dep_2,
    input wire [31:0]           _rob_register_value_2,

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

    //to LoadStoreBuffer
    output wire                 _lsb_rs_ready,
    output wire [4:0]           _lsb_rob_id, 
    output wire [31:0]          _lsb_st_value,
    output wire [31:0]          _lsb_ptr_value
);
reg busy[0:7];
reg[6:0] rss_type[0:7];
reg[4:0] rss_rob_id[0:7];
reg[31:0] rss_v1[0:7];
reg[31:0] rss_sv[0:7];
reg[31:0] rss_imm[0:7];
reg[4:0] rss_dep1[0:7];
reg[4:0] rss_dep2[0:7];
wire[2:0] _space;
wire _pop_valid;
wire[2:0] _pop_pos;
reg[3:0] size;
assign _rs_full=size>=4'd7;
always @(posedge clk_in) begin: MainBlock
    integer i;
    if(rst_in || _clear) begin
        size <= 4'b0;
            for(i=0;i<8;i=i+1)begin
                busy[i] <= 0;
                rss_type[i] <= 32'b0;
                rss_rob_id[i] <= 5'b0;
                rss_v1[i] <= 32'b0;
                rss_sv[i] <= 32'b0;
                rss_imm[i] <= 32'b0;
                rss_dep1[i] <= 5'b0;
                rss_dep2[i] <= 5'b0;
            end
    end else if(rdy_in)begin
        if(_rs_ready) begin
            busy[_space] <= 1 ;
            rss_type[_space] <= _rs_type;
            rss_rob_id[_space] <= _rs_rob_id;
            // rss_v1[_space] <= _rs_r1;
            // rss_sv[_space] <= _rs_sv;
            rss_imm[_space] <= _lsb_rs_imm;
            // rss_dep1[_space] <= _rs_has_dep1?_rs_dep1:0;
            // rss_dep2[_space] <= _rs_has_dep2?_rs_dep2:0;

            if(_lsb_rs_need_1)begin
                if(_cdb_ready && _rob_register_dep_1==_cdb_rob_id)begin
                    rss_v1[_space] <= _cdb_value;
                    rss_dep1[_space] <= 0;
                end else if(_cdb_ls_ready && _rob_register_dep_1==_cdb_ls_rob_id)begin
                    rss_v1[_space] <= _cdb_ls_value;
                    rss_dep1[_space] <= 0;
                end else begin
                    rss_v1[_space] <= _rob_register_value_1;
                    rss_dep1[_space] <= _rob_register_dep_1;
                end
            end else begin
                rss_v1[_space] <= 32'b0;
                rss_dep1[_space] <= 0;
            end

            if(_lsb_rs_need_2)begin
                if(_cdb_ready && _rob_register_dep_2==_cdb_rob_id)begin
                    rss_sv[_space] <= _cdb_value;
                    rss_dep2[_space] <= 0;
                end else if(_cdb_ls_ready && _rob_register_dep_2==_cdb_ls_rob_id)begin
                    rss_sv[_space] <= _cdb_ls_value;
                    rss_dep2[_space] <= 0;
                end else begin
                    rss_sv[_space] <= _rob_register_value_2;
                    rss_dep2[_space] <= _rob_register_dep_2;
                end
            end else begin
                rss_sv[_space] <= 32'b0;
                rss_dep2[_space] <= 0;
            end

            // if(_rs_has_dep1 && _cdb_ready && _rs_dep1==_cdb_rob_id)begin
            //     rss_v1[_space] <= _cdb_value;
            //     rss_dep1[_space] <= 0;
            // end else if(_rs_has_dep1 && _cdb_ls_ready && _rs_dep1==_cdb_ls_rob_id)begin
            //     rss_v1[_space] <= _cdb_ls_value;
            //     rss_dep1[_space] <= 0;
            // end else begin
            //     rss_v1[_space] <= _rs_r1;
            //     rss_dep1[_space] <= _rs_has_dep1?_rs_dep1:0;
            // end
            // if(_rs_has_dep2 && _cdb_ready && _rs_dep2==_cdb_rob_id)begin
            //     rss_sv[_space] <= _cdb_value;
            //     rss_dep2[_space] <= 0;
            // end else if(_rs_has_dep2 && _cdb_ls_ready && _rs_dep2==_cdb_ls_rob_id)begin
            //     rss_sv[_space] <= _cdb_ls_value;
            //     rss_dep2[_space] <= 0;
            // end else begin
            //     rss_sv[_space] <= _rs_sv;
            //     rss_dep2[_space] <= _rs_has_dep2?_rs_dep2:0;
            // end
            // size <= size + 1;
        end
        
        for (i = 0;i<8;i=i+1) begin
            if(busy[i])begin
                if(_cdb_ready)begin
                    if(rss_dep1[i]==_cdb_rob_id) begin
                        rss_v1[i] <= _cdb_value;
                        rss_dep1[i] <= 0;
                    end
                    if(rss_dep2[i]==_cdb_rob_id) begin
                        rss_sv[i] <= _cdb_value;
                        rss_dep2[i] <= 0;
                    end
                end
                if(_cdb_ls_ready)begin
                    if(rss_dep1[i]==_cdb_ls_rob_id) begin
                        rss_v1[i] <= _cdb_ls_value;
                        rss_dep1[i] <= 0;
                    end
                    if(rss_dep2[i]==_cdb_ls_rob_id) begin
                        rss_sv[i] <= _cdb_ls_value;
                        rss_dep2[i] <= 0;
                    end
                end
                if(_rob_msg_ready_1)begin
                    if(rss_dep1[i]==_rob_msg_rob_id_1) begin
                        rss_v1[i] <= _rob_msg_value_1;
                        rss_dep1[i] <= 0;
                    end
                    if(rss_dep2[i]==_rob_msg_rob_id_1) begin
                        rss_sv[i] <= _rob_msg_value_1;
                        rss_dep2[i] <= 0;
                    end
                end
                if(_rob_msg_ready_2)begin
                    if(rss_dep1[i]==_rob_msg_rob_id_2) begin
                        rss_v1[i] <= _rob_msg_value_2;
                        rss_dep1[i] <= 0;
                    end
                    if(rss_dep2[i]==_rob_msg_rob_id_2) begin
                        rss_sv[i] <= _rob_msg_value_2;
                        rss_dep2[i] <= 0;
                    end
                end
                if(_rf_msg_ready)begin
                    if(rss_dep1[i]==_rf_msg_rob_id) begin
                        rss_v1[i] <= _rf_msg_value;
                        rss_dep1[i] <= 0;
                    end
                    if(rss_dep2[i]==_rf_msg_rob_id) begin
                        rss_sv[i] <= _rf_msg_value;
                        rss_dep2[i] <= 0;
                    end
                end
            end
        end
        if(_pop_valid)begin
            busy[_pop_pos] <= 0;
        end

        if(_rs_ready && !_pop_valid)begin
            size <= size + 1;
        end
        else if(!_rs_ready && _pop_valid)begin
            size <= size - 1;
        end
    end
end

generate
    genvar i;
    wire _ready[0:7];
    wire _pop_v[1:15];
    wire[2:0] _pop_index[1:15];
    wire _space_v[1:15];
    wire[2:0] _space_index[1:15];
    for(i=0;i<8;i=i+1)begin: PopBlock
        assign _ready[i] = busy[i] && !rss_dep1[i] && !rss_dep2[i];
    end
    for(i=8;i<16;i=i+1)begin: GenBlock
        assign _pop_v[i] = _ready[i-8];
        assign _pop_index[i] = i-8;
        assign _space_v[i] = ~busy[i-8];
        assign _space_index[i] = i-8;
    end
    for(i=1;i<8;i=i+1)begin: WorkBlock
        assign _pop_v[i]=_pop_v[i<<1] | _pop_v[(i<<1)|1];
        assign _pop_index[i]=_pop_v[i<<1]?_pop_index[i<<1]:_pop_index[(i<<1)|1];
        assign _space_v[i]=_space_v[i<<1] | _space_v[(i<<1)|1];
        assign _space_index[i]=_space_v[i<<1]?_space_index[i<<1]:_space_index[(i<<1)|1];
    end
endgenerate
assign _space=_space_index[1];
assign _pop_pos=_pop_index[1];
assign _pop_valid=_pop_v[1];
wire [31:0] _result;
LSAlu alu(
    ._v1(rss_v1[_pop_pos]),
    ._imm(rss_imm[_pop_pos]),
    ._result(_result)
);
// assign _space=_space_index[1];
// assign _pop_pos=_pop_index[1];
// assign _pop_valid=_pop_v[1];
// assign _space= !busy[0]?5'd0:!busy[1]?5'd1:!busy[2]?5'd2:!busy[3]?5'd3:!busy[4]?5'd4:!busy[5]?5'd5:!busy[6]?5'd6:!busy[7]?5'd7:!busy[8]?5'd8:!busy[9]?5'd9:!busy[10]?5'd10:!busy[11]?5'd11:!busy[12]?5'd12:!busy[13]?5'd13:!busy[14]?5'd14:!busy[15]?5'd15:!busy[16]?5'd16:!busy[17]?5'd17:!busy[18]?5'd18:!busy[19]?5'd19:!busy[20]?5'd20:!busy[21]?5'd21:!busy[22]?5'd22:!busy[23]?5'd23:!busy[24]?5'd24:!busy[25]?5'd25:!busy[26]?5'd26:!busy[27]?5'd27:!busy[28]?5'd28:!busy[29]?5'd29:!busy[30]?5'd30:!busy[31]?5'd31:5'd0;
// assign _pop_pos = (_ready[0] ? 5'd0 :_ready[1] ? 5'd1 :_ready[2] ? 5'd2 :_ready[3] ? 5'd3 :_ready[4] ? 5'd4 :_ready[5] ? 5'd5 :_ready[6] ? 5'd6 :_ready[7] ? 5'd7 :_ready[8] ? 5'd8 :_ready[9] ? 5'd9 :_ready[10] ? 5'd10 :_ready[11] ? 5'd11 :_ready[12] ? 5'd12 :_ready[13] ? 5'd13 :_ready[14] ? 5'd14 :_ready[15] ? 5'd15 :_ready[16] ? 5'd16 :_ready[17] ? 5'd17 :_ready[18] ? 5'd18 :_ready[19] ? 5'd19 :_ready[20] ? 5'd20 :_ready[21] ? 5'd21 :_ready[22] ? 5'd22 :_ready[23] ? 5'd23 :_ready[24] ? 5'd24 :_ready[25] ? 5'd25 :_ready[26] ? 5'd26 :_ready[27] ? 5'd27 :_ready[28] ? 5'd28 :_ready[29] ? 5'd29 :_ready[30] ? 5'd30 :_ready[31] ? 5'd31 : 5'd0);
// assign _pop_valid=(_ready[0] || _ready[1] || _ready[2] || _ready[3] || _ready[4] || _ready[5] || _ready[6] || _ready[7] || _ready[8] || _ready[9] || _ready[10] || _ready[11] || _ready[12] || _ready[13] || _ready[14] || _ready[15] || _ready[16] || _ready[17] || _ready[18] || _ready[19] || _ready[20] || _ready[21] || _ready[22] || _ready[23] || _ready[24] || _ready[25] || _ready[26] || _ready[27] || _ready[28] || _ready[29] || _ready[30] || _ready[31]);
assign _lsb_rs_ready=_pop_valid;
assign _lsb_rob_id=rss_rob_id[_pop_pos];
assign _lsb_st_value=rss_sv[_pop_pos];
assign _lsb_ptr_value=_result;
endmodule

module LSAlu(
    input wire[31:0]        _v1,
    input wire[31:0]        _imm,
    output wire[31:0]       _result
);
assign _result = _v1 + _imm;
endmodule