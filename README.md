# Ma Sorcière ❤️

Application Android de suivi du cycle menstruel — **100 % hors connexion**, données stockées
uniquement sur le téléphone, verrouillage par code PIN et biométrie.

Technologie : **Flutter (Dart)** + **SQLite (sqflite)**. Un seul code source, compilable en APK.

---

## 1. Structure du projet

```
ma_sorciere/
├── pubspec.yaml                  # dépendances
├── analysis_options.yaml
├── android_patch/                # fichiers à recopier dans android/ après "flutter create ."
│   ├── MainActivity.kt
│   ├── AndroidManifest-extrait.xml
│   └── build.gradle-extrait.txt
├── test/
│   └── widget_test.dart          # tests du moteur de cycle
└── lib/
    ├── main.dart                 # point d'entrée, thème, verrouillage
    ├── core/
    │   ├── constants.dart        # humeurs, symptômes, textes de prudence
    │   ├── date_utils.dart       # utilitaires de dates en français
    │   ├── theme.dart            # identité visuelle (rose / lavande, clair + sombre)
    │   ├── cycle_engine.dart     # CALCUL DU CYCLE (jour, phase, ovulation, moyennes)
    │   └── advice.dart           # conseils intelligents 🧠
    ├── data/
    │   ├── models.dart           # Règles, Humeur, Symptôme, Rapport
    │   ├── db.dart               # base de données locale SQLite
    │   └── settings.dart         # paramètres (SharedPreferences)
    ├── state/
    │   └── app_state.dart        # état global, relie tous les écrans aux données
    ├── services/
    │   ├── notification_service.dart  # notifications locales programmées
    │   ├── security_service.dart      # PIN (SHA-256) + biométrie
    │   └── backup_service.dart        # export / import JSON local
    ├── widgets/
    │   ├── common.dart           # cartes, encadrés, boutons
    │   └── charts.dart           # graphiques (barres, fréquences, anneau)
    └── screens/
        ├── lock_screen.dart      # écran de déverrouillage
        ├── home_screen.dart      # écran d'accueil
        ├── calendar_screen.dart  # calendrier mensuel
        ├── day_detail_screen.dart# détail d'une journée
        ├── period_screen.dart    # suivi des règles
        ├── mood_screen.dart      # humeur du jour
        ├── mood_history_screen.dart # historique / tendances d'humeur
        ├── symptom_screen.dart   # symptômes + intensité
        ├── intercourse_screen.dart # rapports 💕
        ├── stats_screen.dart     # statistiques 📊
        └── settings_screen.dart  # paramètres ⚙️
```

---

> **Tu veux juste l'APK sans rien installer ?** Lis `COMMENT-OBTENIR-L-APK.md` :
> le dépôt contient un workflow GitHub Actions qui compile le projet en ligne et te
> rend le fichier `.apk` à télécharger.

## 2. Préparation (une seule fois)

1. Installer Flutter (canal stable) : <https://docs.flutter.dev/get-started/install>
2. Installer Android Studio + le SDK Android + accepter les licences :

```bash
flutter doctor
flutter doctor --android-licenses
```

## 3. Générer les dossiers natifs et compiler

Le dossier `android/` n'est pas inclus : il est généré par Flutter pour correspondre
exactement à ta version installée (c'est la méthode la plus sûre pour éviter les erreurs
de compilation liées à Gradle).

```bash
cd ma_sorciere

# 1) Génère android/ dans un dossier temporaire ISOLÉ, puis copie
#    uniquement ce dossier dans le projet. Ne touche jamais à lib/,
#    pubspec.yaml ou test/ : c'est ./build_apk.sh qui fait exactement ça.
./build_apk.sh
exit 0  # (retire cette ligne si tu préfères dérouler les étapes toi-même ci-dessous)

scaffold=$(mktemp -d)
flutter create --org com.herdy --project-name ma_sorciere --platforms=android "$scaffold/scaffold"
rm -rf android && cp -R "$scaffold/scaffold/android" ./android

# 2) Récupère les dépendances
flutter pub get
```

### 3.1 Appliquer les 3 patchs Android (obligatoire)

**a) `android/app/build.gradle.kts`** (ou `build.gradle`) : reprends le contenu de
`android_patch/build.gradle-extrait.txt` — l'essentiel est `minSdk = 23`,
`isCoreLibraryDesugaringEnabled = true` et la dépendance `desugar_jdk_libs`.

**b) `android/app/src/main/kotlin/com/herdy/ma_sorciere/MainActivity.kt`** : remplace son
contenu par celui de `android_patch/MainActivity.kt` (hériter de `FlutterFragmentActivity`
est obligatoire pour la biométrie).

**c) `android/app/src/main/AndroidManifest.xml`** : ajoute les permissions et les deux
`<receiver>` listés dans `android_patch/AndroidManifest-extrait.xml`, et mets
`android:label="Ma Sorcière"`.

### 3.2 Vérifier

```bash
flutter analyze
flutter test
```

### 3.3 Lancer sur un téléphone branché en USB (débogage activé)

```bash
flutter devices
flutter run
```

## 4. Commandes exactes pour générer l'APK

**APK de test (le plus simple, installable directement) :**

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

**APK allégés par architecture (fichiers plus petits) :**

```bash
flutter build apk --split-per-abi --release
# → app-armeabi-v7a-release.apk / app-arm64-v8a-release.apk / app-x86_64-release.apk
```

**Installer sur le téléphone :**

```bash
flutter install
# ou
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Signer l'APK (pour une installation durable / partage)

```bash
keytool -genkey -v -keystore ~/ma-sorciere.jks -keyalg RSA -keysize 2048 -validity 10000 -alias masorciere
```

Crée `android/key.properties` :

```properties
storePassword=TON_MOT_DE_PASSE
keyPassword=TON_MOT_DE_PASSE
keyAlias=masorciere
storeFile=/chemin/absolu/vers/ma-sorciere.jks
```

Puis, dans `android/app/build.gradle.kts`, déclare `signingConfigs.release` et utilise-le
dans `buildTypes.release` (voir la doc Flutter « Build and release an Android app »).
Sans cette étape, l'APK `--release` est signé avec la clé de debug : il s'installe quand
même, il ne peut simplement pas être publié sur le Play Store.

---

## 5. Ce qui est réellement implémenté

| Demande | Où |
|---|---|
| Jour du cycle, phase, prochaines règles, ovulation, fenêtre fertile | `core/cycle_engine.dart` |
| Apprentissage de la durée moyenne (6 derniers cycles) | `CycleEngine.averageCycleLength` |
| Calendrier mensuel + marqueurs 🔴🌱⭐💕😊🤕 | `screens/calendar_screen.dart` |
| Correction manuelle des dates de règles | `day_detail_screen.dart`, `period_screen.dart` |
| Règles : début, fin, intensité, douleurs, notes | `period_screen.dart` |
| Rapports 💕 avec heure, protection, notes | `intercourse_screen.dart` |
| Humeurs multiples + commentaire + historique | `mood_screen.dart`, `mood_history_screen.dart` |
| 15 symptômes avec intensité 1–3 | `symptom_screen.dart` |
| Conseils intelligents + alerte « consulte un professionnel » | `core/advice.dart` |
| Statistiques et graphiques | `stats_screen.dart`, `widgets/charts.dart` |
| 5 notifications activables séparément | `services/notification_service.dart` |
| PIN + biométrie + effacement + export/import | `security_service.dart`, `backup_service.dart` |
| Thème clair/sombre, prénom, durées, dates | `settings_screen.dart` |

Le premier cycle (**16/09/2026, 29 jours**) est enregistré automatiquement au tout premier
lancement, puis il est modifiable dans les paramètres ou le calendrier.

**Prudence** : l'application affiche partout que la fenêtre fertile et l'ovulation sont des
estimations et ne sont **pas** une méthode de contraception, et elle ne pose jamais de
diagnostic.

---

## 6. Si une erreur de compilation apparaît

| Message | Solution |
|---|---|
| `Cannot fit requested classes… / desugaring` | patch **a** non appliqué (`coreLibraryDesugaring`) |
| `local_auth… requires FragmentActivity` | patch **b** non appliqué (`FlutterFragmentActivity`) |
| `uses-sdk:minSdkVersion 21 cannot be smaller than 23` | mets `minSdk = 23` |
| `Namespace not specified` (vieux plugin) | `flutter upgrade` puis `flutter clean && flutter pub get` |
| Conflit de versions dans `pubspec.yaml` | `flutter pub upgrade --major-versions` |
| Notification jamais reçue | autorise les notifications de l'app dans les réglages Android |

En cas de doute, la remise à zéro complète :

```bash
flutter clean && flutter pub get && flutter build apk --release
```
