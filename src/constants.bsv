package constants;

typedef 5 IMGR;
typedef 5 IMGC;
typedef 3 WSZ;
typedef 1 L;
typedef TAdd#(TMul#(TSub#(WSZ,1),IMGC),WSZ) INIT_TIME;
typedef TAdd#(L,2) WT;

typedef Int#(16) Sizet;
typedef Bit#(16) Pixels;
typedef Bit#(16) BitSz;

endpackage