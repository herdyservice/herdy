class MoodOption {
  final String id;
  final String emoji;
  final String label;
  const MoodOption(this.id, this.emoji, this.label);
}

const moodOptions = <MoodOption>[
  MoodOption('heureuse', '😊', 'Heureuse'),
  MoodOption('affectueuse', '🥰', 'Affectueuse'),
  MoodOption('bien', '🙂', 'Bien'),
  MoodOption('neutre', '😐', 'Neutre'),
  MoodOption('triste', '😔', 'Triste'),
  MoodOption('irritee', '😡', 'Irritée'),
  MoodOption('fatiguee', '😴', 'Fatiguée'),
  MoodOption('stressee', '🤯', 'Stressée'),
  MoodOption('emotive', '😭', 'Émotive'),
  MoodOption('libido', '😍', 'Libido élevée'),
];

MoodOption moodById(String id) => moodOptions.firstWhere(
      (m) => m.id == id,
      orElse: () => MoodOption(id, '•', id),
    );

const symptomOptions = <String>[
  'Douleurs abdominales',
  'Crampes',
  'Mal de tête',
  'Seins sensibles',
  'Fatigue',
  'Ballonnements',
  'Acné',
  'Nausées',
  'Mal de dos',
  'Pertes vaginales',
  'Sommeil perturbé',
  'Appétit augmenté',
  'Appétit diminué',
  'Libido',
  'Autre',
];

const flowOptions = <String, String>{
  'legere': 'Légère',
  'moyenne': 'Moyenne',
  'forte': 'Forte',
};

const intensiteLabels = <String>['Aucune', 'Légère', 'Moyenne', 'Forte'];

const disclaimerFertile =
    "La fenêtre fertile et l'ovulation affichées sont de simples estimations statistiques. "
    "Elles ne constituent en aucun cas une méthode de contraception fiable.";

const disclaimerMedical =
    "Les conseils affichés sont généraux et ne remplacent pas l'avis d'un professionnel de santé.";
