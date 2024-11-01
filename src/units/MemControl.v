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

    output reg _mem_busy,

    //Fetch
    output reg                 _inst_ready_in_Mem2Fetcher,
    output reg [31:0]          _inst_in_Mem2Fetcher,
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
    output reg                 _lsb_mem_ready_Mem2LoadStoreBuffer,
    output reg [31:0]          _data_out_Mem2LoadStoreBuffer
);
reg[1:0] work_on_mode;
reg[23:0] msg;
reg[1:0] counter;
reg[31:0] _input_data;
reg waiter;
reg _stall;
always @(posedge clk_in) begin
    if(_stall_recover) begin
        _stall <= 1'b0;
    end else if(_stall_set) begin
        _stall <= 1'b1;
    end
    if(rst_in || !rdy_in) begin
        work_on_mode <= 2'b00;
        _mem_busy <= 1'b0;
        mem_wr <= 1'b0;
        mem_a <= 32'b0;
        mem_dout <= 8'b0;
        counter <= 2'b00;
    end else if(work_on_mode==2'b11) begin
        if(counter!=2'b00) begin
            case(counter)
                2'b11: msg[7:0] <= mem_din;
                2'b10: msg[15:8] <= mem_din;
                2'b01: msg[23:16] <= mem_din;
            endcase
            counter <= counter - 1;
            mem_a<=mem_a+1;
        end else if(mem_din) begin
            _inst_in_Mem2Fetcher <= {mem_din,msg};
            _inst_ready_in_Mem2Fetcher <= 1'b1;
            work_on_mode <= 2'b00;
            _mem_busy <= 1'b0;
        end
    end else if(work_on_mode!=2'b00) begin
        if(work_on_mode==2'b01) begin
            if(counter!=2'b00) begin
                case(counter)
                2'b11: mem_dout<=_input_data[15:8];
                2'b10: mem_dout<=_input_data[23:16];
                2'b01: mem_dout<=_input_data[31:24];
                endcase
                counter <= counter - 1;
                mem_a<=mem_a+1;
            end else begin
                _data_out_Mem2LoadStoreBuffer <= {32{1'b0}};
                _lsb_mem_ready_Mem2LoadStoreBuffer <= 1'b1;
                work_on_mode <= 2'b00;
                _mem_busy <= 1'b0;
                _input_data<=0;
                waiter<=1;
            end
        end else if(work_on_mode==2'b10) begin
            if(counter!=2'b00) begin
                case(counter)
                2'b11: msg[7:0] <= mem_din;
                2'b10: msg[15:8] <= mem_din;
                2'b01: msg[23:16] <= mem_din;
                endcase
                counter <= counter - 1;
                mem_a<=mem_a+1;
            end else begin
                _data_out_Mem2LoadStoreBuffer <= {mem_din,msg};
                _lsb_mem_ready_Mem2LoadStoreBuffer <= 1'b1;
                work_on_mode <= 2'b00;
                _mem_busy <= 1'b0;
            end
        end
    end else if(_lsb_mem_ready_LoadStoreBuffer2Mem && (_r_nw_in_LoadStoreBuffer2Mem || waiter==0)) begin
        if(_r_nw_in_LoadStoreBuffer2Mem) begin
            work_on_mode <= 2'b01;
            _mem_busy <= 1'b1;
            mem_wr <= 1'b1;
            mem_a <= _addr_LoadStoreBuffer2Mem;
            mem_dout <= _data_in_LoadStoreBuffer2Mem[7:0];
            _input_data <= _data_in_LoadStoreBuffer2Mem;
        end else begin
            work_on_mode <= 2'b10;
            _mem_busy <= 1'b1;
            mem_wr <= 1'b0;
            mem_a <= _addr_LoadStoreBuffer2Mem;
            mem_dout <= 8'b0;
        end
        counter <= _work_type;
    end else if(!_stall_recover && (_stall_set || _stall)) begin
        work_on_mode <= 2'b00;
        _mem_busy <= 1'b0;
        mem_wr <= 1'b0;
        mem_a <= 32'b0;
        mem_dout <= 8'b0;
        counter <= 2'b00;
    end else if(_InstFetcher_need_inst) begin
        work_on_mode <= 2'b11;
        _mem_busy <= 1'b1;
        mem_wr <= 1'b0;
        mem_a <= _pc_Fetcher2Mem;
        mem_dout <= 8'b0;
        counter <= 2'b11;
    end
end
endmodule