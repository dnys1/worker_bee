/// Builder definitons for `worker_bee_builder`.
library worker_bee_builder.builder;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:worker_bee_builder/src/hive_generator.dart';
import 'package:worker_bee_builder/src/worker_generator.dart';

Builder workerBeeBuilder(BuilderOptions options) => LibraryBuilder(
      WorkerBeeGenerator(),
      generatedExtension: '.worker.dart',
      additionalOutputExtensions: [
        '.worker.vm.dart',
        '.worker.js.dart',
      ],
    );

Builder workerHiveBuilder(BuilderOptions options) => SharedPartBuilder(
      [WorkerHiveGenerator()],
      'worker_hive',
    );
