/// dots_pdf — JSON-templated PDF generation with whole-document or
/// 2-page-pair output, local-disk persistence, on-demand re-generation,
/// and a mobile-first memory budget.
///
/// Public surface only: implementation details live under `src/` and
/// must not be imported by consumers.
library;

export 'src/api/album_boda_cluster_content.dart' show AlbumBodaClusterContent;
export 'src/api/album_collage_content.dart' show AlbumCollageContent;
export 'src/api/album_cover_content.dart' show AlbumCoverContent;
export 'src/api/album_photo_arc_content.dart' show AlbumPhotoArcContent;
export 'src/api/album_simple_content.dart'
    show AlbumSimpleContent, DedicationContent, ClosingContent;
export 'src/api/build_boda_cluster_page.dart' show buildBodaClusterPageFor;
export 'src/api/build_cover_page.dart' show buildCoverPageFor;
export 'src/api/build_photo_arc_page.dart' show buildPhotoArcPageFor;
export 'src/api/build_polaroid_collage_page.dart' show buildPolaroidCollagePageFor;
export 'src/api/build_simple_pages.dart' show buildSimplePagesFor;
export 'src/render/polaroid_slot_position.dart' show PolaroidSlotPosition;
export 'src/render/polaroid_slots.dart' show kDefaultPolaroidSlots;
export 'src/api/dots_album_type.dart';
export 'src/api/dots_generator.dart';
export 'src/api/dots_output_mode.dart';
export 'src/config/dots_config_exception.dart';
export 'src/config/dots_pliego.dart';
export 'src/config/dots_template.dart';
export 'src/config/dots_template_parser.dart';
export 'src/cover/dots_cover_design.dart';
export 'src/cover/dots_cover_geometry.dart';
export 'src/cover/dots_cover_renderer.dart';
export 'src/cover/dots_cover_template.dart';
export 'src/cover/dots_paper_substrate.dart';
export 'src/cover/dots_supplier.dart';
export 'src/events/pdf_generation_event.dart';
export 'src/logging/dots_logger.dart';
export 'src/preview/dots_pdf_rasterizer.dart';
export 'src/render/dots_font_bundle.dart';
export 'src/render/layout/dots_layout_code.dart';
export 'src/render/layout/dots_layout_requirements.dart';
export 'src/render/layout/dots_layout_solver.dart';
export 'src/render/layout/dots_page_geometry.dart';
export 'src/render/layout/dots_slot_rect.dart';
