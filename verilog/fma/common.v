package common;
    parameter THD_NUM = 2;
    parameter MAX_REG_NUM_PER_THD = 4;
    parameter REG_NUM = THD_NUM * MAX_REG_NUM_PER_THD;
//    parameter REG_ADDR_WIDTH  = $clog2(REG_NUM);
    parameter REG_ADDR_WIDTH  = 2;
    parameter DATA_WIDTH  = 32;
    parameter CODE_WIDTH  = 32;
    parameter OPTYPE_WIDTH  = 2;
endpackage
