import '../data/models.dart';
import 'constants.dart';
import 'cycle_engine.dart';
import 'date_utils.dart';

/// Symptômes qui, à forte intensité, justifient un message de prudence.
const _symptomesVigilance = <String>[
  'Douleurs abdominales',
  'Crampes',
  'Mal de tête',
  'Nausées',
  'Mal de dos',
];

class Advice {
  final String text;
  final bool warning;
  const Advice(this.text, {this.warning = false});
}

List<Advice> adviceFor({
  required CycleInfo info,
  required List<SymptomEntry> symptoms,
  required MoodEntry? mood,
  required String prenom,
}) {
  final out = <Advice>[];
  final j = info.dayOfCycle;

  if (info.isPeriod && j == 1) {
    out.add(const Advice(
        "🌸 Aujourd'hui est le Jour 1 de ton cycle. Prends soin de toi, "
        "repose-toi si nécessaire et pense à bien t'hydrater."));
  } else if (info.isPeriod) {
    out.add(Advice(
        "🔴 Jour $j de ton cycle, tu es encore dans tes règles. Une bouillotte, "
        "des boissons chaudes et un peu de douceur peuvent aider."));
  } else {
    switch (info.phase) {
      case Phase.folliculaire:
        out.add(const Advice(
            "🌱 Phase folliculaire : l'énergie remonte doucement. C'est souvent "
            "un bon moment pour bouger, planifier et te lancer dans de nouvelles choses."));
        break;
      case Phase.ovulation:
        out.add(const Advice(
            "⭐ Ovulation estimée aujourd'hui. Il s'agit d'une estimation calculée, "
            "pas d'une certitude biologique."));
        break;
      case Phase.luteale:
        out.add(const Advice(
            "🌙 Phase lutéale : la fatigue, les fringales ou l'irritabilité sont fréquentes. "
            "Un sommeil régulier et des repas équilibrés font beaucoup de bien."));
        break;
      case Phase.menstruation:
        break;
    }
  }

  final d = info.daysUntilNext;
  if (!info.isPeriod && d >= 0 && d <= 3) {
    out.add(Advice(d == 0
        ? "🗓️ Tes règles sont estimées pour aujourd'hui. Pense à prévoir de quoi être à l'aise."
        : "🗓️ Tes règles sont estimées dans ${d == 1 ? '1 jour' : '$d jours'} "
            "(${fmtFr(info.nextStart)})."));
  }

  if (info.isFertile && !info.isPeriod) {
    out.add(const Advice(
        "🌱 Tu es dans la fenêtre fertile estimée. $disclaimerFertile"));
  }

  // Humeurs
  if (mood != null && mood.moods.isNotEmpty) {
    if (mood.moods.contains('stressee') || mood.moods.contains('emotive')) {
      out.add(const Advice(
          "💛 Journée un peu chargée émotionnellement ? Respire, ralentis, "
          "et parle à quelqu'un en qui tu as confiance."));
    }
    if (mood.moods.contains('fatiguee')) {
      out.add(const Advice(
          "😴 Fatigue notée aujourd'hui : essaie de te coucher un peu plus tôt "
          "et de limiter les écrans en soirée."));
    }
  }

  // Symptômes
  if (symptoms.isNotEmpty) {
    final noms = symptoms.map((s) => s.name).toList();
    if (noms.contains('Crampes') || noms.contains('Douleurs abdominales')) {
      out.add(const Advice(
          "🫖 Chaleur locale, hydratation et repos soulagent souvent les crampes légères."));
    }
    if (noms.contains('Ballonnements')) {
      out.add(const Advice(
          "🥗 Repas plus légers et moins salés peuvent réduire la sensation de ballonnement."));
    }
    final fortes = symptoms
        .where((s) => s.intensity >= 3 && _symptomesVigilance.contains(s.name))
        .map((s) => s.name)
        .toSet();
    if (fortes.isNotEmpty) {
      out.add(Advice(
          "⚠️ Tu as enregistré des symptômes de forte intensité (${fortes.join(', ')}). "
          "Si cela se répète, dure ou t'empêche de mener tes activités habituelles, "
          "il vaut mieux en parler à un professionnel de santé. Cette application ne pose aucun diagnostic.",
          warning: true));
    }
  }

  out.add(const Advice(disclaimerMedical));
  return out;
}
