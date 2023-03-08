package bitsignals;

import bitsignals.ESignalCompression;


interface SerializableSignal {
	 function write(ctx:BitWriter, depth : Int) : Void;
	 function read(ctx:BitReader, depth : Int) : Void;
}

class IntSignal implements SerializableSignal {
	var _bits = 31;
	var _offset = 0;
	var _history:Array<Int>;
	var _loc = -1;
	var _mask:UInt = 0;
	var _compression:ESignalCompression;

	var _runBits = 0;
	var _runMax = 0;
	var _deltaBits = -1;
	var _deltaMax = 0;
	var _deltaMask:UInt = 0;


	public function new(bits, min, historyDepth:Int, compression:ESignalCompression,  defaultValue:Int = 0) {
		_bits = bits;
		_offset = min;
		_history = [for (c in 0...historyDepth) defaultValue];
		final MASK:UInt = 0xffffffff;
		_mask = MASK >> (32 - _bits);
		_compression = compression;
		switch(compression) {
			case RLE(runBits): 
				_runBits = runBits;
				_runMax = ((1 << _runBits) - 1);
			case DELTA(deltaBits): 
				if(deltaBits <= 1) throw "Delta bits must be greater than 1";
				_deltaBits = deltaBits - 1; 
				_deltaMax = (1 << _deltaBits); // isn't -1 because we don't use 0
				_deltaMask = MASK >> (32 - _deltaBits);
			default:
		}
	}

	public function push(v:Int) : Int {
		v = (v - _offset) & _mask;
		_loc = (_loc + 1) % _history.length;
		_history[_loc] = v;

		return v + _offset;
	}
	public function history(delta : Int) {
		var i = (_loc - delta + _history.length) % _history.length;
		return _history[i] + _offset;
	}

	function relativeIndex(i : Int) {
		return (_loc - i + _history.length) % _history.length;
	}

	public function write(ctx:BitWriter, depth : Int) {

		switch (_compression) {
			case ESignalCompression.RAW:
				for (i in 0...depth) {
					var idx = relativeIndex(i);
					ctx.addInt(_history[idx], _bits);
				}
			case ESignalCompression.UNIQUE:
				var x = 0;
				for (i in 0...depth) {
					var idx = relativeIndex(i);
					if (_history[idx] != x) {
						ctx.addBool(true);
						x = _history[idx];
						ctx.addInt(x, _bits);
					} else {
						ctx.addBool(false);
					}
				}
			case ESignalCompression.DELTA(_):
				var x = 0;
				for (i in 0...depth) {
					var idx = relativeIndex(i);
					if (_history[idx] != x) {
						ctx.addBool(true);
						var xn = _history[idx];
						var d = xn - x;
						x = xn;
						if (d < 0 && -d <= _deltaMax) {
							ctx.addBool(true);
							ctx.addBool(true);
							ctx.addInt(((-d) - 1) & _deltaMask, _deltaBits);
						} else if (d > 0 && d <= _deltaMax) {
							ctx.addBool(true);
							ctx.addBool(false);
							ctx.addInt((d - 1) & _deltaMask, _deltaBits);
						} else {
							ctx.addBool(false);
							ctx.addInt(x & _mask, _bits);
						}
					} else {
						ctx.addBool(false);
					}
				}
            case ESignalCompression.RLE(_):
                var x = 0;
                var i = 0;

				while (i < depth) {
					var idx = relativeIndex(i);
                    x = _history[idx];
                    ctx.addInt(x, _bits);

                    var headCount = i + 1;
					
                    while (headCount < depth) {
                        var headIdx = relativeIndex(headCount); 
                        if (_history[headIdx] != x)
                            break;
						headCount++;
                    }
					var delta = headCount - i;
					if (delta == 1) {
						ctx.addBool(false);
						i++;
					} else {
						ctx.addBool(true);
						delta -= 2;
						if (delta > _runMax) {
							delta = _runMax;
						}
						ctx.addInt(delta, _runBits );
						i += delta + 2;
					}
				}
			default:
		}
	}

	public function read(ctx:BitReader, depth : Int) {
		_loc = 0;

		switch (_compression) {
			case ESignalCompression.RAW:
                for (i in 0...depth) {
					_history[relativeIndex(i)] = ctx.getInt(_bits);
				}
			case ESignalCompression.UNIQUE:
				var x = 0;
				for (i in 0...depth) {
					if (ctx.getBool()) {
						x = ctx.getInt(_bits);
					}
					_history[relativeIndex(i)] = x;
					
				}
			case ESignalCompression.DELTA(_):
				var x = 0;
				for (i in 0...depth) {
					// is there a change?
					if (ctx.getBool()) {
						// is the change small?
						if (ctx.getBool()) {
							//small
							// Is it negative? 
							var d = ctx.getBool() ?  - ctx.getInt(_deltaBits) - 1 : ctx.getInt(_deltaBits) + 1; // Adds 1 to magnitude
							x = x + d;
						} else {
							//normal
							x = ctx.getInt(_bits);
						}
					}
					_history[relativeIndex(i)] = x;
					
				}
			case ESignalCompression.RLE(_):
				var x = 0;
                var i = 0;
				while (i < depth) {
					x = ctx.getInt(_bits);
					if (ctx.getBool()) {
						//run
						var delta = ctx.getInt(_runBits) + 2;
						for (j in 0...delta) {
							_history[relativeIndex(i)] = x;
							i++;
						}
					} else {
						// different value
						_history[relativeIndex(i)] = x;
						i++;
					}

				}
                default:
			
		}
	}
}
