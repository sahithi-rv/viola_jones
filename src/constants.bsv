package constants;

typedef 240 IMGR;
typedef 320 IMGC;
typedef 25 WSZ;
typedef 1 L;
typedef TMul#(TAdd#(TMul#(TSub#(WSZ,1),IMGC),WSZ),3) INIT_TIME;
typedef TAdd#(L,2) WT;
typedef 2913 HF;
typedef 25 STAGES;

typedef Int#(20) Sizet_20;
typedef Bit#(20) BitSz_20;
typedef Int#(16) Sizet;
typedef Bit#(32) Pixels;
typedef Int#(32) Data_32;
typedef UInt#(32) UData_32;
typedef Bit#(16) BitSz;

endpackage