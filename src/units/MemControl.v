module  MemControl(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
    input  wire					rdy_in,			// ready signal, pause cpu when low

    //with Memory
    output  wire [ 7:0]          mem_din,		// data input bus
    input wire [ 7:0]          mem_dout,		// data output bus
    input wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    input wire                 mem_wr,			// write/read signal (1 for write)
	
	output  wire                 io_buffer_full, // 1 if uart buffer is full

    //Fetch
    output wire _inst_ready_in_Mem2Fetcher,
    output wire [31:0] _inst_in_Mem2Fetcher,
    input wire [31:0] _pc_Fetcher2Mem,
    input wire _InstFetcher_need_inst,

    //LSB
    input wire _lsb_mem_ready_LoadStoreBuffer2Mem,
    input wire _r_nw_in_LoadStoreBuffer2Mem,
    input wire [31:0] _addr_LoadStoreBuffer2Mem,
    input wire [31:0] _data_in_LoadStoreBuffer2Mem,
    output wire _lsb_mem_ready_Mem2LoadStoreBuffer,
    output wire [31:0] _data_out_Mem2LoadStoreBuffer
);
endmodule