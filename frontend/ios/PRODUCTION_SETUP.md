# iOS Production Setup Guide

## Prerequisites

1. **Apple Developer Account**: You need a paid Apple Developer account to distribute on the App
   Store
2. **Xcode**: Latest version of Xcode installed on a Mac
3. **Certificates and Provisioning Profiles**: Set up in Apple Developer Console

## Setup Steps

### 1. Configure Bundle Identifier

Open `ios/Runner.xcodeproj` in Xcode and update:

-   Bundle Identifier: `com.haruma.toeic.learn`
-   Display Name: `TOEIC Learn`
-   Version: Set appropriate version numbers

### 2. Signing Configuration

In Xcode project settings:

1. Select your development team
2. Configure signing certificates
3. Set up provisioning profiles for development and distribution

### 3. App Store Information

Update the following in Xcode:

-   App icons (all required sizes)
-   Launch screen
-   App category: Education
-   Privacy permissions descriptions

### 4. Build Configurations

#### Debug Build

```bash
flutter build ios --debug
```

#### Release Build

```bash
flutter build ios --release
```

#### App Store Build

```bash
flutter build ipa --release
```

### 5. Deployment

#### TestFlight (Beta Testing)

1. Build archive in Xcode (Product → Archive)
2. Upload to App Store Connect
3. Distribute via TestFlight

#### App Store Release

1. Create app listing in App Store Connect
2. Upload build via Xcode or Application Loader
3. Submit for review

## Important Notes

### Privacy Permissions

The app requests the following permissions:

-   Microphone: For speech practice features
-   Speech Recognition: For pronunciation checking
-   User Tracking: For analytics (optional)

### Network Security

-   App Transport Security (ATS) is enabled
-   Only HTTPS connections allowed by default
-   Add exceptions for specific domains if needed

### Background Modes

-   Audio background mode enabled for TTS functionality

### App Store Guidelines

Ensure compliance with:

-   App Store Review Guidelines
-   Privacy requirements
-   Educational app best practices

## Troubleshooting

### Common Issues

1. **Signing Issues**: Verify certificates and provisioning profiles
2. **Missing Permissions**: Add required usage descriptions
3. **Build Errors**: Check iOS deployment target compatibility

### Build Commands

```bash
# Clean build
flutter clean
cd ios && rm -rf Pods/ Podfile.lock && cd ..
flutter pub get
cd ios && pod install && cd ..

# Build for release
flutter build ios --release --no-codesign
```
