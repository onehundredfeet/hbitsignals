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
	var writer = new BitWriter();
	var bytes:haxe.io.Bytes;
	// synchronous setup
	public function setup() {}

	final Pi = 3.1415926535897931;
	final helloWorld = "Hello World";
    final TEST64 = haxe.Int64.make(0x90ABCDEF, 0x12345678);
	function testWriter() {
        var totalBytes = 0;
		writer.addBool(true);
        Assert.equals(writer.lengthBytes(), ++totalBytes);
		writer.addInt(0, 1);
        Assert.equals(writer.lengthBytes(), totalBytes);
		writer.addInt(1, 2);
        Assert.equals(writer.lengthBytes(), totalBytes);
		writer.addInt(2, 3);
        Assert.equals(writer.lengthBytes(), totalBytes);
		writer.addSingle(0.5);
        Assert.equals(writer.lengthBytes(), totalBytes += 4);

		writer.addDouble(Pi);
        Assert.equals(writer.lengthBytes(), totalBytes += 8);

		writer.addString(helloWorld, 8);
        Assert.equals(writer.lengthBytes(), totalBytes += helloWorld.length + 1);
		writer.addBool(false);
        Assert.equals(writer.lengthBytes(), ++totalBytes);
		writer.addInt16(0x1234);
        Assert.equals(writer.lengthBytes(), totalBytes += 2);
		writer.addInt32(0x12345678);
        Assert.equals(writer.lengthBytes(), totalBytes += 4);
		writer.addBool(true);
        Assert.equals(writer.lengthBytes(), totalBytes);
		writer.addInt64(TEST64);
        Assert.equals(writer.lengthBytes(), totalBytes += 8);
		writer.addBool(false);
        Assert.equals(writer.lengthBytes(), ++ totalBytes);
        writer.flushBits();
        Assert.equals(writer.lengthBytes(), totalBytes);
        trace('Writer length is ${writer.lengthBytes()}');
        bytes = writer.getIOBytes();
	}

	function testReader() {
        var reader = new BitReader(bytes);
        Assert.isTrue(reader.getBool());
        Assert.equals(reader.getInt(1), 0);
        Assert.equals(reader.getInt(2), 1);
        Assert.equals(reader.getInt(3), 2);
        Assert.equals(reader.getSingle(), 0.5);
        Assert.equals(reader.getDouble(), Pi);
        Assert.equals(reader.getString(8), helloWorld);
        Assert.isFalse(reader.getBool());
        Assert.equals(reader.getInt16(), 0x1234);
        Assert.equals(reader.getInt32(), 0x12345678);
        Assert.isTrue(reader.getBool());
        Assert.equals(reader.getInt64(), TEST64);
        Assert.isFalse(reader.getBool());
        Assert.equals(reader.bytesRemaining, 0);

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
