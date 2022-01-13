/// Builder definitons for `worker_bee_builder`.
library worker_bee_builder.builder;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:worker_bee_builder/src/generator.dart';

Builder workerBeeBuilder(BuilderOptions options) => LibraryBuilder(
      WorkerBeeGenerator(),
      generatedExtension: '.worker.dart',
    );
