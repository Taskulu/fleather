import 'dart:async';

import 'package:fleather/src/rendering/editor.dart';
import 'package:fleather/src/widgets/controller.dart';
import 'package:flutter/material.dart';

class MentionSuggestionOverlay {
  final BuildContext context;
  final RenderEditor renderObject;
  final Widget debugRequiredFor;
  final Future<Map<String, String>> suggestions;
  final String query, trigger;
  final TextEditingValue textEditingValue;
  final Function(String, String)? suggestionSelected;
  final MentionSuggestionItemBuilder itemBuilder;
  OverlayEntry? overlayEntry;

  MentionSuggestionOverlay({
    required this.textEditingValue,
    required this.context,
    required this.renderObject,
    required this.debugRequiredFor,
    required this.suggestions,
    required this.itemBuilder,
    required this.query,
    required this.trigger,
    this.suggestionSelected,
  });

  void show() {
    overlayEntry = OverlayEntry(
        builder: (context) => FutureBuilder<Map<String, String>>(
              future: suggestions,
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data == null) {
                  return const SizedBox();
                }
                return _MentionSuggestionList(
                  renderObject: renderObject,
                  suggestions: data,
                  textEditingValue: textEditingValue,
                  suggestionSelected: suggestionSelected,
                  itemBuilder: itemBuilder,
                  query: query,
                  trigger: trigger,
                );
              },
            ));
    Overlay.of(context, rootOverlay: true, debugRequiredFor: debugRequiredFor)
        ?.insert(overlayEntry!);
  }

  void hide() {
    overlayEntry?.remove();
  }

  void dispose() {
    hide();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      overlayEntry?.dispose();
      overlayEntry = null;
    });
  }

  void updateForScroll() {
    overlayEntry?.markNeedsBuild();
  }
}

const double listMaxHeight = 200;

class _MentionSuggestionList extends StatelessWidget {
  final RenderEditor renderObject;
  final Map<String, String> suggestions;
  final String query, trigger;
  final TextEditingValue textEditingValue;
  final Function(String, String)? suggestionSelected;
  final MentionSuggestionItemBuilder itemBuilder;

  const _MentionSuggestionList({
    Key? key,
    required this.renderObject,
    required this.suggestions,
    required this.textEditingValue,
    required this.itemBuilder,
    required this.query,
    required this.trigger,
    this.suggestionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final endpoints =
        renderObject.getEndpointsForSelection(textEditingValue.selection);
    final editingRegion = Rect.fromPoints(
      renderObject.localToGlobal(Offset.zero),
      renderObject.localToGlobal(renderObject.size.bottomRight(Offset.zero)),
    );
    final baseLineHeight =
        renderObject.preferredLineHeight(textEditingValue.selection.base);
    final listMaxWidth = editingRegion.width / 2;
    final mediaQueryData = MediaQuery.of(context);
    final screenHeight = mediaQueryData.size.height;

    double? positionFromTop = endpoints[0].point.dy + editingRegion.top;
    double? positionFromBottom;

    if (positionFromTop + listMaxHeight >
        screenHeight - mediaQueryData.viewInsets.bottom) {
      positionFromTop = null;
      positionFromBottom = screenHeight - editingRegion.bottom + baseLineHeight;
    }

    return Positioned(
      top: positionFromTop,
      bottom: positionFromBottom,
      right: 16,
      left: 16,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: listMaxWidth, maxHeight: listMaxHeight),
        child: _buildOverlayWidget(context),
      ),
    );
  }

  Widget _buildOverlayWidget(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: suggestions.keys
                .map((id) =>
                    _buildListItem(context, id, trigger, suggestions[id]!))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(
      BuildContext context, String id, String trigger, String text) {
    return InkWell(
      onTap: () => suggestionSelected?.call(id, text),
      child: itemBuilder(context, id, trigger, query),
    );
  }
}
