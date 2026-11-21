import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/location_data.dart';
import '../services/location_service.dart';

class LocationPickerField extends StatefulWidget {
  const LocationPickerField({
    super.key,
    required this.controller,
    required this.onSelected,
    this.errorText,
    this.label = 'LOCATION / AREA',
    this.hint = 'Search area, city or district in Bangladesh',
    this.initialLocation,
  });

  final TextEditingController controller;
  final ValueChanged<LocationData> onSelected;
  final String? errorText;
  final String label;
  final String hint;
  final LocationData? initialLocation;

  @override
  State<LocationPickerField> createState() => _LocationPickerFieldState();
}

class _LocationPickerFieldState extends State<LocationPickerField> {
  Future<void> _openPicker() async {
    final selected = await showDialog<LocationData>(
      context: context,
      builder: (_) => const _LocationSearchDialog(),
    );
    if (selected == null || !mounted) return;
    widget.controller.text = selected.formattedAddress;
    widget.onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.controller.text.trim().isNotEmpty;
    final hasCoordinates = widget.initialLocation?.hasValidCoordinates ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(widget.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              )),
          const SizedBox(height: 8),
        ],
        InkWell(
          onTap: _openPicker,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: widget.hint,
              errorText: widget.errorText,
              prefixIcon: const Icon(LucideIcons.mapPin),
              suffixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
            ),
            child: Text(
              hasValue ? widget.controller.text : widget.hint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasValue ? Theme.of(context).colorScheme.onSurface : Colors.grey.shade600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Icon(
              hasCoordinates ? Icons.check_circle_outline : Icons.info_outline,
              size: 13,
              color: hasCoordinates ? Colors.green : Colors.grey.shade600,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                hasCoordinates
                    ? 'Location coordinates saved'
                    : (hasValue
                        ? 'Existing text location; select a search result to enable distance matching'
                        : 'Select a search result to save exact coordinates'),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LocationSearchDialog extends StatefulWidget {
  const _LocationSearchDialog();

  @override
  State<_LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<_LocationSearchDialog> {
  final TextEditingController _queryController = TextEditingController();
  final LocationService _locationService = LocationService();
  List<LocationData> _results = [];
  bool _isSearching = false;
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _error = null;
      _searched = true;
    });
    try {
      final results = await _locationService.searchBangladesh(_queryController.text);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select your location'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _queryController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'e.g. Dhanmondi, Dhaka',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _isSearching ? null : _search,
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Search by area, city or district only. Do not enter house numbers or private addresses.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            if (_isSearching) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (!_isSearching && _searched && _results.isEmpty && _error == null)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No results found. Try another area or district.'),
              ),
            if (_results.isNotEmpty)
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final location = _results[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(LucideIcons.mapPin),
                      title: Text(location.formattedAddress, maxLines: 3, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}'),
                      onTap: () => Navigator.pop(context, location),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Search data © OpenStreetMap contributors',
              style: TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSearching ? null : _search,
          child: const Text('Search'),
        ),
      ],
    );
  }
}
