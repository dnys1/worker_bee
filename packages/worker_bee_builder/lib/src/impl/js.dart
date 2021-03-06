import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:worker_bee_builder/src/impl/common.dart';
import 'package:worker_bee_builder/src/types.dart';

class JsGenerator extends MessageGenerator {
  JsGenerator(
    ClassElement classEl,
    ClassElement requestTypeEl,
    ClassElement? responseTypeEl,
    ClassElement? poolWorkerTypeEl,
    this.entrypoint,
    this.fallbackUrls,
  ) : super(classEl, requestTypeEl, responseTypeEl, poolWorkerTypeEl);

  final String entrypoint;
  final List<String> fallbackUrls;

  @override
  Library generate() {
    return Library(
      (b) => b
        ..body.addAll([
          _workerClass,
        ]),
    );
  }

  Class get _workerClass => Class(
        (c) => c
          ..name = workerImplName
          ..docs.add('/// The JS implementation of [${workerType.symbol}].')
          ..extend = workerType
          ..methods.addAll([
            Method((m) => m
              ..annotations.add(DartTypes.core.override)
              ..returns = DartTypes.core.string
              ..type = MethodType.getter
              ..name = 'name'
              ..body = literalString(workerName).code),
            Method((m) => m
              ..annotations.add(DartTypes.core.override)
              ..returns = DartTypes.core.string
              ..type = MethodType.getter
              ..name = 'jsEntrypoint'
              ..body = literalString(entrypoint).code),
            Method((m) => m
              ..annotations.add(DartTypes.core.override)
              ..returns = DartTypes.core.list(DartTypes.core.string)
              ..type = MethodType.getter
              ..name = 'fallbackUrls'
              ..body = literalConstList(fallbackUrls).code),
            if (isWorkerPool) factoryGetter,
          ]),
      );
}
