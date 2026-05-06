/// A type that represents either a Left value (usually an error/failure) or a Right value (usually success)
/// This is a simplified version of the Either type for error handling
abstract class Either<L, R> {
  const Either();
  
  /// Returns true if this is a Right value
  bool get isRight;
  
  /// Returns true if this is a Left value
  bool get isLeft;
  
  /// Fold over the two possible values
  T fold<T>(T Function(L) onLeft, T Function(R) onRight);
  
  /// Map over the right value
  Either<L, T> map<T>(T Function(R) f);
  
  /// FlatMap over the right value
  Either<L, T> flatMap<T>(Either<L, T> Function(R) f);
  
  /// Get the right value or throw an exception
  R get value;
  
  /// Get the left value or throw an exception
  L get leftValue;
  
  /// Get the right value or return a default
  R getOrElse(R Function() defaultValue);
}

class Left<L, R> extends Either<L, R> {
  final L _value;
  
  const Left(this._value);
  
  @override
  bool get isRight => false;
  
  @override
  bool get isLeft => true;
  
  @override
  T fold<T>(T Function(L) onLeft, T Function(R) onRight) => onLeft(_value);
  
  @override
  Either<L, T> map<T>(T Function(R) f) => Left<L, T>(_value);
  
  @override
  Either<L, T> flatMap<T>(Either<L, T> Function(R) f) => Left<L, T>(_value);
  
  @override
  R get value => throw Exception('Called value on Left');
  
  @override
  L get leftValue => _value;
  
  @override
  R getOrElse(R Function() defaultValue) => defaultValue();
  
  @override
  bool operator ==(Object other) {
    return other is Left && other._value == _value;
  }
  
  @override
  int get hashCode => _value.hashCode;
  
  @override
  String toString() => 'Left($_value)';
}

class Right<L, R> extends Either<L, R> {
  final R _value;
  
  const Right(this._value);
  
  @override
  bool get isRight => true;
  
  @override
  bool get isLeft => false;
  
  @override
  T fold<T>(T Function(L) onLeft, T Function(R) onRight) => onRight(_value);
  
  @override
  Either<L, T> map<T>(T Function(R) f) => Right<L, T>(f(_value));
  
  @override
  Either<L, T> flatMap<T>(Either<L, T> Function(R) f) => f(_value);
  
  @override
  R get value => _value;
  
  @override
  L get leftValue => throw Exception('Called leftValue on Right');
  
  @override
  R getOrElse(R Function() defaultValue) => _value;
  
  @override
  bool operator ==(Object other) {
    return other is Right && other._value == _value;
  }
  
  @override
  int get hashCode => _value.hashCode;
  
  @override
  String toString() => 'Right($_value)';
}

// Convenience functions
Either<L, R> left<L, R>(L value) => Left<L, R>(value);
Either<L, R> right<L, R>(R value) => Right<L, R>(value);