// lib/widgets/location_search.dart

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/weather_provider.dart';

class LocationSearchSheet extends StatefulWidget {
  const LocationSearchSheet({super.key});

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  final _controller = TextEditingController();
  final _focusNode  = FocusNode();

  static bool get _locationSupported => kIsWeb || !Platform.isLinux;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _locate(BuildContext context) {
    // Capture provider reference before pop — context becomes invalid after dismiss
    final provider = context.read<WeatherProvider>();
    // Capture ScaffoldMessenger before pop
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    Navigator.pop(context);
    provider.detectCurrentLocation().then((_) {
      final err = provider.locationError;
      if (err != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: errorColor,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Search bar row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SearchBar(
                        controller: _controller,
                        focusNode: _focusNode,
                        hintText: 'Поиск города или региона...',
                        leading: const Icon(Icons.search_rounded),
                        trailing: [
                          if (_controller.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _controller.clear();
                                context.read<WeatherProvider>().clearSearch();
                                setState(() {});
                              },
                            ),
                        ],
                        onChanged: (v) {
                          setState(() {});
                          context.read<WeatherProvider>().searchLocations(v);
                        },
                        elevation: const WidgetStatePropertyAll(0),
                        backgroundColor: WidgetStatePropertyAll(
                          theme.colorScheme.surfaceContainerHighest),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        context.read<WeatherProvider>().clearSearch();
                        Navigator.pop(context);
                      },
                      child: const Text('Отмена'),
                    ),
                  ],
                ),
              ),

              // GPS button (only when search is empty, platform supports it)
              if (_locationSupported && _controller.text.isEmpty)
                Consumer<WeatherProvider>(
                  builder: (_, provider, __) => ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: provider.isLocating
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : Icon(Icons.my_location_rounded,
                              color: theme.colorScheme.primary, size: 20),
                    ),
                    title: Text(
                      provider.isLocating
                          ? 'Определяю местоположение…'
                          : 'Моё местоположение',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'По GPS / сети',
                      style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                    onTap: provider.isLocating ? null : () => _locate(context),
                  ),
                ),

              const Divider(height: 1),

              // Results
              Expanded(
                child: Consumer<WeatherProvider>(
                  builder: (context, provider, _) {
                    if (provider.isSearching) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (_controller.text.isNotEmpty &&
                        provider.searchResults.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            Text('Город не найден',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(
                              'Попробуйте ввести название иначе',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (_controller.text.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.public_rounded, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text('Введите название города',
                                style: theme.textTheme.titleMedium),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: provider.searchResults.length,
                      itemBuilder: (context, index) {
                        final loc = provider.searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(Icons.place_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                          ),
                          title: Text(loc.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text([
                            if (loc.admin1 != null &&
                                loc.admin1!.isNotEmpty &&
                                loc.admin1 != loc.name)
                              loc.admin1!,
                            loc.country,
                          ].join(', ')),
                          onTap: () {
                            provider.selectLocation(loc);
                            Navigator.pop(context);
                          },
                        )
;
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
