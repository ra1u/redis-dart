part of redis;
/*
 * Free software licenced under 
 * GNU AFFERO GENERAL PUBLIC LICENSE
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */

Utf8Encoder RedisSerialiseEncoder = new Utf8Encoder();

class RedisBulk {
  Iterable<int> iterable;

  /// This clase enables sending Iterable<int>
  /// as bulk data on redis
  /// it can be used when sending files for example
  RedisBulk(this.iterable) {}
}

class RedisSerialise {
  static final ASCII = const AsciiCodec();
  static final UTF8 = const Utf8Codec();
  static final _dollar = ASCII.encode("\$");
  static final _star = ASCII.encode("\*");
  static final _semicol = ASCII.encode(":");
  static final _linesep = ASCII.encode("\r\n");
  static final _dollarminus1 = ASCII.encode("\$-1");

  static List<int> Serialise(object) {
    var s = <int>[];
    SerialiseConsumable(object, (v) {
      s.addAll(v as Iterable<int>);
    });
    return s;
  }

  static void SerialiseConsumable(object, void consumer(Iterable s)) {
    if (object is String) {
      var data = UTF8.encode(object);
      consumer(_dollar);
      consumer(_IntToRaw(data.length));
      consumer(_linesep);
      consumer(data);
      consumer(_linesep);
    } else if (object is Iterable) {
      int len = object.length;
      consumer(_star);
      consumer(_IntToRaw(len));
      consumer(_linesep);
      object.forEach(
          (v) => SerialiseConsumable(v is int ? v.toString() : v, consumer));
    } else if (object is int) {
      consumer(_semicol);
      consumer(_IntToRaw(object));
      consumer(_linesep);
    } else if (object is RedisBulk) {
      consumer(_dollar);
      consumer(_IntToRaw(object.iterable.length));
      consumer(_linesep);
      consumer(object.iterable);
    } else if (object == null) {
      consumer(_dollarminus1); //null bulk
    } else {
      throw ("cant serialise such type");
    }
  }

  static Iterable<int> _IntToRaw(int n) {
    //if(i>=0 && i < _ints.length)
    //   return _ints[i];
    return ASCII.encode(n.toString());
  }
}
