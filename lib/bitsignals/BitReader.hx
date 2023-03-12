package bitsignals;

class BitReader {
	public function new(b:haxe.io.Bytes, offset:Int = 0, length:Int = -1) {
		_buffer = b;
		if (length == -1)
			length = b.length - offset;
		_capacity = length;
		_readHead = offset;
		_offset = offset;
	}
	public function asHex() {
		return haxe.crypto.Base64.encode(_buffer);
	}
	var _buffer:haxe.io.Bytes;
	var _readHead = 0;
	var _bitHead = 8;
	var _bitByte = 0;
	var _offset = 0;
	var _capacity = 0;

	public function reset(offset:Int = -1, length:Int = -1) {
		if (offset == -1)
			offset = _offset;
		else 
			_offset = offset;

		if (length == -1) {
			length = _buffer.length - offset;
		}
		if (length + offset > _buffer.length) {
			throw "BitReader: reset() length + offset > buffer.length";
		}

		_capacity = length;
	}
	public inline function discardBits() {
		_bitHead = 8;
		_bitByte = 0;
	}

	inline function cacheBits() {
		if (_bitHead >= 8) {
			_bitByte = nextByte();
			_bitHead = 0;
		}
	}

	public var bytesRemaining(get, null):Int;
	function get_bytesRemaining() {
		return _capacity - _readHead;
	}

	function getAvailableBits() {
		return 8 - _bitHead;
	}

	inline function clipBits(bits:Int) {
		return bits > getAvailableBits() ? getAvailableBits() : bits;
	}

	inline function advanceBits(bits:Int) {
		_bitHead += bits;
	}

	inline function getBits(bits:UInt):UInt {
		return (_bitByte >> _bitHead) & (0xff >> (8 - bits));
	}

	public inline function getBool():Bool {
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
	public inline function getInt32() {
		return getInt(32);
	}

	public inline function getInt16() {
		return getInt(16);
	}
	public inline function getInt64() {
		discardBits();
		var low = getInt(32);
		var high = getInt(32);
		return haxe.Int64.make(high, low);
	}
	function nextByte() {
		return _buffer.get(_readHead++);
	}

	public function getDouble() {
		discardBits();
		var v = _buffer.getDouble(_readHead);
		_readHead += 8;
		return v;
	}

	public function getSingle() {
		discardBits();
		var v = _buffer.getFloat(_readHead);
		_readHead += 4;
		return v;
	}

	public function bind(b:haxe.io.Bytes, length : Int = -1) {
		_buffer = b;
		if (length > -1) {
			_capacity = length;
		} else {
			_capacity = b.length;
		}
		_offset = 0;

		reset();
	}
	

	public function getQuantized(bits:UInt = 32, min:Float = 0, max:Float = 1) {
		return min + (max - min) * (getInt(bits) / (1 << bits));
	}
	public function getString(lengthBits = 16) {
		var length = getInt(lengthBits);
		if (length > 0) {
			discardBits();
			var str = _buffer.getString(_readHead, length);
			_readHead += length;
			return str;
	
		}
		return "";
	}
	
}
