package bitsignals;

import haxe.crypto.Base64;

// Auto expends by EXTRA_SIZE
class BitWriter {
	static inline final INITIAL_SIZE = 1024;
	static inline final EXTRA_SIZE = 512;
	var _buffer:haxe.io.Bytes;
	var _bitHead = 0;
	var _bitByte = 0;
	var _writeHead = 0;
	var _capacity = 0;

	var _expansionSize = EXTRA_SIZE;


	function new(b:haxe.io.Bytes, offset : Int = 0, capacity = -1, expansionSize:Int = -1) {
		_buffer = b;
		_writeHead = offset;
		_capacity = capacity > 0 ? capacity : b.length;
		_expansionSize = expansionSize > -1 ? expansionSize : EXTRA_SIZE;
	}

	public static function makeFromSharedBuffer(b:haxe.io.Bytes, offset : Int = 0, capacity = -1) {
		return new BitWriter(b, offset, capacity, 0);
	}

	public static function alloc(capacity : Int = INITIAL_SIZE, expansionSize : Int = 0) {
		return new BitWriter(haxe.io.Bytes.alloc(capacity), 0, capacity, expansionSize);
	}

	public inline function rewind() {
		_bitHead = 0;
		_bitByte = 0;
		_writeHead = 0;
	}


	public inline function bitLength() {
		return _writeHead * 8 + _bitHead;
	}

	public inline function lengthBytes() {
		return _writeHead + (_bitHead > 0 ? 1 : 0);
	}

	public inline function getBytes() {
		flushBits();

		var hb : hl.Bytes = _buffer;
		return hb.toBytes(_writeHead);
	}

	public inline function getIOBytes() {
		flushBits();

		return _buffer;
	}

	public function asHex() {
		flushBits();
		return _buffer.toHex(); //Base64.encode(_buffer.toBytes(_writeHead));
	}


	public function bind(b:haxe.io.Bytes, length : Int = -1) {
		_buffer = b;
		if (length > -1) {
			_capacity = length;
		} else {
			_capacity = b.length;
		}
		
		rewind();
	}

	inline function getAvailableBits() {
		return 8 - _bitHead;
	}

	inline function clipBits(bits:Int) {
		return bits > getAvailableBits() ? getAvailableBits() : bits;
	}

	inline function advanceBits(bits:Int) {
		_bitHead += bits;
	}

	function expand(extraCapacity:Int = -1) {
		if (extraCapacity == -1) {
			extraCapacity = _expansionSize;
		}
		if (extraCapacity == 0) {
			throw "Cannot expand buffer with 0 expansion capability";
		}

		var newCapacity = _capacity + extraCapacity;
		var newBuffer = haxe.io.Bytes.alloc(newCapacity);
		newBuffer.blit(0, _buffer, 0, _capacity);
		_buffer = newBuffer;
		_capacity = newCapacity;
	}

	inline function checkCapacity(size:Int) {
		if (_writeHead + size > _capacity) {
			throw("Not supported");
			var count = Std.int(Math.ceil(size / _expansionSize));
			expand(_expansionSize * count);
		}
	}

	public function flushBits() {
		if (_bitHead > 0) {
			if (_writeHead == _capacity) {
				expand();
			}
			_buffer.set(_writeHead,_bitByte);
			_bitByte = 0;
			_bitHead = 0;
			_writeHead++;
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

	public inline function addBool(b:Bool) {
		addBits(b ? 1 : 0, 1);
	}

	public inline function addByte(v:Int) {
		addInt(v, 8);
	}

	public inline function addInt32(v:Int) {
		addInt(v, 32);
	}

	public inline function addInt16(v:Int) {
		addInt(v, 16);
	}

	public inline function addIntFlex(v:Int) {
		if (v > 127) {
			addBits(1, 1);
			if (v > 32767) {
				addBits(1, 1);
				addInt(v, 32);
			} else {
				addBits(0, 1);
				addInt(v, 15);
			}
		} else {
			addBits(0, 1);
			addInt(v, 7);
		}
	}

	public inline function addInt64(v:haxe.Int64) {
		flushBits();
		checkCapacity(8);

		_buffer.setInt32(_writeHead, v.low);
		_writeHead += 4;
		_buffer.setInt32(_writeHead, v.high);
		_writeHead += 4;
		//		_buffer.addInt64(v);
	}

	public inline function addSingle(v:Float) {
		flushBits();
		checkCapacity(4);
		_buffer.setFloat(_writeHead, v);
		_writeHead += 4;
	}

	public inline function addDouble(v:Float) {
		flushBits();
		checkCapacity(8);
		_buffer.setDouble(_writeHead, v);
		_writeHead += 8;
	}

	public inline function quantize( v:Float, bits:Int, min:Float, max:Float)  {
		var range = max - min;
		var step = range / (1 << bits);
		var q = Math.floor((v - min) / step);
		return min + q * step;
	}

	public inline function addQuantized( v:Float, bits:Int, min:Float, max:Float)  {
		var range = max - min;
		var step = range / (1 << bits);
		var q = Math.floor((v - min) / step);
		addInt(q, bits);
	}

	public function addString(s:String, lengthBits:Int = 16) {
		if (s == null) {
			addInt(0, lengthBits);
		}
		else {
			var b = haxe.io.Bytes.ofString(s);
			addInt(b.length, lengthBits);
			flushBits();
			for (i in 0...b.length) {
				_buffer.set(_writeHead, s.charCodeAt(i));
				_writeHead++;
			}
		}
	}
}
