import 'package:flutter_test/flutter_test.dart';
import 'package:pslab/others/ringbuffer.dart';

void main() {
  group('create ringbuffer and fill it', () {
    test('create ringbuffer', () {
      RingBuffer<String> ringbuffer = RingBuffer(3);
      expect(ringbuffer.length, 0);
    });

    test('add one element', () {
      RingBuffer<String> ringbuffer = RingBuffer(3);
      ringbuffer.add('first');
      expect(ringbuffer.length, 1);
      expect(ringbuffer[0], 'first');
    });

    test('add two elements', () {
      RingBuffer<String> ringbuffer = RingBuffer(3);
      ringbuffer.add('first');
      ringbuffer.add('second');
      expect(ringbuffer.length, 2);
      expect(ringbuffer[0], 'first');
      expect(ringbuffer[1], 'second');
    });

    test('add three elements', () {
      RingBuffer<String> ringbuffer = RingBuffer(3);
      ringbuffer.add('first');
      ringbuffer.add('second');
      ringbuffer.add('third');
      expect(ringbuffer.length, 3);
      expect(ringbuffer[0], 'first');
      expect(ringbuffer[1], 'second');
      expect(ringbuffer[2], 'third');
    });

    test('add four elements', () {
      RingBuffer<String> ringbuffer = RingBuffer(3);
      ringbuffer.add('first');
      ringbuffer.add('second');
      ringbuffer.add('third');
      ringbuffer.add('fourth');
      expect(ringbuffer.length, 3);
      expect(ringbuffer[0], 'second');
      expect(ringbuffer[1], 'third');
      expect(ringbuffer[2], 'fourth');
    });
  });

  test('create ringbuffer with illegal index', () {
    expect(() => RingBuffer<String>(0), throwsArgumentError);
  });

  test('access nonexistant field', () {
    RingBuffer<String> ringbuffer = RingBuffer(2);
    expect(ringbuffer.length, 0);
    expect(() => ringbuffer[-1], throwsRangeError);
    expect(() => ringbuffer[0], throwsRangeError);
    ringbuffer.add('first');
    expect(ringbuffer.length, 1);
    expect(() => ringbuffer[1], throwsRangeError);
  });

  test('fill and clear', () {
    RingBuffer<String> ringbuffer = RingBuffer(2);
    expect(ringbuffer.length, 0);
    ringbuffer.add('first');
    expect(ringbuffer.length, 1);
    ringbuffer.add('second');
    expect(ringbuffer.length, 2);
    ringbuffer.clear();
    expect(ringbuffer.length, 0);
  });

  test('write with index', () {
    RingBuffer<String> ringbuffer = RingBuffer(2);
    expect(() => ringbuffer[0] = 'first', throwsUnsupportedError);
    expect(ringbuffer.length, 0);
    expect(() => ringbuffer[0], throwsRangeError);
  });

  test('test insert', () {
    RingBuffer<String> ringbuffer = RingBuffer(2);
    expect(() => ringbuffer.insert(0, 'first'), throwsUnsupportedError);
    expect(ringbuffer.length, 0);
    expect(() => ringbuffer[0], throwsRangeError);
  });

  test('test insertAll', () {
    RingBuffer<String> ringbuffer = RingBuffer(2);
    expect(() => ringbuffer.insertAll(0, ['first', 'second']),
        throwsUnsupportedError);
    expect(ringbuffer.length, 0);
    expect(() => ringbuffer[0], throwsRangeError);
  });

  test('test iterator', () {
    RingBuffer<String> ringbuffer = RingBuffer(4);
    var elements = ['first', 'second', 'third'];
    var i = 0;
    expect(ringbuffer.length, 0);
    ringbuffer.add(elements[i++]);
    expect(ringbuffer.length, 1);
    ringbuffer.add(elements[i++]);
    expect(ringbuffer.length, 2);
    ringbuffer.add(elements[i++]);
    expect(ringbuffer.length, 3);

    var iter = ringbuffer.iterator;
    i = 0;
    while (iter.moveNext()) {
      expect(iter.current, elements[i++]);
    }
    expect(i, elements.length);
  });

  test('test reversed', () {
    RingBuffer<String> ringbuffer = RingBuffer(4);
    var elements = ['first', 'second', 'third'];
    var i = 0;
    expect(ringbuffer.length, 0);
    ringbuffer.add(elements[i++]);
    expect(ringbuffer.length, 1);
    ringbuffer.add(elements[i++]);
    expect(ringbuffer.length, 2);
    ringbuffer.add(elements[i++]);
    expect(ringbuffer.length, 3);

    for (var element in ringbuffer.reversed) {
      expect(element, elements[--i]);
    }

    expect(ringbuffer.reversed.length, 3);
  });

  test('test iterable', () {
    RingBuffer<String> ringbuffer = RingBuffer(4);
    var elements = ['first', 'second', 'third'];
    var i = 0;
    expect(ringbuffer.length, 0);
    ringbuffer.add(elements[i++]);
    expect(ringbuffer.length, 1);
    ringbuffer.add(elements[i++]);
    expect(ringbuffer.length, 2);
    ringbuffer.add(elements[i++]);
    expect(ringbuffer.length, 3);

    i = 0;
    for (var element in ringbuffer) {
      expect(element, elements[i++]);
    }
    expect(i, elements.length);
  });
}
