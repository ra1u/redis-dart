/*
 * Free software licenced under 
 * GNU AFFERO GENERAL PUBLIC LICENSE
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */

part of redis;


// this class is returned when redis response is type error
class RedisError  {
  String e;
  RedisError(this.e);
  String toString() { return "RedisError($e)";}
  String get error => e;
}

// thiss class is returned when parsing in client side (aka this libraray)
// get error
class RedisRuntimeError  {
  String e;
  RedisRuntimeError(this.e);
  String toString() { return "RedisRuntimeError($e)";}
  String get error => e;
}

class TransactionError  {
  String e;
  TransactionError(this.e);
  String toString() { return "TranscationError($e)";}
  String get error => e; 
}
