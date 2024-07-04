// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

import '../main.dart';

enum ThemeStatus {
  light,
  dark,
}

class ThemeModel extends Equatable {
  final ThemeStatus themeStatus;
  final bool isChecked;
  ThemeModel({
    required this.themeStatus,
    required this.isChecked,
  });

  factory ThemeModel.initial() {
    var themePref = prefs?.getBool('isDarkTheme');
    return ThemeModel(
      themeStatus: themePref == true ? ThemeStatus.light : ThemeStatus.dark,
      isChecked: themePref == true ? true : false,
    );
  }

  ThemeModel copyWith({
    ThemeStatus? themeStatus,
    bool? isChecked,
  }) {
    return ThemeModel(
      themeStatus: themeStatus ?? this.themeStatus,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  @override
  bool get stringify => true;
  @override
  List<Object> get props => [themeStatus, isChecked];
}
