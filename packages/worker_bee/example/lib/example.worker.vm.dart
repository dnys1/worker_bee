import 'package:example/example.dart';

class MyMessageImpl implements MyMessage {
  const MyMessageImpl({
    required this.message,
  });

  @override
  final String message;
}
