/*
 * Free software licenced under 
 * MIT License
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */

part of redis;

@Deprecated('Use RedisException instead')
class RedisError {
  String e;

  RedisError(this.e);

  String get error => e;

  String toString() {
    return "RedisError($e)";
  }
}

/// This class is returned when redis response is type error
// ignore: deprecated_member_use_from_same_package
class RedisException extends RedisError implements Exception {
  RedisException(String message) : super(message);

  String toString() {
    return "RedisException($e)";
  }
}

@Deprecated('Use RedisRuntimeException instead')
class RedisRuntimeError {
  String e;

  RedisRuntimeError(this.e);

  String get error => e;

  String toString() {
    return "RedisRuntimeError($e)";
  }
}

/// This class is returned when parsing in client side (aka this libraray)
// ignore: deprecated_member_use_from_same_package
class RedisRuntimeException extends RedisRuntimeError implements Exception {
  RedisRuntimeException(String message) : super(message);

  String toString() {
    return "RedisRuntimeException($e)";
  }
}

@Deprecated('Use TransactionException instead')
class TransactionError {
  String e;

  TransactionError(this.e);

  String get error => e;

  String toString() {
    return "TransactionError($e)";
  }
}

/// This class is returned when transaction fails
// ignore: deprecated_member_use_from_same_package
class TransactionException extends TransactionError implements Exception {
  TransactionException(String message) : super(message);

  String get error => e;

  String toString() {
    return "TransactionException($e)";
  }
}
