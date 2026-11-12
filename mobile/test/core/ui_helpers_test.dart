import 'package:cash_compass/core/ui/category_style.dart';
import 'package:cash_compass/core/ui/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatMoney adds spaces and the tenge sign', () {
    expect(formatMoney(0), '0 ₸');
    expect(formatMoney(1500), '1 500 ₸');
    expect(formatMoney(1234567.5), '1 234 567.5 ₸');
  });

  test('colorFromHex reads #RRGGBB', () {
    expect(colorFromHex('#1E88E5'), const Color(0xFF1E88E5));
  });

  test('iconFromName falls back to the default icon', () {
    expect(iconFromName('restaurant'), Icons.restaurant);
    expect(iconFromName('unknown'), Icons.category);
  });
}