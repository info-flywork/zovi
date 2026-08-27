# RevenueCat / Google Play Billing
-keep class com.revenuecat.** { *; }
-keep class com.android.vending.billing.** { *; }

# Google Sign-In / Credential Manager / Firebase Auth (release minify)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keep class com.google.** { *; }
-keep class androidx.credentials.** { *; }
-keep class androidx.credentials.playservices.** { *; }
-dontwarn com.google.**
-dontwarn androidx.credentials.**
