# R8 keeps for the release build (see build.gradle.kts).
#
# Only what reflection reaches. Anything named in AndroidManifest.xml — the
# activity, the five widget providers, the adhan services and receivers — is
# kept automatically, so none of this app's own Kotlin needs a rule here.

# flutter_local_notifications persists each scheduled notification as JSON and
# reads it back through Gson, which resolves fields by name. Obfuscate those
# classes and every reminder scheduled before the update fails to restore
# after a reboot.
-keep class com.dexterous.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Gson's own reflective machinery, pulled in by the above.
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-dontwarn com.google.gson.**

# Desugared java.time, which flutter_local_notifications schedules against.
-dontwarn java.time.**
-dontwarn javax.annotation.**
