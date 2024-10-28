module RegisterFile(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low
    
    //from ROB
    //ROB inputs with launch
    input wire                _rob_launch_ready,
    input wire [4:0]          _rob_launch_rob_id,
    input wire [4:0]          _rob_launch_register_id,
    //ROB inputs with commit
    input wire                _rob_commit_ready,
    input wire [4:0]          _rob_commit_rob_id,
    input wire [4:0]          _rob_commit_register_id,
    input wire [31:0]         _rob_commit_value,

    //from InstFetcher
    input wire [4:0]           _get_register_id_dependency_1,
    input wire [4:0]           _get_register_id_dependency_2,
    output wire                  _register_id_has_dependency_1,
    output wire [4:0]            _register_id_dependency_1,
    output wire [31:0]           _register_value_1,
    output wire                  _register_id_has_dependency_2,
    output wire [4:0]            _register_id_dependency_2,
    output wire [31:0]           _register_value_2,

    //to ReservationStation
    output  wire                 _rf_msg_ready,
    output  wire [4:0]           _rf_msg_rob_id,
    output  wire [31:0]          _rf_msg_value
);
endmodule