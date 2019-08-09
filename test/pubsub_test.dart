// helper function to check
// if Stream data is same as provided test Iterable
import 'dart:async';
import 'dart:cli';

import 'package:redis/redis.dart';
import 'package:test/test.dart';

import 'main.dart';

void main() {
  group("Test Redis Pub-Sub", () {
    Command cmdP = waitFor(generate_connect());
    Command cmdS = waitFor(generate_connect());

    PubSub subscriber = PubSub(cmdS);

    test("Publishing to channel before subscription", () {
      expect(cmdP.send_object(["PUBLISH", "test", "hello"]),
          completion(equals(0)));
    });

    test("Subscribe to channel", () {
      expect(() => subscriber.subscribe(["test"]), returnsNormally,
          reason: "No error should be thrown when subscribing to channel.");

      expect(cmdP.send_object(["PUBSUB", "NUMSUB", "test"]),
          completion(equals(["test", 1])),
          reason: "Number of subscribers should be 1 after subscription");

      expect(() => cmdS.send_object("PING"),
          throwsA(equals("PubSub on this connaction in progress"
              "It is not allowed to issue commands trough this handler")),
          reason: "After subscription, command should not be able to send");
    });

    test("Publishing to channel", () {
      expect(cmdP.send_object(["PUBLISH", "test", "goodbye"]),
          completion(equals(1)));

      expect(subscriber.getStream(), emitsInOrder(
          [["subscribe", "test", 1], ["message", "test", "goodbye"]]),
          reason: "After subscribing, the message should be received.");
    });


    test("Unsubscribe channel", () {
      expect(() => subscriber.unsubscribe(["test"]), returnsNormally,
          reason: "No error should be thrown when subscribing to channel.");

      expect(cmdP.send_object(["PUBSUB", "NUMSUB", "test"]),
          completion(equals(["test", 0])),
          reason: "Number of subscribers should be 0 after unsubscribe");

      expect(cmdP.send_object(["PUBLISH", "test", "goodbye"]),
          completion(equals(0)),
          reason: "Publishing a message after unsubscribe should be received by zero clients.");

      // TODO: Multiple channels, Pattern (un)subscribe
    });
  });
}