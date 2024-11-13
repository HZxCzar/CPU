module RegisterFile(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					rdy_in,			// ready signal, pause cpu when low
    
    input wire                 _clear,
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
    if (rst_in) begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] <= 0;
            dependency[i] <= 0;
        end
    end else if(rdy_in)begin
        if(_clear) begin
            for (i = 0; i < 32; i = i + 1) begin
                dependency[i] <= 0;
            end
        end
        else begin
        if(_rob_launch_ready && _rob_launch_register_id!=0) begin
            dependency[_rob_launch_register_id] <= _rob_launch_rob_id;
        end
        if(_rob_commit_ready && _rob_commit_register_id!=0) begin
            registers[_rob_commit_register_id] <= _rob_commit_value;
            _rf_msg_ready <= 1;
            _rf_msg_rob_id <= _rob_commit_rob_id;
            _rf_msg_value <= _rob_commit_value;
            if(dependency[_rob_commit_register_id] == _rob_commit_rob_id && (!_rob_launch_ready || _rob_launch_register_id!=_rob_commit_register_id)) begin
                dependency[_rob_commit_register_id] <= 0;
            end
        end
        else begin
            _rf_msg_ready <= 0;
        end
        end
    end
end
assign _dep_rd_1 = dependency[_ask_rd_1];
assign _dep_rd_2 = dependency[_ask_rd_2];
assign _dep_value_1 = registers[_ask_rd_1];
assign _dep_value_2 = registers[_ask_rd_2];

wire [31:0] _debug_x0 = registers[0];
wire [31:0] _debug_ra = registers[1];
wire [31:0] _debug_sp = registers[2];
wire [31:0]  _debug_t0 = registers[5];
wire [31:0]  _debug_t1 = registers[6];
wire [31:0]  _debug_t2 = registers[7];
wire [31:0]  _debug_s0 = registers[8];
wire [31:0]  _debug_s1 = registers[9];
wire [31:0]  _debug_a0 = registers[10];
wire [31:0]  _debug_a1 = registers[11];
wire [31:0]  _debug_a2 = registers[12];
wire [31:0]  _debug_a3 = registers[13];
wire [31:0]  _debug_a4 = registers[14];
wire [31:0]  _debug_a5 = registers[15];
wire [31:0]  _debug_a6 = registers[16];
wire [31:0]  _debug_a7 = registers[17];
wire [31:0]  _debug_s2 = registers[18];
wire [31:0]  _debug_s3 = registers[19];
wire [31:0]  _debug_s4 = registers[20];
wire [31:0]  _debug_s5 = registers[21];
wire [31:0]  _debug_s6 = registers[22];
wire [31:0]  _debug_s7 = registers[23];
wire [31:0]  _debug_s8 = registers[24];
wire [31:0]  _debug_s9 = registers[25];
wire [31:0]  _debug_s10 = registers[26];
wire [31:0]  _debug_s11 = registers[27];
wire [31:0]  _debug_t3 = registers[28];
wire [31:0]  _debug_t4 = registers[29];
wire [31:0]  _debug_t5 = registers[30];
wire [31:0]  _debug_t6 = registers[31];

wire [4:0] _debug_dep_x0 = dependency[0];
wire [4:0] _debug_dep_ra = dependency[1];
wire [4:0] _debug_dep_sp = dependency[2];
wire [4:0]  _debug_dep_t0 = dependency[5];
wire [4:0]  _debug_dep_t1 = dependency[6];
wire [4:0]  _debug_dep_t2 = dependency[7];
wire [4:0]  _debug_dep_s0 = dependency[8];
wire [4:0]  _debug_dep_s1 = dependency[9];
wire [4:0]  _debug_dep_a0 = dependency[10];
wire [4:0]  _debug_dep_a1 = dependency[11];
wire [4:0]  _debug_dep_a2 = dependency[12];
wire [4:0]  _debug_dep_a3 = dependency[13];
wire [4:0]  _debug_dep_a4 = dependency[14];
wire [4:0]  _debug_dep_a5 = dependency[15];
wire [4:0]  _debug_dep_a6 = dependency[16];
wire [4:0]  _debug_dep_a7 = dependency[17];
wire [4:0]  _debug_dep_s2 = dependency[18];
wire [4:0]  _debug_dep_s3 = dependency[19];
wire [4:0]  _debug_dep_s4 = dependency[20];
wire [4:0]  _debug_dep_s5 = dependency[21];
wire [4:0]  _debug_dep_s6 = dependency[22];
wire [4:0]  _debug_dep_s7 = dependency[23];
wire [4:0]  _debug_dep_s8 = dependency[24];
wire [4:0]  _debug_dep_s9 = dependency[25];
wire [4:0]  _debug_dep_s10 = dependency[26];
wire [4:0]  _debug_dep_s11 = dependency[27];
wire [4:0]  _debug_dep_t3 = dependency[28];
wire [4:0]  _debug_dep_t4 = dependency[29];
wire [4:0]  _debug_dep_t5 = dependency[30];
wire [4:0]  _debug_dep_t6 = dependency[31];


endmodule