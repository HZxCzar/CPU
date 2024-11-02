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

always @(posedge clk_in) begin
    if (rst_in | !rdy_in | _clear) begin
        _alu_full <= 0;
    end
    else begin
        if(_alu_ready) begin
            _alu_full <= 1;
        end
        else begin
            _alu_full <= 0;
        end
    end
end

assign _cdb_ready = _alu_full;
assign _cdb_rob_id = _alu_rob_id;
assign _cdb_value = (_alu_type==7'b0110011)?((_alu_op==4'd0)?_alu_v1+_alu_v2:(_alu_op==4'd1)?_alu_v1-_alu_v2:(_alu_op==4'd2)?_alu_v1 & _alu_v2:(_alu_op==4'd3)?_alu_v1 | _alu_v2:(_alu_op==4'd4)?_alu_v1 ^ _alu_v2:(_alu_op==4'd5)?_alu_v1<<_alu_v2:(_alu_op==4'd6)?$unsigned(_alu_v1)>>$unsigned(_alu_v2):(_alu_op==4'd7)?$signed(_alu_v1)>>>$signed(_alu_v2):(_alu_op==4'd8)?($signed(_alu_v1) < $signed(_alu_v2)):($unsigned(_alu_v1)>$unsigned(_alu_v2))):
                    (_alu_type==7'b0010011)?((_alu_op==4'd0)?_alu_v1+_alu_v2:(_alu_op==4'd1)?_alu_v1 & _alu_v2:(_alu_op==4'd2)?_alu_v1 | _alu_v2:(_alu_op==4'd3)?_alu_v1 ^ _alu_v2:(_alu_op==4'd4)?_alu_v1<<_alu_v2:(_alu_op==4'd5)?$unsigned(_alu_v1)>>$unsigned(_alu_v2):(_alu_op==4'd6)?$signed(_alu_v1)>>>$signed(_alu_v2):(_alu_op==4'd7)?($signed(_alu_v1) < $signed(_alu_v2)):($unsigned(_alu_v1)>$unsigned(_alu_v2))):
                    (_alu_type==7'b1100011)?((_alu_op==4'd0)?_alu_v1==_alu_v2:(_alu_op==4'd1)?$signed(_alu_v1)>=$signed(_alu_v2):(_alu_op==4'd2)?$unsigned(_alu_v1)>=$unsigned(_alu_v2):(_alu_op==4'd3)?$signed(_alu_v1)<$signed(_alu_v2):(_alu_op==4'd4)?$unsigned(_alu_v1)<$unsigned(_alu_v2):_alu_v1!=_alu_v2):
                    (_alu_type==7'b1101111 || _alu_type==7'b1100111)?_alu_v1+_alu_v2:
                    32'b0;
//SignExtend?
endmodule