/// Single source of truth for "weight in kg → display string".
///
/// Domain validation already constrains stored weights to multiples of 0.5
/// (`ExecutedSet`'s `weightKg_half_kg_resolution` invariant), so the only
/// shapes we have to render are integers and `.5` halves. We render
/// integers without a decimal (`100`) and halves with one (`97.5`).
abstract final class WeightFormatter {
  static String formatKg(double kg) {
    if (kg == kg.truncateToDouble()) return kg.toInt().toString();
    return kg.toStringAsFixed(1);
  }
}
