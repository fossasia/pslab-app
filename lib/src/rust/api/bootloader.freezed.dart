// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bootloader.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FlashState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FlashState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FlashState()';
  }
}

/// @nodoc
class $FlashStateCopyWith<$Res> {
  $FlashStateCopyWith(FlashState _, $Res Function(FlashState) __);
}

/// Adds pattern-matching-related methods to [FlashState].
extension FlashStatePatterns on FlashState {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FlashState_Connecting value)? connecting,
    TResult Function(FlashState_Erasing value)? erasing,
    TResult Function(FlashState_Writing value)? writing,
    TResult Function(FlashState_Verifying value)? verifying,
    TResult Function(FlashState_Finished value)? finished,
    TResult Function(FlashState_Error value)? error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case FlashState_Connecting() when connecting != null:
        return connecting(_that);
      case FlashState_Erasing() when erasing != null:
        return erasing(_that);
      case FlashState_Writing() when writing != null:
        return writing(_that);
      case FlashState_Verifying() when verifying != null:
        return verifying(_that);
      case FlashState_Finished() when finished != null:
        return finished(_that);
      case FlashState_Error() when error != null:
        return error(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FlashState_Connecting value) connecting,
    required TResult Function(FlashState_Erasing value) erasing,
    required TResult Function(FlashState_Writing value) writing,
    required TResult Function(FlashState_Verifying value) verifying,
    required TResult Function(FlashState_Finished value) finished,
    required TResult Function(FlashState_Error value) error,
  }) {
    final _that = this;
    switch (_that) {
      case FlashState_Connecting():
        return connecting(_that);
      case FlashState_Erasing():
        return erasing(_that);
      case FlashState_Writing():
        return writing(_that);
      case FlashState_Verifying():
        return verifying(_that);
      case FlashState_Finished():
        return finished(_that);
      case FlashState_Error():
        return error(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FlashState_Connecting value)? connecting,
    TResult? Function(FlashState_Erasing value)? erasing,
    TResult? Function(FlashState_Writing value)? writing,
    TResult? Function(FlashState_Verifying value)? verifying,
    TResult? Function(FlashState_Finished value)? finished,
    TResult? Function(FlashState_Error value)? error,
  }) {
    final _that = this;
    switch (_that) {
      case FlashState_Connecting() when connecting != null:
        return connecting(_that);
      case FlashState_Erasing() when erasing != null:
        return erasing(_that);
      case FlashState_Writing() when writing != null:
        return writing(_that);
      case FlashState_Verifying() when verifying != null:
        return verifying(_that);
      case FlashState_Finished() when finished != null:
        return finished(_that);
      case FlashState_Error() when error != null:
        return error(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? connecting,
    TResult Function()? erasing,
    TResult Function(int progressPercent)? writing,
    TResult Function()? verifying,
    TResult Function()? finished,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case FlashState_Connecting() when connecting != null:
        return connecting();
      case FlashState_Erasing() when erasing != null:
        return erasing();
      case FlashState_Writing() when writing != null:
        return writing(_that.progressPercent);
      case FlashState_Verifying() when verifying != null:
        return verifying();
      case FlashState_Finished() when finished != null:
        return finished();
      case FlashState_Error() when error != null:
        return error(_that.message);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() connecting,
    required TResult Function() erasing,
    required TResult Function(int progressPercent) writing,
    required TResult Function() verifying,
    required TResult Function() finished,
    required TResult Function(String message) error,
  }) {
    final _that = this;
    switch (_that) {
      case FlashState_Connecting():
        return connecting();
      case FlashState_Erasing():
        return erasing();
      case FlashState_Writing():
        return writing(_that.progressPercent);
      case FlashState_Verifying():
        return verifying();
      case FlashState_Finished():
        return finished();
      case FlashState_Error():
        return error(_that.message);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? connecting,
    TResult? Function()? erasing,
    TResult? Function(int progressPercent)? writing,
    TResult? Function()? verifying,
    TResult? Function()? finished,
    TResult? Function(String message)? error,
  }) {
    final _that = this;
    switch (_that) {
      case FlashState_Connecting() when connecting != null:
        return connecting();
      case FlashState_Erasing() when erasing != null:
        return erasing();
      case FlashState_Writing() when writing != null:
        return writing(_that.progressPercent);
      case FlashState_Verifying() when verifying != null:
        return verifying();
      case FlashState_Finished() when finished != null:
        return finished();
      case FlashState_Error() when error != null:
        return error(_that.message);
      case _:
        return null;
    }
  }
}

/// @nodoc

class FlashState_Connecting extends FlashState {
  const FlashState_Connecting() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FlashState_Connecting);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FlashState.connecting()';
  }
}

/// @nodoc

class FlashState_Erasing extends FlashState {
  const FlashState_Erasing() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FlashState_Erasing);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FlashState.erasing()';
  }
}

/// @nodoc

class FlashState_Writing extends FlashState {
  const FlashState_Writing({required this.progressPercent}) : super._();

  final int progressPercent;

  /// Create a copy of FlashState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FlashState_WritingCopyWith<FlashState_Writing> get copyWith =>
      _$FlashState_WritingCopyWithImpl<FlashState_Writing>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FlashState_Writing &&
            (identical(other.progressPercent, progressPercent) ||
                other.progressPercent == progressPercent));
  }

  @override
  int get hashCode => Object.hash(runtimeType, progressPercent);

  @override
  String toString() {
    return 'FlashState.writing(progressPercent: $progressPercent)';
  }
}

/// @nodoc
abstract mixin class $FlashState_WritingCopyWith<$Res>
    implements $FlashStateCopyWith<$Res> {
  factory $FlashState_WritingCopyWith(
          FlashState_Writing value, $Res Function(FlashState_Writing) _then) =
      _$FlashState_WritingCopyWithImpl;
  @useResult
  $Res call({int progressPercent});
}

/// @nodoc
class _$FlashState_WritingCopyWithImpl<$Res>
    implements $FlashState_WritingCopyWith<$Res> {
  _$FlashState_WritingCopyWithImpl(this._self, this._then);

  final FlashState_Writing _self;
  final $Res Function(FlashState_Writing) _then;

  /// Create a copy of FlashState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? progressPercent = null,
  }) {
    return _then(FlashState_Writing(
      progressPercent: null == progressPercent
          ? _self.progressPercent
          : progressPercent // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class FlashState_Verifying extends FlashState {
  const FlashState_Verifying() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FlashState_Verifying);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FlashState.verifying()';
  }
}

/// @nodoc

class FlashState_Finished extends FlashState {
  const FlashState_Finished() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FlashState_Finished);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FlashState.finished()';
  }
}

/// @nodoc

class FlashState_Error extends FlashState {
  const FlashState_Error({required this.message}) : super._();

  final String message;

  /// Create a copy of FlashState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FlashState_ErrorCopyWith<FlashState_Error> get copyWith =>
      _$FlashState_ErrorCopyWithImpl<FlashState_Error>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FlashState_Error &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'FlashState.error(message: $message)';
  }
}

/// @nodoc
abstract mixin class $FlashState_ErrorCopyWith<$Res>
    implements $FlashStateCopyWith<$Res> {
  factory $FlashState_ErrorCopyWith(
          FlashState_Error value, $Res Function(FlashState_Error) _then) =
      _$FlashState_ErrorCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$FlashState_ErrorCopyWithImpl<$Res>
    implements $FlashState_ErrorCopyWith<$Res> {
  _$FlashState_ErrorCopyWithImpl(this._self, this._then);

  final FlashState_Error _self;
  final $Res Function(FlashState_Error) _then;

  /// Create a copy of FlashState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(FlashState_Error(
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
