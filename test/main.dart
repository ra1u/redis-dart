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
import 'dart:io' show Platform;

bool g_redis_initialsed = false;
String g_db_uri = "";
int g_db_port = 0;

void init_db_vars() {
  // read REDIS_URL and REDIS_PORT from ENV and store in globals for faster retreival
  if(g_redis_initialsed)
    return;
  Map<String, String> envVars = Platform.environment;
  g_db_uri = envVars["REDIS_URL"] ?? "localhost";
  String port = envVars["REDIS_PORT"] ?? "6379";
  g_db_port = int.tryParse(port) ?? 6379;
  g_redis_initialsed = true;
} 

Future<Command> generate_connect() {
  init_db_vars();
  return RedisConnection().connect(g_db_uri, g_db_port);
}

void main() {
  setUpAll(() => generate_connect().then((cmd) => cmd.send_object("FLUSHALL")));
}
