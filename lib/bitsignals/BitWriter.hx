package bitsignals;

import haxe.crypto.Base64;

class BitWriter {
	var _out:haxe.io.BytesBuffer;
    var _bitHead = 0;
    var _bitByte = 0;

	public function bitLength() {
		return _out.length * 8 + _bitHead; 
	}
	public function getBytes() {
		flushBits();

		return _out.getBytes();
	}
	public function asHex() {
		return Base64.encode(_out.getBytes());
	}
	public function new(b:haxe.io.BytesBuffer = null) {

		if (b == null) {
			_out = new haxe.io.BytesBuffer();
		} else {
			_out = b;
		}
		
	}

	public function bind(b:haxe.io.BytesBuffer) {
		_out = b;
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

	public function flushBits() {
		if (_bitHead > 0) {
			_out.addByte(_bitByte);
			_bitByte = 0;
			_bitHead = 0;
		}
	}

	 function addBits(v:UInt, bits:UInt) {
		if (bits > getAvailableBits())
			bits = getAvailableBits();

		var xv = v & (0xff >> (8 - bits));

		_bitByte |= xv << _bitHead;
		_bitHead += bits;
		if (_bitHead == 8) {
			flushBits();
		}

		return bits;
	}

	public function addInt(v:Int, bits:UInt = 32) {
		while (bits > 0) {
			var consumed = addBits(v, bits);
			v = v >> consumed;
			bits -= consumed;
		}
	}

	public function addBool(b:Bool) {
		addBits(b ? 1 : 0, 1);
	}

	public function addByte(v:Int) {
		addBits(v, 8);
	}

	public function addInt32(v:Int) {
		addBits(v, 32);
	}

	public function addInt64(v:haxe.Int64) {
        flushBits();
		_out.addInt64(v);
	}

	public function addFloat(v:Float) {
        flushBits();
		_out.addFloat(v);
	}

	public function addDouble(v:Float) {
        flushBits();
		_out.addDouble(v);
	}

	public function addString(s:String, lengthBits : Int = 16) {
		flushBits();
		if (s == null)
			addByte(0);
		else {
			var b = haxe.io.Bytes.ofString(s);
			addInt(b.length + 1, lengthBits);
			_out.add(b);
		}
	}

}
