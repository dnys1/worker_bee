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
  MessageGenerator(this.workerEl, this.messageEl, this.resultEl) {
    workerName = workerEl.name;
    workerImplName = '${workerName}Impl';
    workerType = Reference(
      workerName,
      workerEl.librarySource.uri.toString(),
    );
    _checkCtors(workerEl.constructors);

    if (!messageEl.isAbstract) {
      throw ArgumentError('Message classes must be abstract');
    }
    final messageTypeName = messageEl.name;
    messageType = messageEl.thisType.accept(symbolVisitor);
    messageTypeImplName = '${messageTypeName}Impl';

    messageFields = messageEl.fields;
    for (final field in messageFields) {
      // Check that it is an abstract getter.
      if (!field.isSynthetic) {
        throw ArgumentError('Message fields must be getters');
      }
    }

    trueResultType =
        resultEl?.thisType.accept(symbolVisitor) ?? DartTypes.core.void$;
    resultType =
        trueResultType.isVoid ? DartTypes.core.object.nullable : trueResultType;
    if (trueResultType.symbol == messageType.symbol) {
      throw StateError('Message and result types should not be the same');
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

  final symbolVisitor = const SymbolVisitor();
  final ClassElement workerEl;
  final ClassElement messageEl;
  final ClassElement? resultEl;

  late final String workerName;
  late final String workerImplName;
  late final Reference workerType;
  late final Reference messageType;
  late final String messageTypeImplName;
  late final List<FieldElement> messageFields;
  late final Reference trueResultType;
  late final Reference resultType;

  Library generate();
}
