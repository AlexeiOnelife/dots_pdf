import '../config/dots_template.dart';
import 'dots_renderer.dart';

/// Renders 1–2 pages of the template into a single pair PDF file.
///
/// The renderer is invoked once per pair by the orchestration layer.
/// It expects [pages] to be exactly the pages belonging to one pair
/// (length 1 for the trailing odd page, length 2 otherwise).
class PairDocumentRenderer extends DotsRenderer {
  /// Creates a pair renderer.
  PairDocumentRenderer({
    required super.fileSystem,
    required super.logger,
    super.drawCropMarks,
    super.tmpDir,
    super.urlFetcher,
    super.fontBundle,
    super.onPhotoSlotFailure,
  });

  @override
  Future<void> render({
    required DotsTemplate template,
    required List<DotsPage> pages,
    required String outputPath,
  }) {
    assert(
      pages.length == 1 || pages.length == 2,
      'PairDocumentRenderer expects a 1- or 2-page slice; got ${pages.length}',
    );
    log.info(
      'PairDocumentRenderer: rendering ${pages.length} pages '
      'to "$outputPath"',
    );
    return renderPagesToFile(
      template: template,
      pages: pages,
      outputPath: outputPath,
    );
  }
}
