package bitsignals;

// Delta bits include sign bit, i.e. 1 is not a legal value
enum ESignalCompression {
	RAW;
	UNIQUE;
	DELTA(deltaBits : Int);
	RLE(runBits : Int);
}