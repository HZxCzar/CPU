module  MemControl(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
    input  wire					rdy_in,			// ready signal, pause cpu when low

    //with Memory
    input  wire [ 7:0]           mem_din,		// data input bus
    output wire [ 7:0]           mem_dout,		// data output bus
    output wire [31:0]           mem_a,			// address bus (only 17:0 is used)
    output wire                  mem_wr,			// write/read signal (1 for write)
	
	output  wire                io_buffer_full, // 1 if uart buffer is full

    output wire _mem_busy,
    input wire _clear,

    //Fetch
    output wire                 _inst_ready_in_Mem2Fetcher,
    output wire [31:0]          _inst_in_Mem2Fetcher,
    input wire [31:0]           _pc_Fetcher2Mem,
    input wire                  _stall_set,
    input wire                  _InstFetcher_need_inst,
    //ROB
    input wire             _stall_recover,

    //LSB
    input wire [1:0]            _work_type,
    input wire                  _lsb_mem_ready_LoadStoreBuffer2Mem,
    input wire                  _r_nw_in_LoadStoreBuffer2Mem,
    input wire [31:0]           _addr_LoadStoreBuffer2Mem,
    input wire [31:0]           _data_in_LoadStoreBuffer2Mem,
    output wire                 _lsb_mem_ready_Mem2LoadStoreBuffer,
    output wire [31:0]          _data_out_Mem2LoadStoreBuffer
);
reg _stall;
reg [1:0] work_on_mode;
reg [1:0] waiter;
reg [31:0] addr;
reg write_waiter;
reg[7:0]  data_in[1:3];
always @(posedge clk_in) begin
    if(_stall_recover || _clear) begin
        _stall<=1'b0;
    end else if(_stall_set) begin
        _stall<=1'b1;
    end
    if(rst_in || !rdy_in || _clear) begin
        _stall<=1'b0;
        work_on_mode <= 2'b00;
        waiter<=0;
        write_waiter<=0;
        data_in[1]<=0;
        data_in[2]<=0;
        data_in[3]<=0;
    end else begin
        if(waiter==0 && write_waiter)begin
            write_waiter<=0;
        end
        if(waiter!=0)begin
            waiter<=waiter-1;
            addr<=addr+1;
            data_in[waiter]<=mem_din;
        end
        else if(_lsb_mem_ready_LoadStoreBuffer2Mem && !write_waiter)begin
            if(_r_nw_in_LoadStoreBuffer2Mem)begin
                work_on_mode <= 2'b01;
                write_waiter<=1;
            end
            else begin
                work_on_mode <= 2'b10;
            end
            waiter<=_work_type;
            addr<=_addr_LoadStoreBuffer2Mem;
        end
        else if(_InstFetcher_need_inst && !_stall_set && !_stall)begin
            work_on_mode <= 2'b11;
            waiter<=3;
            addr<=_pc_Fetcher2Mem;
        end
    end
end
assign mem_dout=(work_on_mode==2'b01)?(waiter==3)?_data_in_LoadStoreBuffer2Mem[31:24]:(waiter==2)?_data_in_LoadStoreBuffer2Mem[23:16]:(waiter==1)?_data_in_LoadStoreBuffer2Mem[15:8]:_data_in_LoadStoreBuffer2Mem[7:0]:0;
assign mem_wr=(work_on_mode==2'b01)?1'b1:0;
assign mem_a=addr;
assign _lsb_mem_ready_Mem2LoadStoreBuffer=(work_on_mode==2'b01 || work_on_mode==2'b10) && waiter==0;
assign _data_out_Mem2LoadStoreBuffer={data_in[3],data_in[2],data_in[1],mem_din};
assign _inst_ready_in_Mem2Fetcher=(work_on_mode==2'b11) && waiter==0;
assign _inst_in_Mem2Fetcher={data_in[3],data_in[2],data_in[1],mem_din};
assign _mem_busy=waiter!=0;
endmodule