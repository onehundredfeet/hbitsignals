package bitsignals;

class BoolSignal extends IntSignal {
	public function new(historyDepth:Int, compression:ESignalCompression, def:Int = 0) {
		super(1, 0, historyDepth, compression, def);

	}

	public function pushBool( v : Bool ) : Bool {
		push(v ? 1 : 0);
        return v;
	}

	public function boolHistory( d : Int ) : Bool{
		var x = history(d);
		return x > 0;
	}

    public function edgeHistory( d : Int ) : Bool {
        var x = history(d);
        var y = history(d + 1);

        return x != y;

    }
}
