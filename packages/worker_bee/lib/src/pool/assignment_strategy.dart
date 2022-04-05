import 'worker_pool.dart';

/// Identifies a [Request] type by selecting the property to hash.
typedef Identifier<Request extends Object> = Object Function(Request);

enum _AssignmentStrategyType {
  roundRobin,
  stickySession,
}

/// The technique used to assign a request to a worker bee in a [WorkerPool].
class AssignmentStrategy<Request extends Object> {
  AssignmentStrategy._(this._type, [this._getId]);

  /// Every request is assigned to the next worker in the rotation, evenly
  /// distributing requests across the pool.
  AssignmentStrategy.roundRobin() : this._(_AssignmentStrategyType.roundRobin);

  /// Every request has a marker which is used to maintain a one-to-one
  /// correspondence of requests to workers.
  AssignmentStrategy.stickySession({
    required Identifier getId,
  }) : this._(_AssignmentStrategyType.stickySession, getId);

  final _AssignmentStrategyType _type;
  final Identifier? _getId;
  final Map<Object, int> _assignmentMap = {};
  int _currentWorker = 0;

  /// Assigns [request] to a worker index based on the strategy.
  int assign(Request request) {
    switch (_type) {
      case _AssignmentStrategyType.roundRobin:
        return _currentWorker++;
      case _AssignmentStrategyType.stickySession:
        final id = _getId!(request);
        return _assignmentMap[id] ??= _currentWorker++;
    }
  }
}
