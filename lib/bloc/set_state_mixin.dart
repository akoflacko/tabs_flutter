import 'package:bloc/bloc.dart' show Emittable;

/// {@template set_state_mixin}
/// A mixin that provides a [setState] method to simplify the process of
/// updating the state of a [State] object.
/// {@endtemplate}
mixin SetStateMixin<State extends Object?> implements Emittable<State> {
  /// Calls the [emit] method to update the state of the [State] object.
  void setState(State state) => emit(state);
}
