module ALU(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low
    
    input  wire                 _clear,
    input  wire                 _stall,

    //ReservationStation inputs
    input wire          _alu_ready,
    input wire [4:0]    _alu_rob_id,
    input wire [31:0]   _alu_value,
    //ReservationStation outputs
    output wire          _alu_full,

    //CDB outputs
    output wire          _cdb_ready,
    output wire [4:0]    _cdb_rob_id,
    output wire [31:0]   _cdb_value,
);
endmodule