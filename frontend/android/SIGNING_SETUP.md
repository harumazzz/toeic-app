# Android Keystore Setup for Production

## Generate Release Keystore

To generate a release keystore for signing your Android app:

```bash
keytool -genkey -v -keystore release-key.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000
```

## Key Properties File

Create a `key.properties` file in the `android` folder with:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=release
storeFile=../release-key.keystore
```

## Security Notes

1. Never commit the `key.properties` file or `release-key.keystore` to version control
2. Store these files securely and create backups
3. Use strong passwords for both store and key
4. Keep the keystore file safe - losing it means you cannot update your published app

## CI/CD Integration

For CI/CD pipelines, you can inject signing properties as environment variables:

-   `android.injected.signing.store.file`
-   `android.injected.signing.store.password`
-   `android.injected.signing.key.alias`
-   `android.injected.signing.key.password`

## Build Commands

Debug build:

```bash
flutter build apk --debug
```

Release build:

```bash
flutter build apk --release
flutter build appbundle --release
```
