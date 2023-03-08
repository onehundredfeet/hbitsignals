package bitsignals;


class RemappedSignal extends IntSignal {
	var _min = 0.;
	var _max = 1.;
	var _range = 1.;
	var _rangeScaled = 1.;
	var _inverse = 1.;
	var _inverseScaled = 1.;

	public function new(bits, min : Float, max : Float, accurateCenter : Bool, historyDepth:Int, compression:ESignalCompression, def:Int = 0) {
		super(bits, 0, historyDepth, compression, def);

		#if !release
		if (bits == 1 && accurateCenter) throw "You stupid, yo? 1 Bit is only two values, how do you have a center?";
		#end

		var maxInt = (1 << bits - 1) - (accurateCenter ? 1 : 0);
		
		_min = min;
		_max = max;
		_range = _max - _min;
		_inverse = 1. / _range;
		_inverseScaled =  maxInt / _range;
		_rangeScaled = _range / maxInt;
	}

	public inline function simulate(x : Float) : Float {
		var c = Math.min( _max, Math.max( _min, x ));
		var y = Math.round((c - _min) * _inverseScaled);

		return (y * _rangeScaled) + _min;
	}
	public inline function pushRemapped( x : Float )  {
		var c = Math.min( _max, Math.max( _min, x ));
		var y = Math.round((c - _min) * _inverseScaled);
		push( y );
	}

	public inline function remapHistory( d : Int ) {
		var x = history(d);
		return (x * _rangeScaled) + _min;
	}
}
