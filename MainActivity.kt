// Copie ce fichier dans :
// android/app/src/main/kotlin/<ton/package/>/MainActivity.kt
// en remplaçant la ligne "package" par celle qui existe déjà dans ton projet.
//
// IMPORTANT : on hérite de FlutterFragmentActivity (et non FlutterActivity)
// car le plugin local_auth (biométrie) l'exige.

package com.herdy.ma_sorciere

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
