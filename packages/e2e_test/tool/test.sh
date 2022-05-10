#!/bin/bash
set -e

dart run build_runner build --delete-conflicting-outputs
dart compile js -o lib/workers.js lib/workers.dart
dart compile js -m -O4 -o lib/workers.min.js lib/workers.dart
dart compile js -o lib/no_workers.js lib/no_workers.dart
dart compile js -m -O4 -o lib/no_workers.min.js lib/no_workers.dart
dart test $@
