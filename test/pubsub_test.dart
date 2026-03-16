import 'package:redis/redis.dart';
import 'package:test/test.dart';
import 'package:async/async.dart';

import 'main.dart';

void main() async {
  group("Test Redis Pub-Sub", () {
    test("Publishing to channel before subscription", () async {
      Command cmdP = await generate_connect();
      Command cmdS = await generate_connect();
      PubSub subscriber = PubSub(cmdS);

      String chan = "test_pub_before_sub";
      expect(
          cmdP.send_object(["PUBLISH", chan, "hello"]), completion(equals(0)));
    });

    test("Subscribe to channel", () async {
      Command cmdP = await generate_connect();
      Command cmdS = await generate_connect();
      PubSub subscriber = PubSub(cmdS);

      String chan = "test_sub";
      expect(() => subscriber.subscribe([chan]), returnsNormally,
          reason: "No error should be thrown when subscribing to channel.");

      var queue = StreamQueue(subscriber.getStream());
      expect(await queue.next, equals(["subscribe", chan, 1]));

      expect(cmdP.send_object(["PUBSUB", "NUMSUB", chan]),
          completion(equals([chan, 1])),
          reason: "Number of subscribers should be 1 after subscription");

      expect(
          () => cmdS.send_object("PING"),
          throwsA(equals("PubSub on this connaction in progress"
              "It is not allowed to issue commands trough this handler")),
          reason: "After subscription, command should not be able to send");
    });

    test("Publishing to channel", () async {
      Command cmdP = await generate_connect();
      Command cmdS = await generate_connect();
      PubSub subscriber = PubSub(cmdS);

      String chan = "test_pub";

      expect(() => subscriber.subscribe([chan]), returnsNormally,
          reason: "No error should be thrown when subscribing to channel.");

      var queue = StreamQueue(subscriber.getStream());
      expect(await queue.next, equals(["subscribe", chan, 1]));

      expect(cmdP.send_object(["PUBLISH", chan, "goodbye"]),
          completion(equals(1)));

      expect(await queue.next, equals(["message", chan, "goodbye"]));
    });

    test("Unsubscribe channel", () async {
      Command cmdP = await generate_connect();
      Command cmdS = await generate_connect();
      PubSub subscriber = PubSub(cmdS);

      String chan = "test_unsub";
      expect(() => subscriber.unsubscribe([chan]), returnsNormally,
          reason: "No error should be thrown when subscribing to channel.");

      expect(
          subscriber.getStream(),
          emitsInOrder([
            ["unsubscribe", chan, 0],
          ]),
          reason: "After subscribing, the message should be received.");

      expect(cmdP.send_object(["PUBSUB", "NUMSUB", chan]),
          completion(equals([chan, 0])),
          reason: "Number of subscribers should be 0 after unsubscribe");

      expect(
          cmdP.send_object(["PUBLISH", chan, "goodbye"]), completion(equals(0)),
          reason:
              "Publishing a message after unsubscribe should be received by zero clients.");

      // TODO: Multiple channels, Pattern (un)subscribe
    });

    test("Test close", () async {
      Command cmdP = await generate_connect();
      Command cmdS = await generate_connect();
      PubSub subscriber = PubSub(cmdS);
      // test that we can close connection
      // creates new connection as prevously used in test
      // does not expect errors
      Command cmdClose = await generate_connect();
      PubSub ps_c = PubSub(cmdClose);
      cmdClose.get_connection().close();
      expect(ps_c.getStream(), emitsError(anything), // todo catch CloseError
          reason: "Number of subscribers should be 0 after unsubscribe");
    });
  });
}
