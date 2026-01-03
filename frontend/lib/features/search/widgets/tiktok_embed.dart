// ============================================
// For Android, you MUST set minSdkVersion to 19 or higher
// in android/app/build.gradle for WebView to work.
// ============================================

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TikTokEmbed extends StatefulWidget {
  final String videoUrl;

  const TikTokEmbed({super.key, required this.videoUrl});

  @override
  State<TikTokEmbed> createState() => _TikTokEmbedState();
}

class _TikTokEmbedState extends State<TikTokEmbed> {
  late WebViewController _controller;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    _extractVideoId();
    if (_videoId != null) {
      _initWebView();
    }
  }

  void _extractVideoId() {
    final regex = RegExp(r'/video/(\d+)');
    final match = regex.firstMatch(widget.videoUrl);
    if (match != null) {
      _videoId = match.group(1);
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadHtmlString(_buildHtml());
  }

  String _buildHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { 
      background-color: #000; 
      display: flex; 
      justify-content: center; 
      align-items: flex-start;
      min-height: 100vh;
      overflow-x: hidden;
    }
    .tiktok-embed {
      max-width: 325px !important;
      min-width: 300px !important;
    }
  </style>
</head>
<body>
  <blockquote class="tiktok-embed" cite="${widget.videoUrl}" data-video-id="$_videoId" style="max-width: 325px; min-width: 300px;">
    <section></section>
  </blockquote>
  <script async src="https://www.tiktok.com/embed.js"></script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    if (_videoId == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 340,
      height: 500,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: WebViewWidget(controller: _controller),
    );
  }
}

