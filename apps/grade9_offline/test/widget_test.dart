import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grade9_offline_learning/main.dart';

void main() {
  test('application root is a Material application widget', () {
    expect(const GradeNineApp(), isA<StatelessWidget>());
  });
}
