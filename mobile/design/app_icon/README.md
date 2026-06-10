# App icon sources

Three candidate designs, each a self-contained folder of SVG masters. These are
**design sources**, not bundled assets — nothing here ships in the app binary.

| Folder | Concept |
| --- | --- |
| `a_zbar/` | Bold geometric **Z** monogram in a molten-ember gradient on graphite. |
| `b_ember_plate/` | Bumper plate face-on rendered as a glowing ember ring (also echoes the rest-timer ring). |
| `c_planned_actual/` | The first product pillar as a mark: ghost-outline pill (planned) beside a taller solid ember pill (actual). |
| `d_z_dumbbell/` | **Chosen design (wired).** Adjustable dumbbell top-down, flat duotone: ember Z (plates + corner-to-corner handle as one filleted path) with off-white smaller plates and spinlock wing nuts, on a graphite tile. Masters carry the v7 geometry + c2 colors; `variations/` holds the exploration history (v2–v7 compositions, v7c1–c4 color studies). |

## Files per design

| File | Role |
| --- | --- |
| `full.svg` | Full-bleed 1024×1024 composite. Source for **iOS** (all sizes), **Android legacy** `ic_launcher`, and the **Play Store** 512 listing icon. Square, opaque, no pre-rounded corners — iOS applies its own squircle mask. |
| `foreground.svg` | Android **adaptive-icon foreground** (transparent). **Note:** `a_zbar` and `d_z_dumbbell` are sized for flutter_launcher_icons' generated XML, which wraps this layer in a **16% inset** — so the glyph is drawn *larger* than the raw ⌀66 dp safe zone and the inset shrinks it into place. `b_ember_plate`/`c_planned_actual` still use the raw safe-zone convention and need the same retuning before wiring up. |
| `background.svg` | Android **adaptive-icon background**. Opaque, full-bleed, center-weighted because OEM masks crop the outer ~16% and parallax shifts the layers. |
| `monochrome.svg` | Single-color glyph. **Android 13+ themed icons** (system tints the alpha channel) and the base for the **iOS 18 tinted** variant (export as grayscale). |

All SVGs use plain paths and linear/radial gradients only — no text, filters, or
masks — so any rasterizer (`rsvg-convert`, Inkscape, sharp) renders them
identically.

## Export matrix

Rasterize each SVG at 1024×1024 first (e.g. `rsvg-convert -w 1024 -h 1024 full.svg -o full-1024.png`),
then either let `flutter_launcher_icons` fan out the sizes (recommended) or
export manually:

**iOS** (`ios/Runner/Assets.xcassets/AppIcon.appiconset/`, from `full.svg`):
20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024 px.
The 1024 marketing icon must have **no alpha channel**.
Optional iOS 18 variants: the default icon is already dark so it works for the
dark slot as-is (or use `foreground.svg` on transparent to let the system
supply the dark gradient); for the tinted slot export `monochrome.svg` as grayscale.

**Android adaptive** (`foreground.svg` / `background.svg` / `monochrome.svg`, 108 dp grid):
mdpi 108, hdpi 162, xhdpi 216, xxhdpi 324, xxxhdpi 432 px, plus
`mipmap-anydpi-v26/ic_launcher.xml` wiring the three layers.

**Android legacy** (`full.svg`, for API < 26 since `minSdk < 26`):
mdpi 48, hdpi 72, xhdpi 96, xxhdpi 144, xxxhdpi 192 px as `ic_launcher.png`.

**Play Store**: 512×512 PNG from `full.svg`.

## Pipeline (wired for `d_z_dumbbell`)

```bash
tool/generate_app_icons.sh   # from mobile/; requires `brew install librsvg`
```

The script rasterizes the four `d_z_dumbbell` SVGs to
`d_z_dumbbell/exports/*-1024.png` (plus `play_store-512.png`), then runs
`dart run flutter_launcher_icons` (configured in `pubspec.yaml`) to fan out
every Android and iOS asset. Edit an SVG master, re-run the script, commit
the regenerated PNGs.

To switch designs, change `DESIGN` in the script and the four
`flutter_launcher_icons` paths in `pubspec.yaml`.

The iOS master (`full.svg`) and the adaptive foreground carry different
glyph scales, documented in each SVG's header comment: Android's mask zooms
its padded layer ~1.5× (108 dp canvas → ~72 dp visible) while iOS shows the
full square, so each layer is tuned so both platforms display the glyph at
the same visual size.
