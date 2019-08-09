/*
 * Free software licenced under 
 * GNU AFFERO GENERAL PUBLIC LICENSE
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */

import 'dart:async';

import 'package:redis/redis.dart';
import 'package:test/test.dart';

Future<Command> generate_connect() {
  return RedisConnection().connect('localhost', 6379);
}

void main() {
  setUpAll(() => generate_connect().then((cmd) => cmd.send_object("FLUSHALL")));

}
