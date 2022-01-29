import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:worker_bee_builder/src/type_visitor.dart';

enum Target { vm, js }

class WorkerMessageImpl {
  const WorkerMessageImpl(this.target, this.impl);

  final Target target;
  final String impl;
}

abstract class MessageGenerator {
  MessageGenerator(this.workerEl, this.messageEl) {
    _checkCtors(workerEl.constructors);
    workerName = workerEl.name;
    workerImplName = '${workerName}Impl';
    workerType = Reference(
      workerName,
      workerEl.librarySource.uri.toString(),
    );

    if (!messageEl.isAbstract) {
      throw ArgumentError('Message classes must be abstract');
    }
    final messageTypeName = messageEl.name;
    final messageTypeSourceUri = messageEl.librarySource.uri;
    messageType = Reference(messageTypeName, messageTypeSourceUri.toString());
    messageTypeImplName = '${messageTypeName}Impl';

    messageFields = messageEl.fields;
    for (final field in messageFields) {
      // Check that it is an abstract getter.
      if (!field.isSynthetic) {
        throw ArgumentError('Message fields must be getters');
      }
    }

    final resultTypeEl = messageEl.interfaces.single.typeArguments.singleOrNull;
    if (resultTypeEl == null) {
      throw ArgumentError(
        'Result type must be specified, e.g. '
        'MyMessage implements WorkerMessage<String>',
      );
    }
    resultType = resultTypeEl.accept(const SymbolVisitor());
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
        'MyWorker();\n'
        'factory MyWorker.create() = MyWorkerImpl;',
      );
    }
  }

  final symbolVisitor = const SymbolVisitor();
  final ClassElement workerEl;
  final ClassElement messageEl;

  late final String workerName;
  late final String workerImplName;
  late final Reference workerType;
  late final Reference messageType;
  late final String messageTypeImplName;
  late final List<FieldElement> messageFields;
  late final Reference resultType;

  Library generate();
}
