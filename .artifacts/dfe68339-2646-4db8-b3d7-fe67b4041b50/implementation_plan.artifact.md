# Implementation Plan - Push Notifications with Supabase and FCM

This plan outlines the steps to properly implement push notifications in the "No More Breakups" app using Firebase Cloud Messaging (FCM) and Supabase.

## User Review Required

> [!IMPORTANT]
> **Firebase Setup**: Ensure you have added the `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to your project if you haven't already.
> **Supabase Table**: You must create the `fcm_tokens` table in your Supabase database for this logic to work.

## Proposed Changes

### Core Services

#### [NEW] [notification_service.dart](file:///E:/NoMoreBreakups/lib/core/services/notification_service.dart)
Implement the `NotificationService` class to handle:
- Firebase initialization and permission requests.
- FCM token generation and storage in Supabase.
- Handling of foreground and background notifications.
- Local notification display for foreground messages.

### App Entry Point

#### [MODIFY] [main.dart](file:///E:/NoMoreBreakups/lib/main.dart)
- Initialize Firebase.
- Call `NotificationService.initialize()`.

## Verification Plan

### Manual Verification
1. Launch the app and verify that notification permissions are requested.
2. Check the Supabase `fcm_tokens` table to ensure the device token is saved.
3. Trigger a test notification (via Firebase Console or Supabase Edge Function) and verify it appears in the foreground/background.
