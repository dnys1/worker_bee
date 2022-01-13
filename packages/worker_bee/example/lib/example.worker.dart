import 'example.dart' deferred as worker;

Future<void> main() async {
  await worker.loadLibrary();
  worker.MyWorker().run();
}
