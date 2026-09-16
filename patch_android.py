#!/usr/bin/env python3
"""
Applique automatiquement les 3 patchs Android necessaires a Ma Sorciere :
  1. minSdk 23 + desugaring (flutter_local_notifications)
  2. MainActivity qui herite de FlutterFragmentActivity (local_auth)
  3. Permissions + receivers de notifications dans le manifeste

A lancer depuis la racine du projet, APRES "flutter create ... .".
    python3 tool/patch_android.py
"""
import glob
import os
import re
import sys

APP_LABEL = "Ma Sorciere"
DESUGAR = "com.android.tools:desugar_jdk_libs:2.1.4"


def log(msg):
    print("[patch] " + msg)


# --------------------------------------------------------------- build.gradle
def patch_gradle():
    candidates = [
        "android/app/build.gradle.kts",
        "android/app/build.gradle",
    ]
    path = next((c for c in candidates if os.path.exists(c)), None)
    if not path:
        sys.exit("ERREUR: android/app/build.gradle(.kts) introuvable. "
                 "Lance d'abord: flutter create --platforms=android .")
    kts = path.endswith(".kts")
    src = open(path, encoding="utf-8").read()

    # minSdk
    src = re.sub(r"minSdk(Version)?\s*=?\s*flutter\.minSdkVersion",
                 "minSdk = 23" if kts else "minSdkVersion 23", src)
    src = re.sub(r"minSdk(Version)?\s*=\s*\d+",
                 "minSdk = 23" if kts else "minSdkVersion 23", src)

    # Java 11 minimum (requis par le desugaring)
    src = src.replace("JavaVersion.VERSION_1_8", "JavaVersion.VERSION_11")
    src = src.replace('jvmTarget = "1.8"', 'jvmTarget = "11"')

    # Desugaring dans compileOptions
    flag = ("isCoreLibraryDesugaringEnabled = true" if kts
            else "coreLibraryDesugaringEnabled true")
    if "oreLibraryDesugaringEnabled" not in src:
        if "compileOptions {" in src:
            src = src.replace("compileOptions {",
                              "compileOptions {\n        " + flag, 1)
        else:
            block = ("\n    compileOptions {\n        " + flag +
                     "\n    }\n")
            src = re.sub(r"android\s*\{", "android {" + block, src, count=1)

    # Dependance de desugaring
    if "coreLibraryDesugaring" not in src:
        dep = ('\ndependencies {\n    coreLibraryDesugaring("%s")\n}\n' % DESUGAR
               if kts else
               "\ndependencies {\n    coreLibraryDesugaring '%s'\n}\n" % DESUGAR)
        src = src.rstrip() + "\n" + dep

    open(path, "w", encoding="utf-8").write(src)
    log("OK  " + path + " (minSdk 23 + desugaring)")


# ------------------------------------------------------------- MainActivity
def patch_main_activity():
    files = glob.glob("android/app/src/main/kotlin/**/MainActivity.kt",
                      recursive=True)
    files += glob.glob("android/app/src/main/java/**/MainActivity.java",
                       recursive=True)
    if not files:
        log("ATTENTION: MainActivity introuvable, patch ignore.")
        return
    for path in files:
        src = open(path, encoding="utf-8").read()
        src = src.replace(
            "io.flutter.embedding.android.FlutterActivity",
            "io.flutter.embedding.android.FlutterFragmentActivity")
        src = re.sub(r"\bFlutterActivity\b", "FlutterFragmentActivity", src)
        open(path, "w", encoding="utf-8").write(src)
        log("OK  " + path + " (FlutterFragmentActivity)")


# ----------------------------------------------------------------- manifeste
PERMISSIONS = [
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.RECEIVE_BOOT_COMPLETED",
    "android.permission.VIBRATE",
    "android.permission.USE_BIOMETRIC",
    "android.permission.USE_FINGERPRINT",
]

RECEIVERS = """
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
"""


def patch_manifest():
    path = "android/app/src/main/AndroidManifest.xml"
    if not os.path.exists(path):
        sys.exit("ERREUR: " + path + " introuvable.")
    src = open(path, encoding="utf-8").read()

    block = ""
    for perm in PERMISSIONS:
        if perm not in src:
            block += '    <uses-permission android:name="%s" />\n' % perm
    if block:
        src = src.replace("    <application", block + "    <application", 1)

    if "ScheduledNotificationBootReceiver" not in src:
        src = src.replace("    </application>", RECEIVERS + "    </application>", 1)

    src = re.sub(r'android:label="[^"]*"', 'android:label="%s"' % APP_LABEL,
                 src, count=1)

    open(path, "w", encoding="utf-8").write(src)
    log("OK  " + path + " (permissions + receivers + label)")


if __name__ == "__main__":
    if not os.path.exists("pubspec.yaml"):
        sys.exit("ERREUR: lance ce script depuis la racine du projet ma_sorciere.")
    patch_gradle()
    patch_main_activity()
    patch_manifest()
    log("Patchs Android appliques. Tu peux lancer: flutter build apk --release")
