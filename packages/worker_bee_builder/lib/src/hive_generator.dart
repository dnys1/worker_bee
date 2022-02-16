import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:worker_bee/worker_bee.dart';

class WorkerHiveGenerator extends GeneratorForAnnotation<WorkerHive> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! FunctionElement || !element.isEntryPoint) {
      throw ArgumentError(
        '@WorkerHive can only be applied to the main method.',
      );
    }

    // Collect workers
    final workerObjects = annotation.read('workers').listValue;
    final workers = workerObjects.map((obj) => obj.toTypeValue()!);

    final output = StringBuffer()
      ..writeln('final workers = <String, WorkerBeeBuilder>{');

    for (final workerType in workers) {
      final workerName = workerType.getDisplayString(withNullability: false);
      output.writeln("'$workerName': $workerName.create,");
    }

    output.writeln('};');

    return output.toString();
  }
}
