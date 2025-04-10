import 'package:flutter/widgets.dart';
import 'package:tabs_test/models/dependencies.dart';

/// {@template dependencies_scope}
/// DependenciesScope widget.
/// {@endtemplate}
class DependenciesScope extends StatelessWidget {
  /// {@macro dependencies_scope}
  const DependenciesScope({
    required this.dependencies,
    required this.child,
    super.key, // ignore: unused_element
  });

  final Dependencies dependencies;

  final Widget child;

  static Dependencies of(BuildContext context) => context
      .getInheritedWidgetOfExactType<_InheritedDependencies>()!
      .dependencies;

  @override
  Widget build(BuildContext context) => _InheritedDependencies(
        dependencies: dependencies,
        child: child,
      );
}

/// {@template dependencies_scope}
/// _InheritedDependencies widget.
/// {@endtemplate}
class _InheritedDependencies extends InheritedWidget {
  /// {@macro dependencies_scope}
  const _InheritedDependencies({
    required super.child,
    required this.dependencies,
    super.key, // ignore: unused_element
  });

  final Dependencies dependencies;

  @override
  bool updateShouldNotify(covariant _InheritedDependencies oldWidget) => false;
}

extension BuildContextX on BuildContext {
  Dependencies get dependencies => DependenciesScope.of(this);
}
