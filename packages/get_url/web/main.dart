import 'pkg_b.dart' deferred as b;

void main() async {
  await b.loadLibrary();
  b.callMe();
}
