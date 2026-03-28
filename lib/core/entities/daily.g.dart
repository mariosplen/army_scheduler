// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DailyCWProxy {
  Daily program(Program program);

  Daily otherTasks(OtherTasks otherTasks);

  Daily date(Date date);

  Daily isHoliday(bool isHoliday);

  Daily isMilitaryMarketClosed(bool isMilitaryMarketClosed);

  Daily isSigned(bool isSigned);

  Daily manpower(List<Soldier> manpower);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Daily(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Daily(...).copyWith(id: 12, name: "My name")
  /// ````
  Daily call({
    Program? program,
    OtherTasks? otherTasks,
    Date? date,
    bool? isHoliday,
    bool? isMilitaryMarketClosed,
    bool? isSigned,
    List<Soldier>? manpower,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDaily.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDaily.copyWith.fieldName(...)`
class _$DailyCWProxyImpl implements _$DailyCWProxy {
  const _$DailyCWProxyImpl(this._value);

  final Daily _value;

  @override
  Daily program(Program program) => this(program: program);

  @override
  Daily otherTasks(OtherTasks otherTasks) => this(otherTasks: otherTasks);

  @override
  Daily date(Date date) => this(date: date);

  @override
  Daily isHoliday(bool isHoliday) => this(isHoliday: isHoliday);

  @override
  Daily isMilitaryMarketClosed(bool isMilitaryMarketClosed) =>
      this(isMilitaryMarketClosed: isMilitaryMarketClosed);

  @override
  Daily isSigned(bool isSigned) => this(isSigned: isSigned);

  @override
  Daily manpower(List<Soldier> manpower) => this(manpower: manpower);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Daily(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Daily(...).copyWith(id: 12, name: "My name")
  /// ````
  Daily call({
    Object? program = const $CopyWithPlaceholder(),
    Object? otherTasks = const $CopyWithPlaceholder(),
    Object? date = const $CopyWithPlaceholder(),
    Object? isHoliday = const $CopyWithPlaceholder(),
    Object? isMilitaryMarketClosed = const $CopyWithPlaceholder(),
    Object? isSigned = const $CopyWithPlaceholder(),
    Object? manpower = const $CopyWithPlaceholder(),
  }) {
    return Daily(
      program: program == const $CopyWithPlaceholder() || program == null
          ? _value.program
          // ignore: cast_nullable_to_non_nullable
          : program as Program,
      otherTasks:
          otherTasks == const $CopyWithPlaceholder() || otherTasks == null
              ? _value.otherTasks
              // ignore: cast_nullable_to_non_nullable
              : otherTasks as OtherTasks,
      date: date == const $CopyWithPlaceholder() || date == null
          ? _value.date
          // ignore: cast_nullable_to_non_nullable
          : date as Date,
      isHoliday: isHoliday == const $CopyWithPlaceholder() || isHoliday == null
          ? _value.isHoliday
          // ignore: cast_nullable_to_non_nullable
          : isHoliday as bool,
      isMilitaryMarketClosed:
          isMilitaryMarketClosed == const $CopyWithPlaceholder() ||
                  isMilitaryMarketClosed == null
              ? _value.isMilitaryMarketClosed
              // ignore: cast_nullable_to_non_nullable
              : isMilitaryMarketClosed as bool,
      isSigned: isSigned == const $CopyWithPlaceholder() || isSigned == null
          ? _value.isSigned
          // ignore: cast_nullable_to_non_nullable
          : isSigned as bool,
      manpower: manpower == const $CopyWithPlaceholder() || manpower == null
          ? _value.manpower
          // ignore: cast_nullable_to_non_nullable
          : manpower as List<Soldier>,
    );
  }
}

extension $DailyCopyWith on Daily {
  /// Returns a callable class that can be used as follows: `instanceOfDaily.copyWith(...)` or like so:`instanceOfDaily.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DailyCWProxy get copyWith => _$DailyCWProxyImpl(this);
}
