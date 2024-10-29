module  MemControl(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
    input  wire					rdy_in,			// ready signal, pause cpu when low

    //with Memory
    input  wire [ 7:0]           mem_din,		// data input bus
    output reg [ 7:0]           mem_dout,		// data output bus
    output reg [31:0]           mem_a,			// address bus (only 17:0 is used)
    output reg                  mem_wr,			// write/read signal (1 for write)
	
	output  wire                io_buffer_full, // 1 if uart buffer is full

    //Fetch
    output reg                 _inst_ready_in_Mem2Fetcher,
    output reg [31:0]          _inst_in_Mem2Fetcher,
    input wire [31:0]           _pc_Fetcher2Mem,
    input wire                  _stall_set,
    //ROB
    input wire             _stall_recover,

    //LSB
    input wire                  _lsb_mem_ready_LoadStoreBuffer2Mem,
    input wire                  _r_nw_in_LoadStoreBuffer2Mem,
    input wire [31:0]           _addr_LoadStoreBuffer2Mem,
    input wire [7:0]           _data_in_LoadStoreBuffer2Mem,
    output reg                 _lsb_mem_ready_Mem2LoadStoreBuffer,
    output reg [7:0]          _data_out_Mem2LoadStoreBuffer
);
reg[1:0] work_on_mode;
reg[23:0] inst;
reg[1:0] counter;
reg _stall;
always @(posedge clk_in) begin
    if(_stall_recover) begin
        _stall <= 1'b0;
    end else if(_stall_set) begin
        _stall <= 1'b1;
    end
    if(rst_in || !rdy_in) begin
        work_on_mode <= 2'b00;
        mem_wr <= 1'b0;
        mem_a <= 32'b0;
        mem_dout <= 8'b0;
        counter <= 2'b00;
    end else if(work_on_mode==2'b11) begin
        if(mem_din && counter!=2'b10) begin
            case(counter)
                2'b00: inst[7:0] <= mem_din;
                2'b01: inst[15:8] <= mem_din;
                2'b10: inst[23:16] <= mem_din;
            endcase
            counter <= counter + 1;
        end else if(mem_din) begin
            counter <= 2'b00;
            _inst_in_Mem2Fetcher <= {mem_din,inst};
            _inst_ready_in_Mem2Fetcher <= 1'b1;
            work_on_mode <= 2'b00;
        end
    end else if(work_on_mode!=2'b00) begin
        if(mem_din && work_on_mode==2'b01) begin
            _data_out_Mem2LoadStoreBuffer <= mem_din;
            _lsb_mem_ready_Mem2LoadStoreBuffer <= 1'b1;
            work_on_mode <= 2'b00;
        end else if(mem_din && work_on_mode==2'b10) begin
            _data_out_Mem2LoadStoreBuffer <= mem_din;
            _lsb_mem_ready_Mem2LoadStoreBuffer <= 1'b1;
            work_on_mode <= 2'b00;
        end
    end else if(_lsb_mem_ready_LoadStoreBuffer2Mem) begin
        if(_r_nw_in_LoadStoreBuffer2Mem) begin
            work_on_mode <= 2'b01;
            mem_wr <= 1'b1;
            mem_a <= _addr_LoadStoreBuffer2Mem;
            mem_dout <= _data_in_LoadStoreBuffer2Mem;
        end else begin
            work_on_mode <= 2'b10;
            mem_wr <= 1'b0;
            mem_a <= _addr_LoadStoreBuffer2Mem;
            mem_dout <= 8'b0;
        end
    end else if(!_stall_recover && (_stall_set || _stall)) begin
        work_on_mode <= 2'b00;
        mem_wr <= 1'b0;
        mem_a <= 32'b0;
        mem_dout <= 8'b0;
        counter <= 2'b00;
    end else if(_inst_ready_in_Mem2Fetcher) begin
        work_on_mode <= 2'b11;
        mem_wr <= 1'b0;
        mem_a <= _pc_Fetcher2Mem;
        mem_dout <= 8'b0;
    end
end
endmodule