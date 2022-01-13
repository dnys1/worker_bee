import 'package:build/build.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:worker_bee/worker_bee.dart';

class WorkerBeeGenerator extends GeneratorForAnnotation<WorkerBee> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    throw UnimplementedError();
  }
}
