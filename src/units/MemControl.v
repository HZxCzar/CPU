module  MemControl(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
    input  wire					rdy_in,			// ready signal, pause cpu when low

    //with Memory
    input  wire [ 7:0]           mem_din,		// data input bus
    output reg [ 7:0]           mem_dout,		// data output bus
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
    input wire                  _stall_recover,

    //LSB
    input wire [1:0]            _work_type,
    input wire                  _lsb_mem_ready_LoadStoreBuffer2Mem,
    input wire                  _r_nw_in_LoadStoreBuffer2Mem,
    input wire [31:0]           _addr_LoadStoreBuffer2Mem,
    input wire [31:0]           _data_in_LoadStoreBuffer2Mem,
    output wire                 _lsb_mem_ready_Mem2LoadStoreBuffer,
    output wire [31:0]          _data_out_Mem2LoadStoreBuffer
);
wire _ICache_ready;
wire [31:0] _ICache_output;
wire [31:0] _ICache_addr;
wire _mem_ready;
wire [15:0] _mem_inst_in;
wire _flush;

assign _mem_ready=(work_on_mode==2'b11) && waiter==0 && !_flush;
assign _mem_inst_in={mem_din,data_in[1]};

ICache cache(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .rdy_in(rdy_in),
    ._pc_Fetcher2Mem(_pc_Fetcher2Mem),
    ._stall_set(_stall_set),
    ._InstFetcher_need_inst(_InstFetcher_need_inst),
    ._stall_recover(_stall_recover),
    ._stall(_stall),
    ._mem_ready(_mem_ready),
    ._mem_inst_in(_mem_inst_in),
    ._ICache_ready(_ICache_ready),
    ._ICache_output(_ICache_output),
    ._ICache_addr(_ICache_addr),
    ._flush(_flush)
);

reg _stall;
reg [1:0] work_on_mode;
reg [2:0] waiter;
reg [2:0] adder;
reg [31:0] addr;
reg[7:0]  data_in[1:3];
always @(posedge clk_in) begin
    if(rdy_in && (_stall_recover || _clear)) begin
        _stall<=1'b0;
    end else if(rdy_in && (_stall_set)) begin
        _stall<=1'b1;
    end
    if(rst_in || _clear) begin
        _stall<=1'b0;
        work_on_mode <= 2'b00;
        adder<=0;
        waiter<=0;
        data_in[1]<=0;
        data_in[2]<=0;
        data_in[3]<=0;
    end else if(rdy_in)begin
        if(waiter!=0 && !(_flush && work_on_mode==2'b11))begin
            // if(_flush && work_on_mode==2'b11)begin
            //     waiter<=0;
            // end
            if(work_on_mode==2'b01)begin
                if(adder==0)begin
                    mem_dout<=_data_in_LoadStoreBuffer2Mem[15:8];
                end
                else if(adder==1)begin
                    mem_dout<=_data_in_LoadStoreBuffer2Mem[23:16];
                end
                else begin
                    mem_dout<=_data_in_LoadStoreBuffer2Mem[31:24];
                end
            end
            if(adder!=0)begin
            data_in[waiter]<=mem_din;
            end
            adder<=adder+1;
            waiter<=waiter-1;
            addr<=addr+1;
        end
        else if(_lsb_mem_ready_LoadStoreBuffer2Mem)begin//&& !write_waiter
            if(_r_nw_in_LoadStoreBuffer2Mem)begin
                work_on_mode <= 2'b01;
                mem_dout<=_data_in_LoadStoreBuffer2Mem[7:0];
            end
            else begin
                work_on_mode <= 2'b10;
            end
            adder<=0;
            waiter<=_work_type+1;
            addr<=_addr_LoadStoreBuffer2Mem;
        end
        else begin
            work_on_mode <= 2'b11;
            adder<=0;
            waiter<=2;
            addr<=_ICache_addr;
        end
        // else if(_InstFetcher_need_inst && !_stall_set && (!_stall || _stall_recover))begin
        //     work_on_mode <= 2'b11;
        //     adder<=0;
        //     waiter<=4;
        //     addr<=_pc_Fetcher2Mem;
        // end
        // else begin
        //     adder<=0;
        //     work_on_mode <= 2'b00;
        // end
    end
end
// assign mem_dout=(work_on_mode==2'b01)?(adder==3)?_data_in_LoadStoreBuffer2Mem[31:24]:(adder==2)?_data_in_LoadStoreBuffer2Mem[23:16]:(adder==1)?_data_in_LoadStoreBuffer2Mem[15:8]:(adder==0)?_data_in_LoadStoreBuffer2Mem[7:0]:0:0;
assign mem_wr=(work_on_mode==2'b01 && waiter!=0)?1'b1:0;
assign mem_a=addr;
assign _lsb_mem_ready_Mem2LoadStoreBuffer=(work_on_mode==2'b01 || work_on_mode==2'b10) && waiter==0;
assign _data_out_Mem2LoadStoreBuffer={mem_din,data_in[1],data_in[2],data_in[3]};
// assign _inst_ready_in_Mem2Fetcher=(work_on_mode==2'b11) && waiter==0;
assign _inst_ready_in_Mem2Fetcher=_ICache_ready;
// assign _inst_in_Mem2Fetcher={mem_din,data_in[1],data_in[2],data_in[3]};
assign _inst_in_Mem2Fetcher=_ICache_output;
assign _mem_busy=waiter!=0;

wire _debug_mem_wirte=mem_a==32'h30000;
endmodule