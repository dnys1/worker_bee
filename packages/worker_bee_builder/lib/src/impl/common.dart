import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:worker_bee_builder/src/type_visitor.dart';
import 'package:worker_bee_builder/src/types.dart';

enum Target { vm, js }

class WorkerMessageImpl {
  const WorkerMessageImpl(this.target, this.impl);

  final Target target;
  final String impl;
}

abstract class MessageGenerator {
  MessageGenerator(
    this.workerEl,
    this.requestEl,
    this.responseEl,
    this.poolWorkerTypeEl,
  ) {
    isWorkerPool = workerEl.supertype!.element.name == 'WorkerPoolBase';
    workerName = workerEl.name;
    workerImplName = '${workerName}Impl';
    workerType = Reference(
      workerName,
      workerEl.librarySource.uri.toString(),
    );
    _checkCtors(workerEl.constructors);

    final requestTypeName = requestEl.name;
    requestType = requestEl.thisType.accept(symbolVisitor);
    requestTypeImplName = '${requestTypeName}Impl';

    trueResponseType =
        responseEl?.thisType.accept(symbolVisitor) ?? DartTypes.core.void$;
    responseType = trueResponseType.isVoid
        ? DartTypes.core.object.nullable
        : trueResponseType;

    if (isWorkerPool) {
      poolWorkerType = poolWorkerTypeEl!.thisType.accept(symbolVisitor);
    }
  }

  void _checkCtors(List<ConstructorElement> ctors) {
    var hasUnnamed = false;
    var hasCreate = false;
    for (final ctor in ctors) {
      if (ctor.isDefaultConstructor) {
        hasUnnamed = true;
        continue;
      }
      if (ctor.name == 'create' && ctor.isFactory) {
        hasCreate = true;
        continue;
      }
    }

    if (!hasUnnamed || !hasCreate) {
      throw ArgumentError(
        'Constructors must follow the pattern:\n'
        '$workerName();\n'
        'factory $workerName.create() = $workerImplName;',
      );
    }
  }

  Method get factoryGetter => Method(
        (m) => m
          ..annotations.add(DartTypes.core.override)
          ..returns = FunctionType((b) => b..returnType = poolWorkerType)
          ..name = 'factory'
          ..type = MethodType.getter
          ..lambda = true
          ..body = poolWorkerType.property('create').code,
      );

  final symbolVisitor = const SymbolVisitor();
  final ClassElement workerEl;
  final ClassElement requestEl;
  final ClassElement? responseEl;
  final ClassElement? poolWorkerTypeEl;

  late final bool isWorkerPool;
  late final String workerName;
  late final String workerImplName;
  late final Reference workerType;
  late final Reference requestType;
  late final Reference poolWorkerType;
  late final String requestTypeImplName;
  late final Reference trueResponseType;
  late final Reference responseType;

  Library generate();
}
