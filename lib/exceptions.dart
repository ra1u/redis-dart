/*
 * Free software licenced under 
 * GNU AFFERO GENERAL PUBLIC LICENSE
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */

part of redis;


class RedisError  {
  String e;
  RedisError(this.e);
  String toString() { return "RedisError($e)";}
}


class TransactionError  {
  String e;
  TransactionError(this.e);
  String toString() { return "TranscationError($e)";}
}

