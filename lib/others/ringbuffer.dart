import 'dart:collection';
import 'dart:math';

class RingBuffer<T> with ListMixin<T> {
  late int _capacity;
  late List<T?> _buffer;

  late int _length;
  int _index = -1;

  RingBuffer(int capacity) {
    if (capacity <= 0) {
      throw ArgumentError("Capacity must be a positive number.");
    }

    _capacity = capacity;
    _buffer = List<T?>.filled(_capacity, null);
    _length = 0;
  }

  @override
  int get length => _length;

  @override
  set length(int newLength) {
    throw UnsupportedError('Setting new length is not supported.');
  }

  @override
  void add(T element) {
    _index = (_index + 1) % _capacity;
    _buffer[_index] = element;
    _length = min(_length + 1, _capacity);
  }

  @override
  T operator [](int index) {
    if (index < 0 || index >= length) {
      throw RangeError.index(index, this);
    }

    final oldestIndex = (_index - _length + 1 + _capacity) % _capacity;
    final bufferIndex = (oldestIndex + index) % _capacity;
    return _buffer[bufferIndex] as T;
  }

  @override
  void clear() {
    _index = -1;
    _length = 0;
    // don't keep refernces to elements when buffer is cleared
    for (int i = 0; i < _buffer.length; i++) {
      _buffer[i] = null;
    }
  }

  @override
  void operator []=(int index, T? value) {
    throw UnsupportedError(
        'Direct write access with index is not permitted, use add(T element)');
  }

  @override
  void insert(int index, T element) {
    throw UnsupportedError('Inserting element not supported.');
  }

  @override
  void insertAll(int index, Iterable<T> iterable) {
    throw UnsupportedError('Inserting elements not supported.');
  }

  @override
  Iterator<T> get iterator {
    List<T> out = [];
    for (int i = 0; i < _length; i++) {
      out.add(this[i]);
    }
    return out.iterator;
  }
}
