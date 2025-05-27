class ImageUtils {
  static String convertToWebp(String imageUrl) {
    if (imageUrl.isEmpty) return imageUrl;

    // Handle different image extensions
    final lowerUrl = imageUrl.toLowerCase();
    if (lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg')) {
      // Get the base URL without extension
      final lastDotIndex = imageUrl.lastIndexOf('.');
      if (lastDotIndex != -1) {
        // Ensure we're not already a webp
        if (!imageUrl.toLowerCase().endsWith('.webp')) {
          return '${imageUrl.substring(0, lastDotIndex)}.webp';
        }
      }
    }

    return imageUrl;
  }

  static String getImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';

    // Always convert to webp regardless of URL format
    return convertToWebp(imagePath);
  }

  // Helper method to check if URL is already webp
  static bool isWebp(String url) {
    return url.toLowerCase().endsWith('.webp');
  }
}
