module LoadStoreBuffer(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low
    
    input  wire                 _clear,
    input  wire                 _stall,

    //from InstFetcher
    input wire                 _ls_ready,
    input wire [4:0]           _ls_type,
    input wire [4:0]         _ls_rob_id,
    output wire               _ls_full,

    //from LoadStoreBufferRS
    input wire                _lsb_rs_ready,
    input wire [4:0]          _rs_rob_id, 
    input wire [31:0]         _rs_st_value,

    //from ALU
    input wire                _lsb_alu_ready,
    input wire [4:0]          _alu_rob_id,
    input wire [31:0]         _alu_value,

    //to MEM
    output wire               _lsb_mem_ready,
    output wire               _r_nw_in,
    output wire [31:0]        _addr,
    output wire [31:0]        _data_in,
    //from MEM
    input wire                _lsb_mem_ready,
    input wire [31:0]         _data_out,

    //to CDB
    output wire               _lsb_cdb_ready,
    output wire [4:0]         _lsb_cdb_rob_id,
    output wire [31:0]        _lsb_cdb_value,
);
endmodule