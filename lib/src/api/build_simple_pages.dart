import '../config/dots_template.dart';
import 'album_simple_content.dart';
import 'dots_album_type.dart';

/// Builds the ordered list of simple spread pages for [type] given [content].
///
/// Emission rules:
///   - [DotsAlbumType.boda]: only a closing page is emitted (boda has no
///     dedication in the design spec). A dedication in [content] is silently
///     ignored for boda.
///   - All other types: dedication first (when [content.dedication] != null),
///     then closing (when [content.closing] != null).
///
/// When both fields of [content] are `null`, an empty list is returned.
///
/// [contextLabelValue] is the pre-resolved string the caller has already
/// derived from [type.contextLabelToken] and their variable map.  This
/// function does NOT perform token substitution — it passes the value
/// straight through to the named constructors.
///
/// [firstPageNumber] is assigned to the first emitted page; subsequent pages
/// receive sequentially incremented numbers.
List<DotsAlbumSpreadPage> buildSimplePagesFor(
  DotsAlbumType type,
  AlbumSimpleContent content, {
  required int firstPageNumber,
  required String contextLabelValue,
}) {
  final pages = <DotsAlbumSpreadPage>[];

  if (_hasDedication(type)) {
    final dedication = content.dedication;
    if (dedication != null) {
      pages.add(DotsAlbumSpreadPage.dedication(
        type: type,
        pageNumber: firstPageNumber + pages.length,
        contextLabelValue: contextLabelValue,
        title: dedication.title,
        body: dedication.body,
        signature: dedication.signature,
      ));
    }
  }

  final closing = content.closing;
  if (closing != null) {
    pages.add(DotsAlbumSpreadPage.closing(
      type: type,
      pageNumber: firstPageNumber + pages.length,
      contextLabelValue: contextLabelValue,
      photoPath: closing.photoPath,
      title: closing.title,
      subtitle: closing.subtitle,
    ));
  }

  return pages;
}

/// Returns `true` for every album type that has a dedication page.
/// Only [DotsAlbumType.boda] does not — it goes straight to a closing page.
bool _hasDedication(DotsAlbumType type) => type != DotsAlbumType.boda;
