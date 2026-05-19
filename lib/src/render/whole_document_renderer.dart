import '../config/dots_template.dart';
import 'dots_renderer.dart';

/// Renders every page of the template into a single PDF file.
///
/// Memory contract: build pages one at a time, append each to the
/// `pw.Document`, then null out any page-local resources (images,
/// canvases) before constructing the next page.
class WholeDocumentRenderer extends DotsRenderer {
  /// Creates a whole-document renderer.
  WholeDocumentRenderer({
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
    log.info(
      'WholeDocumentRenderer: rendering ${pages.length} pages '
      'to "$outputPath"',
    );
    return renderPagesToFile(
      template: template,
      pages: pages,
      outputPath: outputPath,
    );
  }
}
