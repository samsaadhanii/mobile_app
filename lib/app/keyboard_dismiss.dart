import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A tap outside a text field puts the keyboard away, on every screen
/// (BUGS.md #19). An iPhone has no back button to do it. It sits above the
/// navigator, so no screen needs its own copy, and it only listens to raw
/// pointer events: it takes no part in the gesture arena, so a button or a
/// row under the tap still does what it does.
///
/// A tap on the focused field, or on its selection handles and toolbar (they
/// share the field's `TextFieldTapRegion` group), leaves the focus alone.
class KeyboardDismiss extends StatefulWidget {
  const KeyboardDismiss({super.key, required this.child});

  final Widget child;

  @override
  State<KeyboardDismiss> createState() => _KeyboardDismissState();
}

class _KeyboardDismissState extends State<KeyboardDismiss> {
  int? _pointer;
  Offset _down = Offset.zero;

  bool _onTextField(PointerEvent e) {
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, e.position, e.viewId);
    return result.path.any((entry) {
      final target = entry.target;
      return target is RenderTapRegion && target.groupId == EditableText;
    });
  }

  void _onUp(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    // A drag is a scroll, not a tap; scrolling pages close the keyboard
    // themselves (keyboardDismissBehavior).
    if ((e.position - _down).distance > kTouchSlop) return;
    final focus = FocusManager.instance.primaryFocus;
    if (focus?.context?.findAncestorStateOfType<EditableTextState>() == null) {
      return;
    }
    if (_onTextField(e)) return;
    focus!.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _pointer = e.pointer;
        _down = e.position;
      },
      onPointerUp: _onUp,
      onPointerCancel: (_) => _pointer = null,
      child: widget.child,
    );
  }
}
