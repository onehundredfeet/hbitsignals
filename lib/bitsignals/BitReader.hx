package bitsignals;

class BitReader {
	public function new(b:haxe.io.Bytes) {
		_in = b;
	}
	public function asHex() {
		return haxe.crypto.Base64.encode(_in);
	}
	var _in:haxe.io.Bytes;
	var _inPos = 0;
	var _bitHead = 8;
	var _bitByte = 0;

	public function discardBits() {
		_bitHead = 8;
		_bitByte = 0;
	}

	function cacheBits() {
		if (_bitHead >= 8) {
			_bitByte = nextByte();
			_bitHead = 0;
		}
	}

	function getAvailableBits() {
		return 8 - _bitHead;
	}

	function clipBits(bits:Int) {
		return bits > getAvailableBits() ? getAvailableBits() : bits;
	}

	function advanceBits(bits:Int) {
		_bitHead += bits;
	}

	function getBits(bits:UInt):UInt {
		return (_bitByte >> _bitHead) & (0xff >> (8 - bits));
	}

	public function getBool():Bool {
		cacheBits();
		var x = getBits(1) > 0;
		advanceBits(1);

		return x;
	}

	public function getInt(bits:UInt = 32):UInt {
		if (bits == 0)
			return 0;

		var offset = 0;
		var result:UInt = 0;
		while (offset < bits) {
			cacheBits();
			var batch = clipBits(bits - offset);
			result |= getBits(batch) << offset;
			offset += batch;
			advanceBits(batch);
		}

		return result;
	}

	function nextByte() {
		return _in.get(_inPos++);
	}

	public function getDouble() {
		var v = _in.getDouble(_inPos);
		_inPos += 8;
		return v;
	}

	public function getSingle() {
		var v = _in.getFloat(_inPos);
		_inPos += 4;
		return v;
	}
	/*

		public function getVector<T>(f:Void->T):haxe.ds.Vector<T> {
			var len = getInt();
			if (len == 0)
				return null;
			len--;
			var a = new haxe.ds.Vector<T>(len);
			for (i in 0...len)
				a[i] = f();
			return a;
		}



		@:extern public function getMap<K, T>(fk:Void->K, ft:Void->T):Map<K, T> {
			var len = getInt();
			if (len == 0)
				return null;
			var m = new Map<K, T>();
			while (--len > 0) {
				var k = fk();
				var v = ft();
				m.set(k, v);
			}
			return m;
		}


		public function skip(size) {
			inPos += size;
		}

		public function getInt32() {
			var v = input.getInt32(inPos);
			inPos += 4;
			return v;
		}

		public function getInt64() {
			var v = input.getInt64(inPos);
			inPos += 8;
			return v;
		}

		public function getDouble() {
			var v = input.getDouble(inPos);
			inPos += 8;
			return v;
		}

		public function getFloat() {
			var v = input.getFloat(inPos);
			inPos += 4;
			return v;
		}



		public function addBytes(b:haxe.io.Bytes) {
			if (b == null)
				addByte(0);
			else {
				addInt(b.length + 1);
				out.add(b);
			}
		}
	 */
}
