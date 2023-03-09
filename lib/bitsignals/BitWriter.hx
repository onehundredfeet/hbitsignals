package bitsignals;

import haxe.crypto.Base64;

class BitWriter {
	var _buffer:hl.Bytes;
	var _bitHead = 0;
	var _bitByte = 0;
	var _writeHead = 0;
	var _capacity = 0;

	static final INITIAL_SIZE = 1024;
	static final EXTRA_SIZE = 512;


	public function new(size:Int = 0) {
		if (size == 0) {
			size = INITIAL_SIZE;
		}

		_buffer = new hl.Bytes(INITIAL_SIZE);
		_capacity = size;
	}

	public inline function reset() {
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

		return _buffer;
	}

	public inline function getIOBytes() {
		flushBits();

		return _buffer.toBytes(_writeHead);
	}

	public function asHex() {
		flushBits();
		return Base64.encode(_buffer.toBytes(_writeHead));
	}


	public function bind(b:hl.Bytes) {
		_buffer = b;
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

	function expand(extraCapacity:Int = 0) {
		if (extraCapacity == 0) {
			extraCapacity = EXTRA_SIZE;
		}
		var newCapacity = _capacity + extraCapacity;
		var newBuffer = new hl.Bytes(newCapacity);
		newBuffer.blit(0, _buffer, 0, _capacity);
		_buffer = newBuffer;
		_capacity = newCapacity;
	}

	inline function checkCapacity(size:Int) {
		if (_writeHead + size > _capacity) {
			if (size < EXTRA_SIZE)
				expand(EXTRA_SIZE);
			else
				expand(size + EXTRA_SIZE);
		}
	}

	public function flushBits() {
		if (_bitHead > 0) {
			if (_writeHead == _capacity) {
				expand();
			}
			_buffer[_writeHead] = _bitByte;
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

	public function addInt64(v:haxe.Int64) {
		flushBits();
		checkCapacity(8);

		_buffer.setI32(_writeHead, v.low);
		_writeHead += 4;
		_buffer.setI32(_writeHead, v.high);
		_writeHead += 4;
		//		_buffer.addInt64(v);
	}

	public function addSingle(v:Float) {
		flushBits();
		checkCapacity(4);
		_buffer.setF32(_writeHead, v);
		_writeHead += 4;
	}

	public function addDouble(v:Float) {
		flushBits();
		checkCapacity(8);
		_buffer.setF64(_writeHead, v);
		_writeHead += 8;
	}

	public function quantize( v:Float, bits:Int, min:Float, max:Float)  {
		var range = max - min;
		var step = range / (1 << bits);
		var q = Math.floor((v - min) / step);
		return min + q * step;
	}
	
	public function addQuantized( v:Float, bits:Int, min:Float, max:Float)  {
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
				_buffer.setUI8(_writeHead, s.charCodeAt(i));
				_writeHead++;
			}
		}
	}
}
