import 'package:build/build.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:worker_bee/worker_bee.dart';
import 'package:worker_bee_builder/src/message.dart';

class WorkerBeeGenerator extends GeneratorForAnnotation<WorkerBee> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw ArgumentError('@WorkerBee can only be applied to classes.');
    }

    // Get generic arguments
    final supertype = element.supertype;
    if (supertype == null || supertype.element.name != 'WorkerBeeBase') {
      throw ArgumentError(
          '@WorkerBee classes must extends WorkerBeeBase<M, R>.');
    }
    final typeArgs = supertype.typeArguments;
    if (typeArgs.length != 2) {
      throw ArgumentError('@WorkerBee classes must declare their types.');
    }

    // Look up message type to generate JS/VM implementations.
    final messageType = typeArgs[0];
    final messageTypeEl = messageType.element;
    if (messageTypeEl == null || messageTypeEl is! ClassElement) {
      throw ArgumentError(
          'Could not find element for ${messageType.getDisplayString(withNullability: true)}.');
    }
    final messageImpls = await MessageGenerator(messageTypeEl).generate();

    for (final messageImpl in messageImpls) {
      final target = messageImpl.target.name;
      final assetId = buildStep.inputId.changeExtension('.worker.$target.dart');
      await buildStep.writeAsString(assetId, messageImpl.impl);
    }

    return '';
  }
}
