import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shared search input. Selecting a suggestion immediately updates the
/// controller and calls onChanged so each screen's existing filter is applied.
class SearchSuggestionField extends StatefulWidget {
  const SearchSuggestionField({
    super.key,
    required this.controller,
    required this.options,
    required this.onChanged,
    required this.hintText,
    this.focusNode,
    this.decoration,
    this.textStyle,
    this.maxSuggestions = 7,
  });

  final TextEditingController controller;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String hintText;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextStyle? textStyle;
  final int maxSuggestions;

  static List<String> collectOptions(Iterable<dynamic> values) {
    final result = <String>[];
    final seen = <String>{};

    void add(dynamic value) {
      if (value == null) return;
      if (value is Iterable && value is! String) {
        for (final item in value) {
          add(item);
        }
        return;
      }
      if (value is Map) {
        for (final item in value.values) {
          add(item);
        }
        return;
      }
      final text = value.toString().trim();
      if (text.isEmpty) return;
      if (seen.add(text.toLowerCase())) result.add(text);
    }

    for (final value in values) {
      add(value);
    }
    return result;
  }

  @override
  State<SearchSuggestionField> createState() =>
      _SearchSuggestionFieldState();
}

class _SearchSuggestionFieldState extends State<SearchSuggestionField> {
  final LayerLink _link = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  final FocusNode _internalFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;

  List<String> get _matches {
    final query = widget.controller.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    final result = <String>[];
    final seen = <String>{};
    for (final option in widget.options) {
      final value = option.trim();
      final lower = value.toLowerCase();
      if (value.isEmpty || lower == query || !lower.contains(query)) continue;
      if (seen.add(lower)) {
        result.add(value);
        if (result.length >= widget.maxSuggestions) break;
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refreshOverlay);
    _focusNode.addListener(_refreshOverlay);
  }

  @override
  void didUpdateWidget(covariant SearchSuggestionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refreshOverlay);
      widget.controller.addListener(_refreshOverlay);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_refreshOverlay);
      if (oldWidget.focusNode == null) {
        _internalFocusNode.removeListener(_refreshOverlay);
      }
      _focusNode.addListener(_refreshOverlay);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshOverlay());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refreshOverlay);
    _focusNode.removeListener(_refreshOverlay);
    _removeOverlay();
    _internalFocusNode.dispose();
    super.dispose();
  }

  void _refreshOverlay() {
    if (!mounted) return;
    if (!_focusNode.hasFocus || widget.controller.text.trim().isEmpty) {
      _removeOverlay();
      return;
    }
    if (_overlayEntry == null) {
      _overlayEntry = _buildOverlay();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  OverlayEntry _buildOverlay() {
    return OverlayEntry(
      builder: (context) {
        final renderObject = _fieldKey.currentContext?.findRenderObject();
        final width = renderObject is RenderBox
            ? renderObject.size.width
            : MediaQuery.sizeOf(context).width - 40;
        final options = _matches;

        return Positioned(
          width: width,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: const Offset(0, 54),
            child: Material(
              color: Colors.white,
              elevation: 9,
              shadowColor: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              child: options.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          Icon(LucideIcons.search, size: 16, color: Color(0xFF929AAA)),
                          SizedBox(width: 10),
                          Text('No suggestions found', style: TextStyle(
                            fontSize: 12, color: Color(0xFF929AAA))),
                        ],
                      ),
                    )
                  : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, index) => const Divider(
                    height: 1,
                    indent: 42,
                    color: Color(0xFFE9EBEF),
                  ),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    return InkWell(
                      onTap: () => _select(option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.search, size: 16,
                                color: Color(0xFF929AAA)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                option,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF202938),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _select(String value) {
    widget.controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    widget.onChanged(value);
    _removeOverlay();
    _focusNode.unfocus();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final decoration = widget.decoration ?? InputDecoration(
      hintText: widget.hintText,
      prefixIcon: const Icon(LucideIcons.search, size: 18),
      suffixIcon: widget.controller.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Clear search',
              onPressed: () {
                widget.controller.clear();
                widget.onChanged('');
                _focusNode.requestFocus();
              },
              icon: const Icon(LucideIcons.x, size: 17),
            ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFB89A58), width: 1.3),
      ),
    );

    return CompositedTransformTarget(
      link: _link,
      child: SizedBox(
        key: _fieldKey,
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          onSubmitted: (_) => _removeOverlay(),
          textInputAction: TextInputAction.search,
          style: widget.textStyle ??
              const TextStyle(fontSize: 13, color: Color(0xFF202938)),
          decoration: decoration,
        ),
      ),
    );
  }
}
