# Firebase production connection

Create a Firebase project, add your Android app with applicationId `com.mrniazi.app`, then place the generated `google-services.json` in `android/app/`.

Enable:
- Authentication
- Cloud Firestore
- Cloud Messaging
- App Check

Before launch, replace the demo order storage in `lib/main.dart` with Firestore writes and use authenticated admin accounts. Do not ship the sample permissive `orders create` rule without adding validation/App Check.
