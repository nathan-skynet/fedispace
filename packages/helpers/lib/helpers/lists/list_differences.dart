import 'package:flutter/foundation.dart';
import 'package:helpers/helpers.dart';

class ListDifference<T> {
  ListDifference({
    List<T> initialValues = const [],
    List<T> currentValues = const [],
    this.containsValidator,
  }) {
    final List<T> initial = initialValues.removeDuplicates();
    final List<T> current = currentValues.removeDuplicates();

    if (!listEquals(initial, current)) {
      if (initial.isEmpty) {
        added.addAll(current);
      } else {
        for (final item in initial) {
          if (!_validator(current, item)) removed.add(item);
        }
        for (final item in current) {
          if (!_validator(initial, item)) added.add(item);
        }
      }
      equals.addAll(currentValues.where((e) => _validator(initialValues, e)));
    } else {
      equals.addAll(current);
    }
  }

  bool _validator(List<T> elements, T item) {
    return containsValidator?.call(elements, item) ?? elements.contains(item);
  }

  final bool Function(List<T> elements, T e)? containsValidator;
  final List<T> added = [];
  final List<T> removed = [];
  final List<T> equals = [];

  @override
  String toString() =>
      "ListDifference(added: $added, removed: $removed, equals: $equals)";
}
