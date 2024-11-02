module RegisterFile(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low
    
    //from ROB
    //ROB inputs with launch
    input wire                  _rob_launch_ready,
    input wire [4:0]            _rob_launch_rob_id,
    input wire [4:0]            _rob_launch_register_id,
    //ROB inputs with commit
    input wire                  _rob_commit_ready,
    input wire [4:0]            _rob_commit_rob_id,
    input wire [4:0]            _rob_commit_register_id,
    input wire [31:0]           _rob_commit_value,

    //transmit
    input wire [4:0]            _ask_rd_1,
    input wire [4:0]            _ask_rd_2, 
    output wire [4:0]           _dep_rd_1,
    output wire [4:0]           _dep_rd_2,
    output wire [31:0]          _dep_value_1,
    output wire [31:0]          _dep_value_2,

    //to ReservationStation
    output  reg                 _rf_msg_ready,
    output  reg [4:0]           _rf_msg_rob_id,
    output  reg [31:0]          _rf_msg_value
);
reg [31:0] registers[0:31];
reg [4:0] dependency[0:31];
always @(posedge clk_in) begin:MainBlock
    integer i;
    if (rst_in | !rdy_in) begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] <= 0;
            dependency[i] <= 0;
        end
    end else begin
        if(_rob_launch_ready) begin
            dependency[_rob_launch_register_id] <= _rob_launch_rob_id;
        end
        if(_rob_commit_ready) begin
            registers[_rob_commit_register_id] <= _rob_commit_value;
            _rf_msg_ready <= 1;
            _rf_msg_rob_id <= _rob_commit_rob_id;
            _rf_msg_value <= _rob_commit_value;
            if(dependency[_rob_commit_register_id] == _rob_commit_rob_id) begin
                dependency[_rob_commit_register_id] <= 0;
            end
        end
        else begin
            _rf_msg_ready <= 0;
        end
    end
end
assign _dep_rd_1 = dependency[_ask_rd_1];
assign _dep_rd_2 = dependency[_ask_rd_2];
assign _dep_value_1 = registers[_ask_rd_1];
assign _dep_value_2 = registers[_ask_rd_2];
endmodule