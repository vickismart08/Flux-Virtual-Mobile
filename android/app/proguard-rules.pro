# Flutter
-keep class io.flutter.** { *; }

# Play Core (Flutter deferred components — not used; suppress R8 missing-class errors)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Twilio Programmable Voice
-keep class com.twilio.** { *; }
-keep class tvo.webrtc.** { *; }
-dontwarn tvo.webrtc.**
-keep class com.twilio.voice.** { *; }
-keepattributes *Annotation*

# Firebase
-keep class com.google.firebase.** { *; }
