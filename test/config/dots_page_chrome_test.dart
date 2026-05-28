// Tests for DotsPageChrome value-object equality/hashCode (T1.3) and
// DotsTemplate.defaultChrome contentHash participation (T1.4).
//
// T1.3 tests are GREEN immediately once T2.1 ships the type.
// T1.4 tests are GREEN immediately once T2.2 adds the field to contentHash.
import 'package:dots_pdf/dots_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // T1.3 — DotsPageChrome equality and hashCode (R6)
  // ──────────────────────────────────────────────────────────────────────────

  group('DotsPageChrome — equality and hashCode', () {
    const a = DotsPageChrome(
      pageNumber: '3',
      centerLabel: 'Mi álbum',
      wordmark: 'Dots. Memories',
      isLeftPage: true,
      suppressHeader: false,
      suppressFooter: false,
    );
    const b = DotsPageChrome(
      pageNumber: '3',
      centerLabel: 'Mi álbum',
      wordmark: 'Dots. Memories',
      isLeftPage: true,
      suppressHeader: false,
      suppressFooter: false,
    );
    const c = DotsPageChrome(
      pageNumber: '4',
      centerLabel: 'Mi álbum',
      wordmark: 'Dots. Memories',
      isLeftPage: false,
      suppressHeader: false,
      suppressFooter: false,
    );

    test('DotsPageChrome — equal instances satisfy == and share hashCode', () {
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('DotsPageChrome — differing instances do not satisfy ==', () {
      expect(a, isNot(equals(c)));
    });

    test('default booleans are false/true as documented', () {
      const d = DotsPageChrome();
      expect(d.isLeftPage, isTrue);
      expect(d.suppressHeader, isFalse);
      expect(d.suppressFooter, isFalse);
    });

    test('suppressHeader participates in equality', () {
      const suppressed = DotsPageChrome(suppressHeader: true);
      const notSuppressed = DotsPageChrome(suppressHeader: false);
      expect(suppressed, isNot(equals(notSuppressed)));
    });

    test('suppressFooter participates in equality', () {
      const suppressed = DotsPageChrome(suppressFooter: true);
      const notSuppressed = DotsPageChrome(suppressFooter: false);
      expect(suppressed, isNot(equals(notSuppressed)));
    });

    test('wordmark participates in equality', () {
      const withWordmark = DotsPageChrome(wordmark: 'Dots. Memories');
      const withoutWordmark = DotsPageChrome(wordmark: null);
      expect(withWordmark, isNot(equals(withoutWordmark)));
    });

    test('centerLabel participates in equality', () {
      const withLabel = DotsPageChrome(centerLabel: 'A');
      const withoutLabel = DotsPageChrome(centerLabel: null);
      expect(withLabel, isNot(equals(withoutLabel)));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // T1.4 — DotsTemplate.defaultChrome participates in contentHash (R7)
  // ──────────────────────────────────────────────────────────────────────────

  group('DotsTemplate — defaultChrome and contentHash', () {
    const baseTemplate = DotsTemplate(
      documentId: 'doc_chrome_test',
      pageSize: DotsPageSize(width: 575.43, height: 720.0),
    );

    const chrome = DotsPageChrome(
      pageNumber: '1',
      centerLabel: 'tiempojuntos',
      wordmark: 'Dots. Memories',
    );

    const templateWithChrome = DotsTemplate(
      documentId: 'doc_chrome_test',
      pageSize: DotsPageSize(width: 575.43, height: 720.0),
      defaultChrome: chrome,
    );

    const templateWithSameChrome = DotsTemplate(
      documentId: 'doc_chrome_test',
      pageSize: DotsPageSize(width: 575.43, height: 720.0),
      defaultChrome: DotsPageChrome(
        pageNumber: '1',
        centerLabel: 'tiempojuntos',
        wordmark: 'Dots. Memories',
      ),
    );

    test('DotsTemplate — defaultChrome participates in contentHash', () {
      expect(
        baseTemplate.contentHash,
        isNot(equals(templateWithChrome.contentHash)),
      );
    });

    test('DotsTemplate — identical defaultChrome produces equal contentHash',
        () {
      expect(
        templateWithChrome.contentHash,
        equals(templateWithSameChrome.contentHash),
      );
    });

    test(
        'DotsTemplate — defaultChrome null is backward-compatible; '
        'no chrome rendered', () {
      // A template without defaultChrome must still be constructible and
      // must have defaultChrome == null — the renderer skips chrome in that
      // case (backward-compatibility guarantee from R10).
      expect(baseTemplate.defaultChrome, isNull);
    });
  });
}
