package constants;

typedef 5 IMGR;
typedef 5 IMGC;
typedef 3 WSZ;
typedef 1 L;
typedef TAdd#(TMul#(TSub#(WSZ,1),IMGC),WSZ) INIT_TIME;
typedef TAdd#(L,2) WT;

typedef Int#(32) Sizet;
typedef Bit#(32) Pixels;
typedef Bit#(32) BitSz;

endpackage