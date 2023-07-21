/*
 * Free software licenced under 
 * GNU AFFERO GENERAL PUBLIC LICENSE
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */

part of redis;

@Deprecated('Use RedisException instead')
class RedisError extends RedisException {
  String e;

  RedisError(this.e) : super(e);

  String get error => message;

  String toString() {
    return "RedisError($message)";
  }
}

/// This class is returned when redis response is type error
class RedisException implements Exception {
  String message;

  RedisException(this.message);

  String toString() {
    return "RedisException($message)";
  }
}

@Deprecated('Use RedisRuntimeException instead')
class RedisRuntimeError extends RedisRuntimeException {
  String e;

  RedisRuntimeError(this.e) : super(e);

  String toString() {
    return "RedisRuntimeError($e)";
  }

  String get error => e;
}

/// This class is returned when parsing in client side (aka this libraray)
class RedisRuntimeException implements Exception {
  String e;

  RedisRuntimeException(this.e);

  String toString() {
    return "RedisRuntimeException($e)";
  }

  String get error => e;
}

@Deprecated('Use TransactionException instead')
class TransactionError extends RedisException {
  String e;

  TransactionError(this.e) : super(e);

  String toString() {
    return "TransactionError($e)";
  }

  String get error => e;
}

/// This class is returned when transaction fails
class TransactionException implements Exception {
  String e;

  TransactionException(this.e);

  String toString() {
    return "TranscationException($e)";
  }

  String get error => e;
}
