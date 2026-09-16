# Obtenir le fichier .apk de Ma Sorcière ❤️

Trois voies, de la plus simple à la plus technique.

---

## Voie A — GitHub Actions (aucune installation, ~10 min)

**⚠️ Point important si tu as déjà un dépôt existant :** GitHub propose parfois, dans
l'onglet **Actions**, de créer automatiquement un fichier `main.yml` avec un modèle Flutter
générique. **Ne l'utilise pas** — ce modèle ne connaît pas les patchs nécessaires et peut
écraser le code source par le projet vide par défaut de Flutter. Utilise uniquement le
fichier fourni ici : `.github/workflows/build-apk.yml`.

Si tu as déjà créé un `main.yml` par erreur (c'est ce qui a provoqué l'échec précédent :
`lib/main.dart` remplacé par le modèle par défaut de Flutter, reconnaissable à
`colorScheme: .fromSeed(...)`), **supprime-le** avant de continuer :
`.github/workflows/main.yml` → bouton corbeille sur GitHub, puis commit.

### Étapes

1. Crée un compte sur <https://github.com> puis un dépôt **privé** nommé `ma-sorciere`.
2. Décompresse `ma_sorciere.zip` et envoie **tout** son contenu dans le dépôt, y compris
   le dossier caché `.github/`.
   - Soit par le site : **Add file → Upload files**, glisse tout le contenu du dossier
     `ma_sorciere`, puis **Commit**.
     > Certains navigateurs ignorent les dossiers commençant par un point lors d'un
     > glisser-déposer. Vérifie ensuite dans le dépôt que le chemin
     > `.github/workflows/build-apk.yml` existe bien. S'il manque, crée-le à la main via
     > **Add file → Create new file** en tapant ce chemin exact, puis colle le contenu du
     > fichier fourni dans le zip.
   - Soit en ligne de commande :
     ```bash
     cd ma_sorciere
     git init && git add -A && git commit -m "Ma Sorciere"
     git branch -M main
     git remote add origin https://github.com/TON_COMPTE/ma-sorciere.git
     git push -u origin main
     ```
3. Onglet **Actions** → le workflow « Construire l'APK Ma Sorcière » démarre seul (ou
   clique dessus puis **Run workflow**).
4. Quand le rond devient vert (8–12 min), ouvre l'exécution et télécharge l'artefact
   **ma-sorciere-apk** en bas de la page. Il contient `app-release.apk`.

Ce workflow génère maintenant le dossier `android/` dans un répertoire **temporaire**,
totalement séparé du dépôt, puis copie uniquement ce dossier `android/` dans le projet.
Il vérifie aussi explicitement, avant de continuer, que `lib/main.dart` contient bien le
code de Ma Sorcière (`MaSorciereApp`) — si jamais ce n'était pas le cas, la construction
s'arrête immédiatement avec un message clair plutôt que de continuer sur un projet vide.

---

## Voie B — Sur ton ordinateur (si Flutter est installé)

```bash
cd ma_sorciere
./build_apk.sh
```

Résultat : `build/app/outputs/flutter-apk/app-release.apk`

Sous Windows (PowerShell), les mêmes étapes manuellement :

```powershell
cd ma_sorciere
$scaffold = New-Item -ItemType Directory -Path "$env:TEMP\ms_scaffold" -Force
flutter create --org com.herdy --project-name ma_sorciere --platforms=android "$scaffold\scaffold"
Remove-Item -Recurse -Force android -ErrorAction SilentlyContinue
Copy-Item -Recurse "$scaffold\scaffold\android" android
python tool\patch_android.py
flutter pub get
flutter build apk --release
```

Prérequis : `flutter doctor` doit être vert pour « Flutter » et « Android toolchain ».

---

## Voie C — Codemagic (alternative cloud à GitHub Actions)

<https://codemagic.io> propose des minutes gratuites. Connecte le dépôt GitHub créé en
voie A, choisis « Flutter App (Android) », mode release, et remplace l'étape de build par
un script shell équivalent à `build_apk.sh` (génération isolée + patchs).

---

## Installer l'APK sur le téléphone

1. Transfère `app-release.apk` sur le téléphone (câble USB, Bluetooth, Google Drive…).
2. Ouvre-le depuis le gestionnaire de fichiers.
3. Android demandera d'autoriser « l'installation d'applications inconnues » pour
   l'application depuis laquelle tu ouvres le fichier : accepte.
4. À la première ouverture, accepte les notifications.

L'APK est signé avec la clé de debug : il s'installe parfaitement, il ne peut simplement
pas être publié sur le Play Store. Pour une vraie clé de signature, voir la section 4 du
`README.md`.

---

## Si la compilation échoue encore

Copie-moi le message d'erreur du journal (onglet Actions → l'étape rouge) et je corrige.

**Erreur déjà rencontrée et corrigée :** `This requires the experimental 'dot-shorthands'
language feature` dans `lib/main.dart`. Cela signifiait que le fichier avait été remplacé
par le modèle par défaut de Flutter — voir l'encadré au tout début de ce document.
