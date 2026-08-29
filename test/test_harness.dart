/// A deliberately tiny, dependency-free test harness. This lets the
/// domain/payroll test suite run with a bare `dart run test/all_tests.dart`
/// even before `package:test` (or any pub package) is available — useful
/// in network-restricted environments, and a fine bridge until the real
/// Flutter project is scaffolded with `package:test`/`flutter_test`.
///
/// To migrate later: replace `test(...)`/`expect(...)` calls with
/// `package:test`'s API of the same names — the call shapes are close
/// enough that most test bodies won't need to change.
typedef TestFn = Future<void> Function();

class _TestCase {
  final String name;
  final TestFn fn;
  _TestCase(this.name, this.fn);
}

final List<_TestCase> _tests = [];

void test(String name, TestFn fn) => _tests.add(_TestCase(name, fn));

class TestFailure implements Exception {
  final String message;
  TestFailure(this.message);
  @override
  String toString() => message;
}

void expect(Object? actual, Object? expected, [String? reason]) {
  if (actual != expected) {
    throw TestFailure(
        'Expected <$expected> but got <$actual>${reason != null ? ' — $reason' : ''}');
  }
}

void expectTrue(bool condition, [String reason = 'Expected condition to be true']) {
  if (!condition) throw TestFailure(reason);
}

Future<void> expectThrowsAsync(Future<void> Function() fn,
    [String reason = 'Expected an exception to be thrown']) async {
  try {
    await fn();
  } catch (_) {
    return;
  }
  throw TestFailure(reason);
}

Future<void> runTests() async {
  var passed = 0;
  var failed = 0;
  for (final t in _tests) {
    try {
      await t.fn();
      passed++;
      // ignore: avoid_print
      print('PASS  ${t.name}');
    } catch (e) {
      failed++;
      // ignore: avoid_print
      print('FAIL  ${t.name}\n      $e');
    }
  }
  // ignore: avoid_print
  print('\n$passed passed, $failed failed, ${_tests.length} total');
  if (failed > 0) {
    throw StateError('$failed test(s) failed');
  }
}
