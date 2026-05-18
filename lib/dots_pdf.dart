/// dots_pdf — JSON-templated PDF generation with whole-document or
/// 2-page-pair output, local-disk persistence, on-demand re-generation,
/// and a mobile-first memory budget.
///
/// Public surface only: implementation details live under `src/` and
/// must not be imported by consumers.
library;

export 'src/api/dots_album_type.dart';
export 'src/api/dots_generator.dart';
export 'src/api/dots_output_mode.dart';
export 'src/config/dots_config_exception.dart';
export 'src/config/dots_pliego.dart';
export 'src/config/dots_template.dart';
export 'src/config/dots_template_parser.dart';
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
