import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/location/address_autocomplete.dart';
import '../../core/utils/validators.dart';

/// A text field with debounced Cameroon-address autocomplete. Typing ≥3 chars
/// queries the geocoder (via [AddressAutocomplete]) and shows suggestions
/// inline below the field; picking one fills the field and notifies via
/// [onSelected] so the form can also set the region.
class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final ValueChanged<AddressSuggestion>? onSelected;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.onSelected,
  });

  @override
  State<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  Timer? _debounce;
  List<AddressSuggestion> _suggestions = const [];
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    final q = text.trim();
    if (q.length < 3) {
      setState(() {
        _suggestions = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      List<AddressSuggestion> results;
      try {
        results = await AddressAutocomplete.search(q);
      } catch (_) {
        // Offline, rate-limited or geocoder error → no suggestions; the rest
        // of the form keeps working (manual entry is always available).
        results = const [];
      }
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loading = false;
      });
    });
  }

  void _select(AddressSuggestion suggestion) {
    widget.controller.text = suggestion.displayName;
    setState(() => _suggestions = const []);
    widget.onSelected?.call(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
          onChanged: _onChanged,
          validator: (v) => validateRequired(v, widget.label),
        ),
        if (_loading || _suggestions.isNotEmpty)
          Card(
            elevation: 3,
            margin: const EdgeInsets.only(top: 4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      // A Column (not a shrink-wrap ListView) so the dialog's
                      // intrinsic-width sizing never trips over a scrollable.
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final s in _suggestions)
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.place_outlined, size: 18),
                              title: Text(
                                s.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                              onTap: () => _select(s),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}
