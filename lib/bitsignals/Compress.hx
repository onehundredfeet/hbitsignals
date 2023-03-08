package bitsignals;

function compressFloat( x : Float, o : Float, s : Float, bits : Int ) : Int {
    final MAX_INTF : Float = ((1 << bits) - 1);
    var a = (x - o) * (MAX_INTF / s );
    return Math.floor(a);
}

function decompressFloat( x : Int, o : Float, s : Float, bits : Int ) : Float {
    final MAX_INTF : Float = ((1 << bits) - 1);
    var a = x * (s / MAX_INTF) + o;
    return a;
}