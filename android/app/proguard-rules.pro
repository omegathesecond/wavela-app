# Flutter and Dart related rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Google ML Kit Text Recognition rules
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
-keep class com.google.mlkit.vision.text.latin.** { *; }

# Google ML Kit Face Detection rules
-keep class com.google.mlkit.vision.face.** { *; }

# Google ML Kit Pose Detection rules
-keep class com.google.mlkit.vision.pose.** { *; }

# Google ML Kit Selfie Segmentation rules
-keep class com.google.mlkit.vision.segmentation.** { *; }
-keep class com.google.mlkit.vision.segmentation.selfie.** { *; }

# Google ML Kit Common rules
-keep class com.google.mlkit.common.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }

# Camera plugin rules
-keep class io.flutter.plugins.camera.** { *; }

# GetX rules
-keep class com.example.** { *; }
-keepclassmembers class * extends java.lang.Enum {
    <fields>;
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Dio HTTP rules
-keep class com.diox.** { *; }

# General Android rules
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom serialization methods
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Fingerprint SDK rules (commented out for now)
# -keep class com.aratek.** { *; }
# -keep class com.secugen.** { *; }
# -dontwarn com.aratek.**
# -dontwarn com.secugen.**