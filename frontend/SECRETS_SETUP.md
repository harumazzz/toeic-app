# Secrets Configuration for CI/CD

This document outlines the secrets that need to be configured in your GitHub repository for the
CI/CD pipeline to work.

## GitHub Repository Secrets

Go to your repository → Settings → Secrets and variables → Actions, and add the following secrets:

### Android Secrets

1. **ANDROID_KEYSTORE**

    - Base64 encoded keystore file
    - Generate: `base64 -i your-keystore.jks`

2. **ANDROID_KEYSTORE_PASSWORD**

    - Password for the keystore file

3. **ANDROID_KEY_PASSWORD**

    - Password for the key in the keystore

4. **ANDROID_KEY_ALIAS**

    - Alias of the key in the keystore (usually "release")

5. **GOOGLE_PLAY_SERVICE_ACCOUNT_JSON**
    - Service account JSON for Google Play Console API
    - Create in Google Cloud Console → IAM → Service Accounts

### iOS Secrets

1. **IOS_CERTIFICATE**

    - Base64 encoded .p12 certificate file
    - Export from Keychain Access

2. **IOS_CERTIFICATE_PASSWORD**

    - Password for the .p12 certificate

3. **IOS_PROVISIONING_PROFILE**

    - Base64 encoded .mobileprovision file
    - Download from Apple Developer Portal

4. **APPLE_ID**

    - Your Apple ID email

5. **APPLE_APP_PASSWORD**
    - App-specific password for your Apple ID
    - Generate at appleid.apple.com

## Setup Instructions

### Android Setup

1. Generate release keystore (see android/SIGNING_SETUP.md)
2. Create Google Play service account
3. Upload secrets to GitHub

### iOS Setup

1. Create distribution certificate in Apple Developer Portal
2. Create App Store provisioning profile
3. Export certificate as .p12 from Keychain
4. Create app-specific password
5. Upload secrets to GitHub

## Security Notes

-   Never commit these secrets to your repository
-   Rotate secrets regularly
-   Use different keystores for different environments
-   Limit service account permissions to minimum required
-   Monitor secret usage in GitHub Actions logs

## Testing the Pipeline

1. Push to main branch to trigger full build and deploy
2. Create pull request to trigger tests only
3. Check GitHub Actions tab for build status
4. Monitor app store console for deployment status
