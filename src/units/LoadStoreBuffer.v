module LoadStoreBuffer(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low
    
    input  wire                 _clear,

    //from InstFetcher
    input wire                 _ls_ready,
    input wire [6:0]           _ls_type,
    input wire [2:0]           _ls_op,
    input wire [4:0]           _ls_rob_id,
    output wire                _ls_full,

    //from LoadStoreBufferRS
    input wire                 _lsb_rs_ready,
    input wire [4:0]           _lsb_rs_rob_id, 
    input wire [31:0]          _lsb_rs_st_value,
    input wire [31:0]          _lsb_rs_ptr_value,

    //to MEM
    output wire[1:0]           _work_type,
    output wire                _lsb_mem_ready,
    output wire                _r_nw_in,
    output wire [31:0]         _addr,
    output wire [31:0]         _data_in,
    //from MEM
    input wire                 _mem_busy,
    input wire                 _mem_lsb_ready,
    input wire [31:0]          _data_out,

    //to CDB
    output wire                _lsb_cdb_ready,
    output wire [4:0]          _lsb_cdb_rob_id,
    output wire [31:0]         _lsb_cdb_value,

    //Store Control
    input wire                 _lsb_store_ready
);
reg [4:0] head,tail,size;
reg busy[0:31];
reg[4:0] lsb_rob_id[0:31];
// reg[4:0] last_rob_id;
reg[31:0] lsb_addr[0:31];
reg[3:0] lsb_msg[0:31];//0 for load, 1 for store
reg[31:0] lsb_sv[0:31];
reg[1:0] lsb_status[0:31];

assign _ls_full = (size == 32);
always @(posedge clk_in) begin: MainBlock
    integer i;
    if(rst_in || _clear) begin
        head <= 0;
        tail <= 0;
        size <= 0;
        for(i=0;i<32;i=i+1) begin
            busy[i] <= 0;
            lsb_rob_id[i] <= 0;
            lsb_addr[i] <= 0;
            lsb_msg[i] <= 0;
            lsb_sv[i] <= 0;
            lsb_status[i] <= 0;
        end
    end else if(rdy_in)begin
        if(_ls_ready)begin
            busy[tail] <= 1;
            lsb_rob_id[tail] <= _ls_rob_id;
            lsb_addr[tail] <= 0;
            lsb_msg[tail] <= (_ls_type==7'b0000011)?{1'b0,_ls_op}:{1'b1,_ls_op};
            lsb_sv[tail] <= 0;
            lsb_status[tail] <= 0;
            tail <= tail == 31 ? 0 : tail + 1;
            size <= size + 1;
        end
        if(_lsb_rs_ready)begin
            for(i=0;i<32;i=i+1)begin
                if(busy[i] && lsb_rob_id[i]==_lsb_rs_rob_id)begin
                    lsb_addr[i] <= _lsb_rs_ptr_value;
                    if(lsb_msg[i][3]==1)begin
                        case(lsb_msg[i][2:0])
                            3'b000: lsb_sv[i] <= {24'b0,_lsb_rs_st_value[7:0]};
                            3'b001: lsb_sv[i] <= {16'b0,_lsb_rs_st_value[13:0]};
                            3'b010: lsb_sv[i] <= _lsb_rs_st_value;
                            default: lsb_sv[i] <= 0;
                        endcase
                        if(_lsb_store_ready && i==head)begin
                            lsb_status[head]<=2;
                        end
                        else begin
                            lsb_status[i] <= 1;
                        end
                    end else begin
                        lsb_status[i] <= 2;
                    end
                end
            end
        end
        if(_lsb_store_ready && lsb_status[head]==1)begin
            lsb_status[head]<=2;
        end
        if(_pop_valid)begin
            // last_rob_id <= lsb_rob_id[head];
            busy[head] <= 0;
            head <= head == 31 ? 0 : head + 1;
            size <= size - 1;
        end
    end
end
wire[2:0] _op_old=lsb_msg[head][2:0];

//由于这个周期mem完成后还未pop，下个周期才会pop，但是不希望卡mem一个周期，所以直接梭哈下一个值
wire[2:0] _op=lsb_msg[head+_pop_valid][2:0];
wire[1:0] _debug_lsb_status = lsb_status[head];
assign _lsb_mem_ready = busy[head+_pop_valid] && lsb_status[head+_pop_valid]==2 && !_mem_busy;
assign _r_nw_in = lsb_msg[head+_pop_valid][3];
assign _addr = lsb_addr[head+_pop_valid];
assign _data_in = lsb_sv[head+_pop_valid];
assign _work_type = (_op==3'b010)?2'b11:(_op==3'b001 || _op==3'b101)?2'b01:2'b00;

wire _pop_valid;
assign _pop_valid = _mem_lsb_ready;
assign _lsb_cdb_ready = _mem_lsb_ready;
assign _lsb_cdb_rob_id = lsb_rob_id[head];
assign _lsb_cdb_value = (lsb_msg[head][3]==0)?((_op_old==3'b000)?{{24{_data_out[31]}},_data_out[31:24]}:(_op_old==3'b100)?{24'b0,_data_out[31:24]}:(_op_old==3'b001)?{{16{_data_out[31]}},_data_out[31:16]}:(_op_old==3'b101)?{16'b0,_data_out[31:16]}:_data_out):0;
endmodule