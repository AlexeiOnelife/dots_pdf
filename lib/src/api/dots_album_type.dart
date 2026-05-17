/// Album types the library supports.
///
/// Each value selects the front- and back-matter spread set defined in
/// `docs/templates/SPECS_album_types.md`. Body-page rendering does not
/// depend on the album type — the value only affects which fixed spreads
/// are inserted before and after the body, and the right-page top-center
/// header label.
enum DotsAlbumType {
  /// Wedding album. 5-page front/back matter set with a wedding-photo
  /// halo on the title spread and a 7-photo decorative cluster on
  /// "Antes de empezar el viaje".
  boda,

  /// Couples album. 10-page matter set with decorative blue circles on
  /// the cover and a 10-slot photo-circle arc on the
  /// "Un año lleno de recuerdos" spread.
  parejas,

  /// Children album. Structurally identical to [parejas]; differs only in
  /// wording (singular voice, child-name tokens).
  hijos,

  /// Individual album. 8-page matter set with a centered photo on the
  /// cover and a tilted-polaroid collage in the body intro spread.
  individuales,

  /// Other / generic album. Structurally identical to [individuales];
  /// differs only in wording and one extra opacity-gradient overlay on
  /// the polaroid collage spread.
  otros,
}
