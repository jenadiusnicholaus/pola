// iOS Image Picker Configuration
// 
// Add these settings to ios/Runner/Info.plist for better image picker support:
/*

<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to let you select images for your posts.</string>

<key>NSCameraUsageDescription</key>  
<string>This app needs access to camera to let you take photos for your posts.</string>

<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to microphone when recording videos.</string>

<!-- For iOS 14+ Photo Library limited access -->
<key>PHPhotoLibraryPreventAutomaticLimitedAccessAlert</key>
<true/>

<!-- Supported image formats -->
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Images</string>
        <key>LSHandlerRank</key>
        <string>Alternate</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>public.image</string>
            <string>public.jpeg</string>
            <string>public.png</string>
        </array>
    </dict>
</array>

*/

// Additionally, you may want to add these settings to improve compatibility:
/*

<!-- Prevent iOS from converting HEIC to JPEG automatically -->
<key>PHPickerConfigurationPreferredAssetRepresentationMode</key>
<string>current</string>

<!-- Allow access to all photos -->
<key>PHPhotoLibraryPreventAutomaticLimitedAccessAlert</key>
<false/>

*/