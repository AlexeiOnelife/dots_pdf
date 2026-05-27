// RED test scaffolding for boda-halo render pipeline (R2, R7, R8).
// All tests in this file use fail('PR 2: ...') placeholders — they will be
// wired in slice 7 PR 2 when _buildRotatedPhotoElement and the full
// DotsAlbumSpreadPage.bodaHalo factory body are implemented.
//
// Scenarios: S28 (main-isolate render), S29 (worker-isolate parity),
//            S21 (ArgumentError via render path), S22 (RangeError length!=10),
//            S9  (decode failure skips + fires onPhotoFailure),
//            S32 (spread-width warning when pageSize.width < 406 mm).
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('boda halo render — main-isolate (S28) [PR 2]', () {
    test('renders non-empty PDF byte buffer via useIsolate: false', () {
      fail('PR 2: implement when _buildRotatedPhotoElement is ready');
    });
  });

  group('boda halo render — worker-isolate parity (S29) [PR 2]', () {
    test('worker-isolate render matches main-isolate non-empty result', () {
      fail('PR 2: implement when isolate render path handles DotsRotatedPhotoElement');
    });
  });

  group('boda halo render — ArgumentError on non-boda type (S21) [PR 2]', () {
    test('throws ArgumentError when type is not DotsAlbumType.boda', () {
      fail('PR 2: implement when DotsAlbumSpreadPage.bodaHalo body is complete');
    });
  });

  group('boda halo render — RangeError on photoPaths.length != 10 (S22) [PR 2]', () {
    test('throws RangeError when photoPaths has 9 entries', () {
      fail('PR 2: implement when DotsAlbumSpreadPage.bodaHalo body is complete');
    });
  });

  group('boda halo render — decode failure (S9) [PR 2]', () {
    test('skips element and fires onPhotoFailure on decode error', () {
      fail('PR 2: implement when _buildRotatedPhotoElement handles decode failure');
    });
  });

  group('boda halo render — spread-width warning (S32) [PR 2]', () {
    test('emits logger warning when pageSize.width < 406 mm', () {
      fail('PR 2: implement when spread-width guard extended to DotsRotatedPhotoElement');
    });
  });
}
