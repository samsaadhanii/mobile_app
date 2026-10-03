import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/models/tool_config.dart';
import 'package:mobile_app/core/models/tool_registry.dart';

void main() {
  group('ToolRegistry', () {
    test('has 7 tools with unique ids', () {
      final ids = ToolRegistry.tools.map((t) => t.id).toList();
      expect(ids.length, 7);
      expect(ids.toSet().length, ids.length);
    });

    test('every tool has exactly one of apiEndpoint and webviewUrl', () {
      for (final tool in ToolRegistry.tools) {
        expect(
          (tool.apiEndpoint != null) != (tool.webviewUrl != null),
          isTrue,
          reason: '${tool.id} must have exactly one of apiEndpoint, webviewUrl',
        );
      }
    });

    test('findById returns each tool and null for an unknown id', () {
      for (final tool in ToolRegistry.tools) {
        expect(ToolRegistry.findById(tool.id), same(tool));
      }
      expect(ToolRegistry.findById('no_such_tool'), isNull);
    });

    test('byCategory lists together contain every tool once', () {
      final grouped = [
        for (final category in ToolCategory.values)
          ...ToolRegistry.byCategory(category),
      ];
      expect(grouped.length, ToolRegistry.tools.length);
      expect(grouped.toSet().length, grouped.length);
      expect(grouped.toSet(), ToolRegistry.tools.toSet());
    });
  });
}
