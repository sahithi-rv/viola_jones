package constants;

typedef 240 IMGR;
typedef 320 IMGC;
typedef 20 WSZ;
typedef 1 L;
typedef TAdd#(TMul#(TSub#(WSZ,1),IMGC),WSZ) INIT_TIME;
typedef TAdd#(L,2) WT;
typedef 2913 HF;
typedef 25 STAGES;

typedef Int#(20) Sizet_20;
typedef Bit#(20) BitSz_20;
typedef Int#(16) Sizet;
typedef Bit#(16) Pixels;
typedef Bit#(16) BitSz;

endpackage