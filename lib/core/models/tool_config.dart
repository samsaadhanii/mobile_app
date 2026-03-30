enum ToolCategory { analysis, generation, reference }

enum ToolInputType { text, picker, both }

enum ToolOutputType { table, list, webview, text }

class ToolParam {
  final String key;
  final String label;
  final List<String> options; // empty if it's a text input
  final bool isRequired;

  const ToolParam({
    required this.key,
    required this.label,
    this.options = const [],
    this.isRequired = true,
  });

  bool get isPicker => options.isNotEmpty;
}

class ToolConfig {
  final String id;
  final String nameEn;
  final String nameSa;
  final String description;
  final ToolCategory category;
  final List<ToolParam> params;
  final ToolOutputType outputType;
  final String? apiEndpoint; // null if tool uses webview
  final String? webviewUrl; // null if tool uses API

  const ToolConfig({
    required this.id,
    required this.nameEn,
    required this.nameSa,
    required this.description,
    required this.category,
    required this.params,
    required this.outputType,
    this.apiEndpoint,
    this.webviewUrl,
  });

  bool get isWebview => webviewUrl != null;
}
