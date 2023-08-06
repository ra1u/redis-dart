import 'package:mockito/mockito.dart';
import 'package:redis/redis.dart';
import 'package:test/test.dart';

import 'main.dart';

class MockOnNewMessageCallback extends Mock {
  void call(dynamic message, String? channel);
}

void main() async {
  Command cmdP = await generate_connect();
  Command cmdS = await generate_connect();

  group("Test Redis Pub-Sub subscribe with onMessage callback", () {
    PubSub subscriber = PubSub(cmdS);

    test("Subscribe to channel and listen via callback", () async {
      final mockOnNewMessageCallback = MockOnNewMessageCallback();

      subscriber.subscribe(
        ["chat_room"],
        onMessage: mockOnNewMessageCallback,
      );
      subscriber.subscribe(
        ["chat_room2"],
        onMessage: mockOnNewMessageCallback,
      );

      await cmdP.send_object(["PUBLISH", "chat_room", "goodbye"]);
      await cmdP.send_object(["PUBLISH", "chat_room2", "hello"]);

      // wait for the callback is triggered completely
      await Future.delayed(Duration(milliseconds: 500));

      verify(mockOnNewMessageCallback("goodbye", "chat_room")).called(1);
      verify(mockOnNewMessageCallback("hello", "chat_room2")).called(1);
    });
  });
}
