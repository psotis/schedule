// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:scheldule/styling/themes/dark_theme.dart';
import 'package:scheldule/styling/themes/light_theme.dart';

import '../../main.dart';

enum ThemeStatus { dark, light }

class ThemeState extends Equatable {
  final ThemeStatus themeStatus;
  final ThemeData themeData;
  ThemeState({
    required this.themeStatus,
    required this.themeData,
  });

  factory ThemeState.initial() {
    var theme = prefs!.getString('theme');
    return ThemeState(
      themeStatus: theme == 'light' ? ThemeStatus.light : ThemeStatus.dark,
      themeData: theme == 'light' ? lightTheme : darkTheme,
    );
  }

  ThemeState copyWith({
    ThemeStatus? themeStatus,
    ThemeData? themeData,
  }) {
    return ThemeState(
        themeStatus: themeStatus ?? this.themeStatus,
        themeData: themeData ?? this.themeData);
  }

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [themeStatus];
}
