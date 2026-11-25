import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Sarath Oruganti's Gītā study page (D6). One address, held here and nowhere
/// else; the WebView follows no link that leaves this site.
const gitaPageUrl = 'https://1amongus.github.io/BG-1/';
const gitaPageHost = '1amongus.github.io';

/// The credit line, on the Tools card and under the screen's title.
const gitaPageCredit = 'Page by Sarath Oruganti';

/// Whether the WebView may go to [url]: the page's own site, and the blank
/// pages a browser opens internally. Anything else is not followed.
bool gitaPageAllows(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  if (uri.scheme == 'about' || uri.scheme == 'data') return true;
  return uri.scheme == 'https' && uri.host == gitaPageHost;
}

/// What the screen hears from the page view.
class GitaPageEvents {
  const GitaPageEvents({
    required this.onStarted,
    required this.onFinished,
    required this.onFailed,
    required this.onHistory,
  });

  final VoidCallback onStarted;
  final VoidCallback onFinished;
  final VoidCallback onFailed;

  /// Called after each page with whether the page's own history can go back.
  final ValueChanged<bool> onHistory;
}

/// The page view behind the screen, so a test can stand in for the WebView
/// (it cannot run in widget tests).
abstract class GitaPageView {
  Widget build(BuildContext context);
  Future<bool> goBack();
  Future<void> reload();
}

typedef GitaPageViewFactory = GitaPageView Function(GitaPageEvents events);

/// The real WebView. JavaScript is on, as the page needs it. The page's own
/// storage (local storage, IndexedDB, cookies) is left at each platform's
/// default, which keeps it between launches: nothing here clears it and no
/// private or incognito mode is asked for.
class _WebViewGitaPageView implements GitaPageView {
  _WebViewGitaPageView(GitaPageEvents events) {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) => gitaPageAllows(request.url)
            ? NavigationDecision.navigate
            : NavigationDecision.prevent,
        onPageStarted: (_) => events.onStarted(),
        onPageFinished: (_) async {
          events.onFinished();
          events.onHistory(await _controller.canGoBack());
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame ?? true) events.onFailed();
        },
      ))
      ..loadRequest(Uri.parse(gitaPageUrl));
  }

  late final WebViewController _controller;

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);

  @override
  Future<bool> goBack() async {
    if (!await _controller.canGoBack()) return false;
    await _controller.goBack();
    return true;
  }

  @override
  Future<void> reload() => _controller.loadRequest(Uri.parse(gitaPageUrl));
}

GitaPageView _realView(GitaPageEvents events) => _WebViewGitaPageView(events);

/// The Bhagavad Gītā card's screen (D6): the page in a WebView, a progress bar
/// while it loads, and a message with Retry when it cannot be reached. Back
/// goes back in the page's history first, then leaves the screen.
class GitaPageScreen extends StatefulWidget {
  const GitaPageScreen({super.key, this.viewFactory = _realView});

  final GitaPageViewFactory viewFactory;

  @override
  State<GitaPageScreen> createState() => _GitaPageScreenState();
}

class _GitaPageScreenState extends State<GitaPageScreen> {
  late GitaPageView _view;
  bool _loading = true;
  bool _failed = false;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _view = widget.viewFactory(GitaPageEvents(
      onStarted: () => _set(() {
        _loading = true;
        _failed = false;
      }),
      onFinished: () => _set(() => _loading = false),
      onFailed: () => _set(() {
        _loading = false;
        _failed = true;
      }),
      onHistory: (can) => _set(() => _canGoBack = can),
    ));
  }

  void _set(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    await _view.reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      // Leaving is allowed only when the page has no history to go back in.
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final went = await _view.goBack();
        if (!went) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bhagavad Gītā'),
              Text(gitaPageCredit, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(child: _view.build(context)),
            if (_failed)
              Positioned.fill(
                child: ColoredBox(
                  color: theme.colorScheme.surface,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'The page could not be loaded. Check your '
                            'connection and try again.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                              onPressed: _retry, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_loading && !_failed)
              const Positioned(
                  top: 0, left: 0, right: 0, child: LinearProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
