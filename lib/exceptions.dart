/*
 * Free software licenced under
 * MIT License
 *
 * Check for document LICENCE forfull licence text
 *
 * Luka Rahne
 */

part of redis;

/// Thrown when Redis server returns an error response
class RedisException implements Exception {
  final String message;

  RedisException(this.message);

  @override
  String toString() => "RedisException($message)";
}

/// Thrown when a client-side parsing or protocol error occurs
class RedisRuntimeException implements Exception {
  final String message;

  RedisRuntimeException(this.message);

  @override
  String toString() => "RedisRuntimeException($message)";
}

/// Thrown when a Redis transaction fails
class TransactionException implements Exception {
  final String message;

  TransactionException(this.message);

  @override
  String toString() => "TransactionException($message)";
}
