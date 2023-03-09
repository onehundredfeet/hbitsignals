// Written in haxe
package;

import utest.Runner;
import utest.ui.Report;
import utest.Assert;
import utest.Async;
import bitsignals.BitReader;
import bitsignals.BitWriter;
import bitsignals.BoolSignal;
import bitsignals.IntSignal;
import bitsignals.RemappedSignal;

class TestCase extends utest.Test {
	var writer : BitWriter;
	var bytes:haxe.io.Bytes;
	// synchronous setup
	public function setup() {}

	final Pi = 3.1415926535897931;
	final helloWorld = "Hello World";
    final TEST64 = haxe.Int64.make(0x90ABCDEF, 0x12345678);
    var _quant1F : Float;
    var _quant2F : Float;
    var _bufferLength : Int;

	function testWriter() {
        // Test auto expansion, not recommended sizing
        writer = new BitWriter(16, 16);
        var totalBytes = 0;
        var totalRawBytes = 0;
        var totalSimpleBytes = 0;
		writer.addBool(true);
        Assert.equals(writer.lengthBytes(), ++totalBytes); totalRawBytes += 4; totalSimpleBytes += 1;
		writer.addInt(0, 1);
        Assert.equals(writer.lengthBytes(), totalBytes);totalRawBytes += 4; totalSimpleBytes += 1;
		writer.addInt(1, 2);
        Assert.equals(writer.lengthBytes(), totalBytes);totalRawBytes += 4; totalSimpleBytes += 1;
		writer.addInt(2, 3);
        Assert.equals(writer.lengthBytes(), totalBytes);totalRawBytes += 4; totalSimpleBytes += 1;
		writer.addSingle(0.5);
        Assert.equals(writer.lengthBytes(), totalBytes += 4);totalRawBytes += 4; totalSimpleBytes += 4;

		writer.addDouble(Pi);
        Assert.equals(writer.lengthBytes(), totalBytes += 8);totalRawBytes += 8; totalSimpleBytes += 8;
        writer.addQuantized(0.5, 24, 0.0, 1.0);
        Assert.equals(writer.lengthBytes(), totalBytes += 3);totalRawBytes += 8; totalSimpleBytes += 8;
        _quant1F = writer.quantize(0.5, 24, 0.0, 1.0);
        writer.addQuantized(0.5, 7, 0.0, 1.0);
        Assert.equals(writer.lengthBytes(), totalBytes += 1);totalRawBytes += 8; totalSimpleBytes += 8;
        _quant2F = writer.quantize(0.5, 7, 0.0, 1.0);
        trace('Quantized values are ${_quant1F} and ${_quant2F}');

		writer.addString(helloWorld, 8);
        Assert.equals(writer.lengthBytes(), totalBytes += helloWorld.length + 1); totalRawBytes +=  helloWorld.length + 1; totalSimpleBytes += helloWorld.length + 1;
		writer.addBool(false);
        Assert.equals(writer.lengthBytes(), ++totalBytes); totalRawBytes += 4; totalSimpleBytes += 1;
		writer.addInt16(0x1234);
        Assert.equals(writer.lengthBytes(), totalBytes += 2);  totalRawBytes += 4; totalSimpleBytes += 2;
		writer.addInt32(0x12345678);
        Assert.equals(writer.lengthBytes(), totalBytes += 4);  totalRawBytes += 4; totalSimpleBytes += 4;
		writer.addBool(true);
        Assert.equals(writer.lengthBytes(), totalBytes);  totalRawBytes += 4; totalSimpleBytes += 1;
		writer.addInt64(TEST64);
        Assert.equals(writer.lengthBytes(), totalBytes += 8);  totalRawBytes += 8; totalSimpleBytes += 8;
		writer.addBool(false);
        Assert.equals(writer.lengthBytes(), ++ totalBytes);  totalRawBytes += 4; totalSimpleBytes += 1;
        writer.flushBits();
        Assert.equals(writer.lengthBytes(), totalBytes);
        trace('Writer length is ${writer.lengthBytes()} over raw ${totalRawBytes} and simple ${totalSimpleBytes}');
        bytes = writer.getIOBytes();
        _bufferLength = writer.lengthBytes();
        trace('Backing buffer size ${bytes.length}');
	}

	function testReader() {
        var reader = new BitReader(bytes, 0, _bufferLength);
        Assert.isTrue(reader.getBool());
        Assert.equals(reader.getInt(1), 0);
        Assert.equals(reader.getInt(2), 1);
        Assert.equals(reader.getInt(3), 2);
        Assert.equals(reader.getSingle(), 0.5);
        Assert.equals(reader.getDouble(), Pi);
        Assert.equals(reader.getQuantized(24, 0.0, 1.0), _quant1F);   
        Assert.equals(reader.getQuantized(7, 0.0, 1.0), _quant2F);                
        Assert.equals(reader.getString(8), helloWorld);
        Assert.isFalse(reader.getBool());
        Assert.equals(reader.getInt16(), 0x1234);
        Assert.equals(reader.getInt32(), 0x12345678);
        Assert.isTrue(reader.getBool());
        Assert.equals(reader.getInt64(), TEST64);
        Assert.isFalse(reader.getBool());
        Assert.equals(0, reader.bytesRemaining);

	}

}

class Test {
	public static function main() {
		/*
			var runner = new Runner();
			runner.addCase(new TestCase());
			runner.addCase(new TestCase2());
			Report.create(runner);
			runner.run();
		 */
		// the short way in case you don't need to handle any specifics
		utest.UTest.run([new TestCase()]);
	}
}
