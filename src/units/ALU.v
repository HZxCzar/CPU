module ALU(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low
    
    input  wire                 _clear,

    //ReservationStation inputs
    input wire           _alu_ready,
    input wire [4:0]     _alu_rob_id,
    input wire [6:0]     _alu_type,
    input wire [3:0]     _alu_op,
    input wire [31:0]    _alu_v1,
    input wire [31:0]    _alu_v2,
    //ReservationStation outputs
    output reg          _alu_full,

    //CDB outputs
    output wire          _cdb_ready,
    output wire [4:0]    _cdb_rob_id,
    output wire [31:0]   _cdb_value
);
reg[4:0] alu_rob_id;
reg[6:0] alu_type;
reg[3:0] alu_op;
reg[31:0] alu_v1;
reg[31:0] alu_v2;

always @(posedge clk_in) begin
    if (rst_in | _clear) begin
        _alu_full <= 0;
    end
    else if(rdy_in)begin
        if(_alu_ready) begin
            _alu_full <= 1;
            alu_rob_id <= _alu_rob_id;
            alu_type <= _alu_type;
            alu_op <= _alu_op;
            alu_v1 <= _alu_v1;
            alu_v2 <= _alu_v2;
        end
        else begin
            _alu_full <= 0;
        end
    end
end

assign _cdb_ready = _alu_full;
assign _cdb_rob_id = alu_rob_id;
assign _cdb_value = (alu_type==7'b0110011)?((alu_op==4'd0)?alu_v1+alu_v2:(alu_op==4'd1)?alu_v1-alu_v2:(alu_op==4'd2)?alu_v1 & alu_v2:(alu_op==4'd3)?alu_v1 | alu_v2:(alu_op==4'd4)?alu_v1 ^ alu_v2:(alu_op==4'd5)?alu_v1<<alu_v2:(alu_op==4'd6)?$unsigned(alu_v1)>>$unsigned(alu_v2):(alu_op==4'd7)?$signed(alu_v1)>>>$signed(alu_v2):(alu_op==4'd8)?($signed(alu_v1) < $signed(alu_v2)):($unsigned(alu_v1)>$unsigned(alu_v2))):
                    (alu_type==7'b0010011)?((alu_op==4'd0)?alu_v1+alu_v2:(alu_op==4'd1)?alu_v1 & alu_v2:(alu_op==4'd2)?alu_v1 | alu_v2:(alu_op==4'd3)?alu_v1 ^ alu_v2:(alu_op==4'd4)?alu_v1<<alu_v2:(alu_op==4'd5)?$unsigned(alu_v1)>>$unsigned(alu_v2):(alu_op==4'd6)?$signed(alu_v1)>>>$signed(alu_v2):(alu_op==4'd7)?($signed(alu_v1) < $signed(alu_v2)):($unsigned(alu_v1)>$unsigned(alu_v2))):
                    (alu_type==7'b1100011)?((alu_op==4'd0)?alu_v1==alu_v2:(alu_op==4'd1)?$signed(alu_v1)>=$signed(alu_v2):(alu_op==4'd2)?$unsigned(alu_v1)>=$unsigned(alu_v2):(alu_op==4'd3)?$signed(alu_v1)<$signed(alu_v2):(alu_op==4'd4)?$unsigned(alu_v1)<$unsigned(alu_v2):alu_v1!=alu_v2):
                    (alu_type==7'b1101111 || alu_type==7'b1100111 || alu_type==7'b0010111)?alu_v1+alu_v2:
                    32'b0;
//SignExtend?
endmodule