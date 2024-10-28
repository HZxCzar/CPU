module CDB(
    //from ALU
    input wire          _alu_cdb_ready,
    input wire [4:0]    _alu_cdb_rob_id,
    input wire [31:0]   _alu_cdb_value,
    //from LoadStoreBuffer
    input wire               _lsb_cdb_ready,
    input wire [4:0]         _lsb_cdb_rob_id,
    input wire [31:0]        _lsb_cdb_value,

    //outputs
    output wire                _cdb_ready,
    output wire [4:0]          _cdb_rob_id,
    output wire [31:0]         _cdb_value,
    output wire                _cdb_ls_ready,
    output wire [4:0]          _cdb_ls_rob_id,
    output wire [31:0]         _cdb_ls_value
);
endmodule