import 'package:flutter/material.dart';

/// Autocomplete-backed optional stock note field.
final class StockNoteAutocompleteField extends StatelessWidget {
  /// Creates a stock note field using locally supplied [suggestions].
  const StockNoteAutocompleteField({
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.suggestions,
    required this.onSubmitted,
    super.key,
  });

  /// Stable key for the rendered text field.
  final Key fieldKey;

  /// Text controller used by the owning form.
  final TextEditingController controller;

  /// Focus node used by the owning form.
  final FocusNode focusNode;

  /// Whether the field can be edited.
  final bool enabled;

  /// Same-field historical values available as suggestions.
  final List<String> suggestions;

  /// Called when the keyboard submits the field.
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      key: ValueKey<String>(suggestions.join(r'\\u0000')),
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (value) => _matchingSuggestions(value.text),
      onSelected: (selection) {
        controller.value = TextEditingValue(
          text: selection,
          selection: TextSelection.collapsed(offset: selection.length),
        );
      },
      fieldViewBuilder:
          (context, fieldController, fieldFocusNode, onFieldSubmitted) {
            return TextFormField(
              key: fieldKey,
              controller: fieldController,
              focusNode: fieldFocusNode,
              enabled: enabled,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                final hasOptions = _matchingSuggestions(
                  fieldController.text,
                ).isNotEmpty;
                if (hasOptions) {
                  onFieldSubmitted();
                } else {
                  onSubmitted();
                }
              },
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        final optionList = options.toList(growable: false);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 192, maxWidth: 360),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: optionList.length,
                itemBuilder: (context, index) {
                  final option = optionList[index];
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        option,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Iterable<String> _matchingSuggestions(String rawInput) {
    if (!enabled) return const Iterable<String>.empty();
    final input = rawInput.trim().toLowerCase();
    if (input.isEmpty) return const Iterable<String>.empty();
    return suggestions.where((suggestion) {
      return suggestion.trim().toLowerCase().startsWith(input);
    });
  }
}
