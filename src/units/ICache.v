module ICache(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
    input  wire					rdy_in,			// ready signal, pause cpu when low

    input wire                  _clear,
    //Fetch
    input wire [31:0]           _pc_Fetcher2Mem,
    input wire                  _stall_set,
    input wire                  _InstFetcher_need_inst,
    //ROB
    // input wire                  _stall_recover,

    input wire                  _stall,

    input wire                  _mem_ready,
    input wire[15:0]            _mem_inst_in,
    output reg                 _ICache_ready,
    output reg [31:0]          _ICache_output,
    output wire [31:0]           _ICache_addr,
    output reg                  _flush
);

reg [31:0] _addr;
reg[31:0] _pc;
assign _ICache_addr=(ready && !hit_1 && !_remaking)?addr1:(ready && !hit_2 && !_remaking)?addr2:(_mem_ready)?_addr+2:_addr;
reg    _remaking;
reg [9:0] tag[0:7];
reg line[0:127];
reg [15:0] cache[0:127];
wire [31:0] addr1=_pc;
wire [31:0] addr2;
//=_pc_Fetcher2Mem+2;
icache_adder icache_adder(
    ._pc(_pc),
    ._next_pc(addr2)
);

wire[2:0] _index=_addr[7:5];
wire[6:0] _offset=_addr[7:1];

wire[2:0] _index_1=addr1[7:5];
wire[2:0] _index_2=addr2[7:5];
wire[6:0] _offset_1=addr1[7:1];
wire[6:0] _offset_2=addr2[7:1];
wire hit_1=tag[_index_1]==addr1[17:8] && line[_offset_1];
wire hit_2=tag[_index_2]==addr2[17:8] && line[_offset_2];
// assign _ICache_output={cache[addr2[7:1]],cache[addr1[7:1]]};
wire ready=(_InstFetcher_need_inst && !_stall && !clr);
reg work;
// assign _ICache_ready=ready && hit_1 && hit_2;
reg clr;
wire _debug_8613=_mem_inst_in==16'h8613;
always @(posedge clk_in) begin:MainBlock
    integer i;
    if(rst_in | !rdy_in) begin
        _addr <= 0;
        _ICache_ready <= 0;
        _remaking <= 0;
        _flush <= 0;
        work<=0;
        clr<=0;
        for(i=0;i<8;i=i+1)begin
            tag[i]<=-1;
        end
        for(i=0;i<128;i=i+1)begin
            line[i]<=0;
            cache[i]<=-1;
        end
    end else if(rdy_in) begin
        if(_clear || _stall_set)begin
            _ICache_ready<=0;
            work<=0;
            clr<=1;
            _flush<=0;
            if(_mem_ready)begin
                    if(_addr[17:8]!=tag[_index])begin
                        tag[_index]<=_addr[17:8];
                        for(i=0;i<16;i=i+1)begin
                            if((16*_index+i)!=_offset)begin
                                line[16*_index+i]<=0;
                            end
                        end
                    end
                    // tag[_index]<=_addr[17:8];
                    line[_offset]<=1;
                    cache[_addr[7:1]]<=_mem_inst_in;
                    _addr<=_addr+2;
                    if(_remaking)begin
                        _remaking<=0;
                    end
                end
        end else if((ready && !work))begin
            _ICache_ready<=0;
            _pc<=_pc_Fetcher2Mem;
            clr<=0;
            work<=1;
            _flush<=0;
            if(_mem_ready)begin
                    if(_addr[17:8]!=tag[_index])begin
                        tag[_index]<=_addr[17:8];
                        for(i=0;i<16;i=i+1)begin
                            if((16*_index+i)!=_offset)begin
                                line[16*_index+i]<=0;
                            end
                        end
                    end
                    // tag[_index]<=_addr[17:8];
                    line[_offset]<=1;
                    cache[_addr[7:1]]<=_mem_inst_in;
                    _addr<=_addr+2;
                    if(_remaking)begin
                        _remaking<=0;
                    end
                end
        end
        else begin
            clr<=0;
            if(_flush==1)begin
            _flush<=0;
            end
            if(ready && hit_1 && hit_2)begin
                _ICache_output<={cache[addr2[7:1]],cache[addr1[7:1]]};
                _ICache_ready<=1;
                work<=0;
            end
            else begin
                _ICache_ready<=0;
            end
            if(ready && !hit_1 && !_remaking)begin
                _addr<=addr1;
                _flush<=1;
                _remaking<=1;
            end
            else if(ready && !hit_2 && !_remaking)begin
                _addr<=addr2;
                _flush<=1;
                _remaking<=1;
            end
            else begin
                _flush<=0;
                if(_mem_ready)begin
                    if(_addr[17:8]!=tag[_index])begin
                        tag[_index]<=_addr[17:8];
                        for(i=0;i<16;i=i+1)begin
                            if((16*_index+i)!=_offset)begin
                                line[16*_index+i]<=0;
                            end
                        end
                    end
                    // tag[_index]<=_addr[17:8];
                    line[_offset]<=1;
                    cache[_addr[7:1]]<=_mem_inst_in;
                    _addr<=_addr+2;
                    if(_remaking)begin
                        _remaking<=0;
                    end
                end
            end
        end
    end
end
endmodule

module icache_adder(
    input wire [31:0] _pc,
    output wire [31:0] _next_pc
);
assign _next_pc = _pc + 2;
endmodule