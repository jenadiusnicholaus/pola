import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/legal_education_models.dart';

class MaterialViewerScreen extends StatefulWidget {
  const MaterialViewerScreen({super.key});

  @override
  State<MaterialViewerScreen> createState() => _MaterialViewerScreenState();
}

class _MaterialViewerScreenState extends State<MaterialViewerScreen> {
  late LearningMaterial material;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();

    // Get material from arguments
    final args = Get.arguments as Map<String, dynamic>;
    material = args['material'] as LearningMaterial;

    _initializeViewer();
  }

  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }

  void _initializeViewer() {
    // Pre-validate content for better UX
    if (material.fileUrl.isNotEmpty && _isPdfFile()) {
      // For PDF files, validate URL format
      if (!_isValidPdfUrl(material.fileUrl)) {
        setState(() {
          hasError = true;
          errorMessage = 'Invalid PDF file URL format';
          isLoading = false;
        });
        return;
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  bool get _isPaidMaterial {
    final priceValue = double.tryParse(material.price) ?? 0.0;
    return priceValue > 0.0;
  }

  Widget _buildSocialSidePanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      // Fully transparent background like social media
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Like button
          _buildSideAction(
            theme,
            Icons.favorite_outline,
            Icons.favorite,
            false, // TODO: Connect to actual like state
            '0', // TODO: Connect to actual like count
            () {
              // TODO: Implement like functionality
              Get.snackbar(
                'Coming Soon',
                'Like feature will be available soon',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          const SizedBox(height: 16),
          // Download action
          _buildSideAction(
            theme,
            Icons.download_outlined,
            Icons.download,
            false,
            '${material.downloadsCount}',
            () {
              // TODO: Implement download functionality
              Get.snackbar(
                'Download',
                'Download feature will be available soon',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          if (material.isVerified) ...[
            const SizedBox(height: 16),
            // Verified badge
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified,
                size: 18,
                color: Colors.blue,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSideAction(
    ThemeData theme,
    IconData outlineIcon,
    IconData filledIcon,
    bool isActive,
    String count,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // Semi-transparent background like social media
                color: isActive
                    ? theme.colorScheme.primary.withOpacity(0.2)
                    : Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? filledIcon : outlineIcon,
                size: 22,
                color: isActive ? theme.colorScheme.primary : Colors.white,
              ),
            ),
            if (count.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Professional Sliver App Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
            scrolledUnderElevation: 2,
            shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                material.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      color: theme.colorScheme.surface.withOpacity(0.8),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              titlePadding:
                  const EdgeInsets.only(left: 16, bottom: 20, right: 16),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.surface,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        // Clean space - no overlapping content
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content Viewer as Sliver
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              height: MediaQuery.of(context).size.height -
                  300, // Fixed height to avoid intrinsic issues
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.04),
                    blurRadius: 40,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Content indicator bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Main content with social media style side actions
                  Expanded(
                    child: Stack(
                      children: [
                        // Main content area - FULL WIDTH, no padding
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          child: _buildContentViewer(theme),
                        ),
                        // Social media style actions - floating at bottom right like TikTok/Instagram
                        Positioned(
                          right: 12,
                          bottom: 20, // Position at bottom like social media
                          child: _buildSocialSidePanel(theme),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentViewer(ThemeData theme) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading content...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we prepare your material',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (hasError) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load Content',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.error.withOpacity(0.2),
                ),
              ),
              child: Text(
                errorMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _retryLoading(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Prioritize content based on availability: PDF first, then description
    try {
      // 1. If file is available and is PDF, show PDF viewer
      if (material.fileUrl.isNotEmpty && _isPdfFile()) {
        return _buildPdfViewer();
      }
      // 2. For any other file type or web content, show description instead
      else if (material.description.isNotEmpty) {
        return _buildRichTextViewer();
      }
      // 3. If content_type indicates rich text/article, show description
      else if (_isRichTextContent() && material.description.isNotEmpty) {
        return _buildRichTextViewer();
      }
      // 4. No content available
      else {
        return _buildNoContentMessage(material.fileUrl.isEmpty
            ? 'No content available for this material'
            : 'Only PDF files can be viewed in the app. Please use the description below or open in browser.');
      }
    } catch (e) {
      // Fallback to text content if anything fails
      if (material.description.isNotEmpty) {
        return _buildTextContent();
      } else {
        return _buildNoContentMessage('Error loading content: ${e.toString()}');
      }
    }
  }

  Widget _buildPdfViewer() {
    if (material.fileUrl.isEmpty) {
      return _buildNoContentMessage('No PDF file available');
    }

    // Validate PDF URL before attempting to load
    if (!_isValidPdfUrl(material.fileUrl)) {
      return _buildNoContentMessage('Invalid PDF file URL');
    }

    final isPaid = _isPaidMaterial;

    // Create PDF viewer
    final pdfViewer = PDF().cachedFromUrl(
      material.fileUrl,
      placeholder: (progress) => Container(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  value: progress,
                  backgroundColor:
                      Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading PDF...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toInt()}% complete',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      material.title.length > 30
                          ? '${material.title.substring(0, 30)}...'
                          : material.title,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      errorWidget: (error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            hasError = true;
            errorMessage = 'PDF loading failed: ${error.toString()}';
          });
        });
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      size: 48,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'PDF Loading Failed',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to load the PDF file. This might be due to network issues or the file format.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.8),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _retryLoading(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _openInBrowser(),
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('Open in Browser'),
                      ),
                    ],
                  ),
                  if (material.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          // Force show description as fallback
                        });
                      },
                      icon: const Icon(Icons.description),
                      label: const Text('View Description Instead'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );

    // Create the container for the PDF
    Widget pdfWidget = Container(
      color: Theme.of(context).colorScheme.surface,
      child: pdfViewer,
    );

    // For paid materials, apply Medium-style paywall with gradient fade
    if (isPaid) {
      final screenHeight = MediaQuery.of(context).size.height;
      final previewHeight = screenHeight * 0.7; // Show 70% of screen

      return Stack(
        children: [
          // Constrained PDF content with scroll disabled
          ClipRect(
            child: SizedBox(
              height: previewHeight,
              child: AbsorbPointer(
                absorbing: true, // Disable all interactions
                child: pdfWidget,
              ),
            ),
          ),
          // Medium-style gradient fade overlay
          Positioned(
            top: previewHeight * 0.5, // Start fade at 50% of preview
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    Theme.of(context).colorScheme.surface,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ),
          // Paywall overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildPaywallOverlay(Theme.of(context)),
          ),
        ],
      );
    }

    // Free materials show full content
    return pdfWidget;
  }

  Widget _buildRichTextViewer() {
    final theme = Theme.of(context);
    final isPaid = _isPaidMaterial;

    // For paid materials, show more content for proper preview (like Medium)
    final contentToShow = isPaid && material.description.isNotEmpty
        ? material.description // Show full content, will be faded with gradient
        : material.description;

    Widget contentWidget = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contentToShow.isNotEmpty) ...[
            Html(
              data: contentToShow,
              style: {
                "body": Style(
                  fontSize: FontSize(16),
                  lineHeight: const LineHeight(1.6),
                  color: theme.colorScheme.onSurface,
                  fontFamily: theme.textTheme.bodyLarge?.fontFamily,
                ),
                "p": Style(
                  margin: Margins.only(bottom: 16),
                  fontSize: FontSize(16),
                  lineHeight: const LineHeight(1.6),
                  color: theme.colorScheme.onSurface,
                ),
                "h1, h2, h3, h4, h5, h6": Style(
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 24, bottom: 12),
                  color: theme.colorScheme.onSurface,
                  fontFamily: theme.textTheme.headlineMedium?.fontFamily,
                ),
                "h1": Style(fontSize: FontSize(24)),
                "h2": Style(fontSize: FontSize(20)),
                "h3": Style(fontSize: FontSize(18)),
                "li": Style(
                  margin: Margins.only(bottom: 8),
                  fontSize: FontSize(16),
                  lineHeight: const LineHeight(1.6),
                  color: theme.colorScheme.onSurface,
                ),
                "ul, ol": Style(
                  margin: Margins.only(bottom: 16),
                ),
                "blockquote": Style(
                  margin: Margins.only(left: 16, bottom: 16),
                  padding: HtmlPaddings.all(12),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 4,
                    ),
                  ),
                ),
              },
              onLinkTap: (url, _, __) {
                if (url != null) {
                  _launchUrl(url);
                }
              },
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.description,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No content available for this material',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    // For paid materials, apply Medium-style paywall with gradient fade
    if (isPaid && material.description.isNotEmpty) {
      final previewHeight = 400.0; // Height for preview content

      return Stack(
        children: [
          // Constrained content with scroll disabled
          ClipRect(
            child: SizedBox(
              height: previewHeight,
              child: AbsorbPointer(
                absorbing: true, // Disable all interactions
                child: contentWidget,
              ),
            ),
          ),
          // Medium-style gradient fade overlay
          Positioned(
            top: previewHeight * 0.6, // Start fade at 60% of preview
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    theme.colorScheme.surface.withOpacity(0.8),
                    theme.colorScheme.surface,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          // Paywall overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildPaywallOverlay(theme),
          ),
        ],
      );
    }

    // Free materials show full content
    return contentWidget;
  }

  Widget _buildTextContent() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Text(
              material.description.isNotEmpty
                  ? material.description
                  : 'No content available for this material.',
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.7,
                fontSize: 16,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoContentMessage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _isPdfFile() {
    if (material.fileUrl.isEmpty) return false;

    final contentType = material.contentType.toLowerCase();
    final fileUrl = material.fileUrl.toLowerCase();

    return contentType == 'pdf' ||
        contentType == 'document' ||
        fileUrl.contains('.pdf') ||
        fileUrl.contains('pdf');
  }

  bool _isRichTextContent() {
    final contentType = material.contentType.toLowerCase();
    return contentType == 'article' ||
        contentType == 'rich_text' ||
        contentType == 'notes' ||
        contentType == 'research' ||
        (material.description.contains('<') &&
            material.description.contains('>'));
  }

  bool _isValidPdfUrl(String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return false;

      // Check if it's a valid HTTP/HTTPS URL
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) return false;

      // Check if it's likely a PDF file
      final lowerUrl = url.toLowerCase();
      if (lowerUrl.contains('.pdf') || lowerUrl.contains('pdf')) {
        return true;
      }

      // For document content type, assume it might be PDF
      if (material.contentType.toLowerCase() == 'document') {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  void _openInBrowser() {
    if (material.fileUrl.isNotEmpty) {
      _launchUrl(material.fileUrl);
    }
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'Error',
        'Could not open link',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _buildPaywallOverlay(ThemeData theme) {
    final price = double.tryParse(material.price) ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lock,
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Content',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Continue reading with full access',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TSH ${price.toStringAsFixed(0)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'One-time purchase',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement purchase flow
                  Get.snackbar(
                    'Purchase',
                    'Purchase functionality will be available soon',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Purchase'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _retryLoading() {
    setState(() {
      hasError = false;
      isLoading = true;
      errorMessage = '';
    });
    _initializeViewer();
  }
}
