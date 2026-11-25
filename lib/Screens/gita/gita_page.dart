import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as mat;
import 'package:webview_flutter/webview_flutter.dart';
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

const String kGitaPageUrl = 'https://1amongus.github.io/BG-1/';
const String kGitaPageHost = '1amongus.github.io';

/// Sarath Oruganti's Gita study page, shown inside the app.
class GitaPage extends StatefulWidget {
  const GitaPage({super.key});

  @override
  State<GitaPage> createState() => _GitaPageState();
}

/// ************************************************************************
/// loading the webview for the Gita page for Android and iOS
/// ************************************************************************
class _GitaPageState extends State<GitaPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Only this page's own site is followed inside the app.
            final Uri? uri = Uri.tryParse(request.url);
            if (uri != null &&
                (uri.scheme == 'about' ||
                    uri.scheme == 'data' ||
                    (uri.scheme == 'https' && uri.host == kGitaPageHost))) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(kGitaPageUrl));

    _controller = controller;
  }

  /// The title with the credit under it, smaller. The credit takes the bar's
  /// own text colour (no colour is set), so it reads on the bar.
  Widget _title() => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Bhagavad Gītā'),
          Text('Page by Sarath Oruganti', style: TextStyle(fontSize: 12)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    if (TargetPlatform.iOS == mat.Theme.of(context).platform) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: _title(),
        ),
        child: SafeArea(child: WebViewWidget(controller: _controller)),
      );
    } else {
      return mat.Scaffold(
        appBar: mat.AppBar(
          title: _title(),
        ),
        body: SafeArea(child: WebViewWidget(controller: _controller)),
      );
    }
  }
}
