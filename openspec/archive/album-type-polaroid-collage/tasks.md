# Tasks: album-type-polaroid-collage (slice 3 of 5)

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~590 (production ~345, tests ~245) |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Delivery strategy | ask-on-risk |

### Phase T1: Test scaffolding — RED

- [x] T1.1 Create `test/config/dots_polaroid_element_test.dart` — 5 failing tests
- [x] T1.2 Create `test/render/polaroid_collage_test.dart` — 7 failing tests
- [x] T1.3 Create `test/api/build_polaroid_collage_page_test.dart` — 8 failing tests

### Phase T2: Foundation — element type, slot table, exhaustiveness

- [x] T2.1 Add `DotsPolaroidElement` to `dots_template.dart`
- [x] T2.2 Create `polaroid_slot_position.dart` value object
- [x] T2.3 Create `polaroid_slots.dart` with kDefaultPolaroidSlots
- [x] T2.4 Add stub arm to `_buildElement` in `album_spread_page.dart`
- [x] T2.5 Add exhaustiveness arms to `dots_renderer.dart` (2 switches)
- [x] T2.6 Add exhaustiveness arm to `isolate_synthesis.dart`

### Phase T3: Polaroid rendering

- [x] T3.1 Implement `_buildPolaroidElement` in `album_spread_page.dart`

### Phase T4: Builder and value objects

- [x] T4.1 Create `album_collage_content.dart` value object
- [x] T4.2 Add `DotsAlbumSpreadPage.polaroidCollage()` factory
- [x] T4.3 Create `build_polaroid_collage_page.dart` builder

### Phase T5: Public exports and verification

- [x] T5.1 Add 4 new exports to `lib/dots_pdf.dart`
- [x] T5.2 Run `flutter test` — all tests pass GREEN
- [x] T5.3 Run `flutter analyze` — 0 issues
- [x] T5.4 Verify exports accessible
