import 'package:build/build.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;
import 'package:source_gen/source_gen.dart';
import 'package:worker_bee/worker_bee.dart';
import 'package:worker_bee_builder/src/impl/common.dart';
import 'package:worker_bee_builder/src/impl/js.dart';
import 'package:worker_bee_builder/src/impl/vm.dart';

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
    if (supertype == null ||
        (supertype.element.name != 'WorkerBeeBase' &&
            supertype.element.name != 'WorkerPoolBase')) {
      throw ArgumentError(
          '@WorkerBee classes must extends WorkerBeeBase<M, R>.');
    }
    final typeArgs = supertype.typeArguments;
    if (typeArgs.length < 2) {
      throw ArgumentError('@WorkerBee classes must declare their types.');
    }

    // Look up message type to generate JS/VM implementations.
    final requestType = typeArgs[0];
    final requestTypeEl = requestType.element;
    if (requestTypeEl == null || requestTypeEl is! ClassElement) {
      final requestTypeName =
          requestType.getDisplayString(withNullability: true);
      throw ArgumentError('Could not find element for $requestTypeName.');
    }

    final responseType = typeArgs[1];
    final responseTypeEl = responseType.element;

    final poolWorkerType = typeArgs.length == 3 ? typeArgs[2] : null;
    final poolWorkerTypeEl = poolWorkerType?.element;

    final jsEntrypoint = annotation.read('jsEntrypoint').stringValue;
    final fallbackUrls = annotation
        .read('fallbackUrls')
        .listValue
        .map((obj) => obj.toStringValue())
        .toList()
        .cast<String>();
    final workerImpls = generateWorkerImpls(
      element,
      requestTypeEl,
      responseTypeEl as ClassElement?,
      poolWorkerTypeEl as ClassElement?,
      jsEntrypoint,
      fallbackUrls,
    );

    final libraries = <Target, String>{};
    for (final workerImpl in workerImpls) {
      final target = workerImpl.target.name;
      final assetId = buildStep.inputId.changeExtension('.worker.$target.dart');
      libraries[workerImpl.target] = path.basename(assetId.path);
      await buildStep.writeAsString(assetId, workerImpl.impl);
    }

    return "export '${libraries[Target.vm]}' if (dart.library.html) '${libraries[Target.js]}';";
  }

  List<WorkerMessageImpl> generateWorkerImpls(
    ClassElement workerEl,
    ClassElement messageTypeEl,
    ClassElement? resultTypeEl,
    ClassElement? poolWorkerTypeEl,
    String jsEntrypoint,
    List<String> fallbackUrls,
  ) {
    final vmClass = VmGenerator(
      workerEl,
      messageTypeEl,
      resultTypeEl,
      poolWorkerTypeEl,
    ).generate();
    final jsClass = JsGenerator(
      workerEl,
      messageTypeEl,
      resultTypeEl,
      poolWorkerTypeEl,
      jsEntrypoint,
      fallbackUrls,
    ).generate();

    return [
      WorkerMessageImpl(
          Target.vm, formatter.format('${vmClass.accept(emitter)}')),
      WorkerMessageImpl(
          Target.js, formatter.format('${jsClass.accept(emitter)}')),
    ];
  }
}
