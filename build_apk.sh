#!/usr/bin/env bash
# Construit l'APK de Ma Sorciere de bout en bout.
# Prerequis : Flutter installe + SDK Android (flutter doctor sans erreur).
#
# IMPORTANT : flutter create tourne dans un dossier TEMPORAIRE isole, jamais
# a la racine du projet. Seul le dossier android/ genere est copie ensuite.
# Cela evite tout risque que lib/main.dart soit ecrase par le modele par
# defaut de Flutter.
set -euo pipefail

cd "$(dirname "$0")"
PROJECT_DIR="$(pwd)"
SCRATCH="$(mktemp -d)"

echo "==> Génération de android/ dans un dossier temporaire isolé"
flutter create --org com.herdy --project-name ma_sorciere --platforms=android "$SCRATCH/scaffold"

echo "==> Copie du dossier android/ (uniquement) dans le projet"
rm -rf "$PROJECT_DIR/android"
cp -R "$SCRATCH/scaffold/android" "$PROJECT_DIR/android"
rm -rf "$SCRATCH"

echo "==> Vérification que le code source n'a pas été touché"
test -f "$PROJECT_DIR/lib/main.dart"
grep -q "MaSorciereApp" "$PROJECT_DIR/lib/main.dart" \
  || { echo "ERREUR: lib/main.dart ne correspond plus au projet Ma Sorcière."; exit 1; }

echo "==> Application des patchs Android"
python3 tool/patch_android.py

echo "==> Dépendances"
flutter pub get

echo "==> Compilation de l'APK (release)"
flutter build apk --release

echo
echo "APK généré : build/app/outputs/flutter-apk/app-release.apk"
