module LoadStoreBufferALU(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low
    
    input  wire                 _clear,

    //ReservationStation inputs
    input wire                  _alu_ready,
    input wire [4:0]            _alu_rob_id,
    input wire [31:0]           _alu_value,
    //ReservationStation outputs
    output wire                 _alu_full,

    //LoadStoreBuffer outputs
    output wire                 _lsb_ready,
    output wire [4:0]           _lsb_rob_id,
    output wire [31:0]          _lsb_value
);
endmodule