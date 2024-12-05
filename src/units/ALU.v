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
    // output reg          _alu_full,

    //CDB outputs
    output reg          _cdb_ready,
    output reg [4:0]    _cdb_rob_id,
    output reg [31:0]   _cdb_value
);
// reg[4:0] _alu_rob_id;
// reg[6:0] _alu_type;
// reg[3:0] _alu_op;
// reg[31:0] _alu_v1;
// reg[31:0] _alu_v2;
// reg size;
// assign _alu_full = size==2'd2;

always @(posedge clk_in) begin
    if (rst_in | _clear) begin
        // _alu_full <= 0;
        // size<=0;
    end
    else if(rdy_in)begin
        // if(_alu_ready) begin
        //     _alu_rob_id <= _alu_rob_id;
        //     _alu_type <= _alu_type;
        //     _alu_op <= _alu_op;
        //     _alu_v1 <= _alu_v1;
        //     _alu_v2 <= _alu_v2;
        // end
        // if(_alu_ready && !size)begin
        //     size<=1;
        // end else if(!_alu_ready && size)begin
        //     size<=0;
        // end
        if(_alu_ready)begin
            _cdb_ready <= 1;
            _cdb_rob_id <= _alu_rob_id;
            case (_alu_type)
                7'b0110011: begin
                    case (_alu_op)
                        4'd0: _cdb_value <= _alu_v1 + _alu_v2;
                        4'd1: _cdb_value <= _alu_v1 - _alu_v2;
                        4'd2: _cdb_value <= _alu_v1 & _alu_v2;
                        4'd3: _cdb_value <= _alu_v1 | _alu_v2;
                        4'd4: _cdb_value <= _alu_v1 ^ _alu_v2;
                        4'd5: _cdb_value <= _alu_v1 << _alu_v2;
                        4'd6: _cdb_value <= $unsigned(_alu_v1) >> $unsigned(_alu_v2);
                        4'd7: _cdb_value <= $signed(_alu_v1) >>> $signed(_alu_v2);
                        4'd8: _cdb_value <= ($signed(_alu_v1) < $signed(_alu_v2));
                        default: _cdb_value <= ($unsigned(_alu_v1) > $unsigned(_alu_v2));
                    endcase
                end
                7'b0010011: begin
                    case (_alu_op)
                        4'd0: _cdb_value <= _alu_v1 + _alu_v2;
                        4'd1: _cdb_value <= _alu_v1 & _alu_v2;
                        4'd2: _cdb_value <= _alu_v1 | _alu_v2;
                        4'd3: _cdb_value <= _alu_v1 ^ _alu_v2;
                        4'd4: _cdb_value <= _alu_v1 << _alu_v2;
                        4'd5: _cdb_value <= $unsigned(_alu_v1) >> $unsigned(_alu_v2);
                        4'd6: _cdb_value <= $signed(_alu_v1) >>> $signed(_alu_v2);
                        4'd7: _cdb_value <= ($signed(_alu_v1) < $signed(_alu_v2));
                        default: _cdb_value <= ($unsigned(_alu_v1) > $unsigned(_alu_v2));
                    endcase
                end
                7'b1100011: begin
                    case (_alu_op)
                        4'd0: _cdb_value <= (_alu_v1 == _alu_v2);
                        4'd1: _cdb_value <= ($signed(_alu_v1) >= $signed(_alu_v2));
                        4'd2: _cdb_value <= ($unsigned(_alu_v1) >= $unsigned(_alu_v2));
                        4'd3: _cdb_value <= ($signed(_alu_v1) < $signed(_alu_v2));
                        4'd4: _cdb_value <= ($unsigned(_alu_v1) < $unsigned(_alu_v2));
                        default: _cdb_value <= (_alu_v1 != _alu_v2);
                    endcase
                end
                7'b1101111, 7'b1100111, 7'b0010111: begin
                    _cdb_value <= _alu_v1 + _alu_v2;
                end
                default: begin
                    _cdb_value <= 32'b0;
                end
            endcase
        end
        else begin
            _cdb_ready <= 0;
        end
        // else begin
        //     _alu_full <= 0;
        // end
    end
end

// assign _cdb_ready = _alu_full;
// assign _cdb_rob_id = _alu_rob_id;
// assign _cdb_value = (_alu_type==7'b0110011)?((_alu_op==4'd0)?_alu_v1+_alu_v2:(_alu_op==4'd1)?_alu_v1-_alu_v2:(_alu_op==4'd2)?_alu_v1 & _alu_v2:(_alu_op==4'd3)?_alu_v1 | _alu_v2:(_alu_op==4'd4)?_alu_v1 ^ _alu_v2:(_alu_op==4'd5)?_alu_v1<<_alu_v2:(_alu_op==4'd6)?$unsigned(_alu_v1)>>$unsigned(_alu_v2):(_alu_op==4'd7)?$signed(_alu_v1)>>>$signed(_alu_v2):(_alu_op==4'd8)?($signed(_alu_v1) < $signed(_alu_v2)):($unsigned(_alu_v1)>$unsigned(_alu_v2))):
//                     (_alu_type==7'b0010011)?((_alu_op==4'd0)?_alu_v1+_alu_v2:(_alu_op==4'd1)?_alu_v1 & _alu_v2:(_alu_op==4'd2)?_alu_v1 | _alu_v2:(_alu_op==4'd3)?_alu_v1 ^ _alu_v2:(_alu_op==4'd4)?_alu_v1<<_alu_v2:(_alu_op==4'd5)?$unsigned(_alu_v1)>>$unsigned(_alu_v2):(_alu_op==4'd6)?$signed(_alu_v1)>>>$signed(_alu_v2):(_alu_op==4'd7)?($signed(_alu_v1) < $signed(_alu_v2)):($unsigned(_alu_v1)>$unsigned(_alu_v2))):
//                     (_alu_type==7'b1100011)?((_alu_op==4'd0)?_alu_v1==_alu_v2:(_alu_op==4'd1)?$signed(_alu_v1)>=$signed(_alu_v2):(_alu_op==4'd2)?$unsigned(_alu_v1)>=$unsigned(_alu_v2):(_alu_op==4'd3)?$signed(_alu_v1)<$signed(_alu_v2):(_alu_op==4'd4)?$unsigned(_alu_v1)<$unsigned(_alu_v2):_alu_v1!=_alu_v2):
//                     (_alu_type==7'b1101111 || _alu_type==7'b1100111 || _alu_type==7'b0010111)?_alu_v1+_alu_v2:
//                     32'b0;
//SignExtend?
endmodule