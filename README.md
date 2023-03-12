# hbitsignals

Very simple bit compression and numberic signal compression library.

# Usage

## Writing

```haxe
    final INITIAL_SIZE = 1024;
    final EXPANSION_INCREMENT = 512;
    var writer = bitsignals.BitWriter.Alloc(INITIAL_SIZE, EXPANSION_INCREMENT);

    writer.addBool( true );
    writer.addInt32( 1 );
    final SINGLE_BIT = 1;
    writer.addInt(1, SINGLE_BIT);
    writer.addSingle( 3.14 );
    writer.addDouble( 3.14 );
    final QUANT_BITS = 6;
    final QUANT_MIN = 0.;
    final QUANT_MAX = 5.;
    writer.addQuantized( 3.14, QUANT_BITS, QUANT_MIN, QUANT_MAX );
    // any overhanging bits are turned into a full byte
    writer.flushBits();

    var hexStr = writer.asHex();
    var buffer = writer.getBytes();// This is the full buffer ATM, use the length bytes for the length
    var writtenBytes = writer.lengthBytes(); 
```



## Reading

```haxe
    final BYTE_OFFSET = 0;
    var reader = new bitsignals.BitReader(buffer, BYTE_OFFSET, writtenBytes);

    var b = reader.getBool();
    var i32 = reader.getInt32();
    var ib1 = reader.getInt(SINGLE_BIT);
    var s = reader.getSingle();
    var f = reader.getDouble();
    var q = reader.getQuantized(  QUANT_BITS, QUANT_MIN, QUANT_MAX );

```

