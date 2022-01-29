import 'package:build/build.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;
import 'package:source_gen/source_gen.dart';
import 'package:worker_bee/worker_bee.dart';
import 'package:worker_bee_builder/src/message/common.dart';
import 'package:worker_bee_builder/src/message/js.dart';
import 'package:worker_bee_builder/src/message/vm.dart';

class WorkerBeeGenerator extends GeneratorForAnnotation<WorkerBee> {
  DartEmitter get emitter => DartEmitter(
        allocator: Allocator(),
        orderDirectives: true,
        useNullSafetySyntax: true,
      );
  static final formatter = DartFormatter(
    fixes: StyleFix.all,
  );

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
    final messageImpls = generateMessages(element, messageTypeEl);

    final libraries = <Target, String>{};
    for (final messageImpl in messageImpls) {
      final target = messageImpl.target.name;
      final assetId = buildStep.inputId.changeExtension('.worker.$target.dart');
      libraries[messageImpl.target] = path.basename(assetId.path);
      await buildStep.writeAsString(assetId, messageImpl.impl);
    }

    return "export '${libraries[Target.vm]}' if (dart.library.html) '${libraries[Target.js]}';";
  }

  List<WorkerMessageImpl> generateMessages(
      ClassElement workerEl, ClassElement messageTypeEl) {
    final vmClass = VmGenerator(workerEl, messageTypeEl).generate();
    final jsClass = JsGenerator(workerEl, messageTypeEl).generate();

    return [
      WorkerMessageImpl(
          Target.vm, formatter.format('${vmClass.accept(emitter)}')),
      WorkerMessageImpl(
          Target.js, formatter.format('${jsClass.accept(emitter)}')),
    ];
  }
}
