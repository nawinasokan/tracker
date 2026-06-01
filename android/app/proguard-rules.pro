# Flutter release builds enable R8 (code shrinking + obfuscation) automatically.
# flutter_local_notifications (de)serializes scheduled notifications with Gson,
# which relies on generic type information. R8 strips the generic `Signature`
# attribute by default, so Gson's TypeToken fails at schedule time with
# "Missing type parameter." — surfacing in-app as "Couldn't set reminders".
# Keeping the Signature/annotation attributes and the Gson + plugin classes
# fixes it.

# --- Generic signatures & annotations (the critical fix) ---
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses,EnclosingMethod

# --- Gson ---
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
    @com.google.gson.annotations.Expose <fields>;
}
-dontwarn com.google.gson.**

# --- flutter_local_notifications model classes serialized via Gson ---
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**
