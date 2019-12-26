import 'package:restio/restio.dart';
import 'package:test/test.dart';

void main() {
  test('NameAt & ValueAt', () {
    final builder = HeadersBuilder();
    builder.add('string', 'foo');
    builder.add('string', 'bar');
    builder.add('int', 5);
    builder.add('float', 1.5);
    builder.add('bool', true);

    final headers = builder.build();

    expect(headers.nameAt(0), 'string');
    expect(headers.nameAt(1), 'string');
    expect(headers.nameAt(2), 'int');
    expect(headers.nameAt(3), 'float');
    expect(headers.nameAt(4), 'bool');
    expect(headers.valueAt(0), 'foo');
    expect(headers.valueAt(1), 'bar');
    expect(headers.valueAt(2), '5');
    expect(headers.valueAt(3), '1.5');
    expect(headers.valueAt(4), 'true');
  });

  test('Remove', () {
    final builder = HeadersBuilder();
    builder.add('foo', 'bar');
    builder.add('foo', 'baz');
    builder.add('bar', 'foo');

    var headers = builder.build();

    expect(headers.length, 3);

    builder.remove('foo');

    headers = builder.build();

    expect(headers.length, 1);
  });

  test('RemoveAt', () {
    final builder = HeadersBuilder()
      ..add('foo', 'bar')
      ..add('foo', 'baz')
      ..add('bar', 'foo')
      ..removeAt(2);

    final headers = builder.build();

    expect(headers.length, 2);
    expect(headers.has('bar'), false);
  });

  test('RemoveFirst', () {
    final builder = HeadersBuilder()
      ..add('foo', 'bar')
      ..add('foo', 'baz')
      ..add('bar', 'foo')
      ..removeFirst('foo');

    final headers = builder.build();

    expect(headers.length, 2);
    expect(headers.value('foo'), 'baz');
  });

  test('RemoveLast', () {
    final builder = HeadersBuilder()
      ..add('foo', 'bar')
      ..add('foo', 'baz')
      ..add('bar', 'foo')
      ..removeLast('foo');

    final headers = builder.build();

    expect(headers.length, 2);
    expect(headers.value('foo'), 'bar');
  });
}