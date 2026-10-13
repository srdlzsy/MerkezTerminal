import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/shared/offline/offline_sync_status.dart';

void main() {
  test('parses retry metadata and typed completed result', () {
    final status = OfflineSyncStatus<_TestResult>.fromJson(<String, dynamic>{
      'clientRequestId': 'request-1',
      'operationCode': 'test.create',
      'status': 'Completed',
      'createdAtUtc': '2026-10-13T08:10:00Z',
      'completedAtUtc': '2026-10-13T08:10:03Z',
      'errorMessage': null,
      'errorCode': null,
      'retryable': null,
      'retryAfterSeconds': null,
      'result': <String, dynamic>{'documentNo': 42},
    }, resultParser: _TestResult.fromJson);

    expect(status.isCompleted, isTrue);
    expect(status.result?.documentNo, 42);
    expect(status.retryNotBefore(), isNull);
  });

  test('calculates retry gate for an unconfirmed write', () {
    final status = OfflineSyncStatus<_TestResult>.fromJson(<String, dynamic>{
      'clientRequestId': 'request-2',
      'operationCode': 'test.create',
      'status': 'Failed',
      'errorMessage': 'Mikro write outcome could not be confirmed.',
      'errorCode': 'MIKRO_WRITE_OUTCOME_UNCONFIRMED',
      'retryable': true,
      'retryAfterSeconds': 5,
      'result': null,
    }, resultParser: _TestResult.fromJson);
    final now = DateTime(2026, 10, 13, 12);

    expect(status.isFailed, isTrue);
    expect(status.retryable, isTrue);
    expect(status.retryNotBefore(now), now.add(const Duration(seconds: 5)));
  });
}

class _TestResult {
  const _TestResult(this.documentNo);

  final int documentNo;

  factory _TestResult.fromJson(Map<String, dynamic> json) {
    return _TestResult((json['documentNo'] as num).toInt());
  }
}
