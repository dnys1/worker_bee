#!/bin/bash
set -e

dart run build_runner build --delete-conflicting-outputs
dart compile js -o lib/workers.js lib/workers.dart
dart compile js -m -O4 -o lib/workers.min.js lib/workers.dart
dart test $@
