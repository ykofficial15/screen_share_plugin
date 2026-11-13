import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screen_share_plugin/screen_share_plugin.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screen Share Plugin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.dark,
          useMaterial3: true),
      home: const ScreenShareDemo(),
    );
  }
}

class ScreenShareDemo extends StatefulWidget {
  const ScreenShareDemo({super.key});

  @override
  State<ScreenShareDemo> createState() => _ScreenShareDemoState();
}

class _ScreenShareDemoState extends State<ScreenShareDemo> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  bool _rendererReady = false;
  bool _busy = false;
  bool _captureAudio = false;
  String _status = 'Idle';

  String get _platformName {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }

  @override
  void initState() {
    super.initState();
    _renderer.initialize().then((_) {
      if (mounted) setState(() => _rendererReady = true);
    });
    ScreenSharePlugin.sharing.addListener(_onSharingChanged);
  }

  void _onSharingChanged() {
    if (!mounted) return;
    if (!ScreenSharePlugin.sharing.value) {
      _renderer.srcObject = null;
      setState(() => _status = 'Screen sharing stopped');
    }
  }

  Future<void> _start() async {
    DesktopCapturerSource? source;
    if (ScreenSharePlugin.supportsSourceSelection) {
      source = await _pickSource();
      if (source == null) return;
    }

    setState(() {
      _busy = true;
      _status = 'Requesting permission…';
    });
    try {
      final stream = await ScreenSharePlugin.startScreenShare(
        source: source,
        options: ScreenShareOptions(audio: _captureAudio),
      );
      _renderer.srcObject = stream;
      final hasAudio = stream.getAudioTracks().isNotEmpty;
      setState(() => _status =
          'Sharing ${source?.name ?? 'screen'}${hasAudio ? ' with audio' : ''}');
    } on ScreenShareException catch (e) {
      setState(() => _status = e.code == 'PERMISSION_DENIED'
          ? 'Permission denied'
          : 'Error: ${e.message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    setState(() => _busy = true);
    await ScreenSharePlugin.stopScreenShare();
    if (mounted) setState(() => _busy = false);
  }

  Future<DesktopCapturerSource?> _pickSource() async {
    final List<DesktopCapturerSource> sources;
    try {
      sources = await ScreenSharePlugin.getSources();
    } catch (e) {
      setState(() => _status = 'Could not list screens: $e');
      return null;
    }
    if (!mounted) return null;
    if (sources.isEmpty) {
      setState(() => _status = defaultTargetPlatform == TargetPlatform.macOS
          ? 'No screens found. Allow Screen Recording for this app in System Settings, then restart it.'
          : 'No screens or windows found.');
      return null;
    }
    return showDialog<DesktopCapturerSource>(
      context: context,
      builder: (context) => SourcePickerDialog(sources: sources),
    );
  }

  @override
  void dispose() {
    ScreenSharePlugin.sharing.removeListener(_onSharingChanged);
    ScreenSharePlugin.stopScreenShare();
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: ScreenSharePlugin.sharing,
      builder: (context, sharing, _) => Scaffold(
        appBar: AppBar(title: Text('Screen Share · $_platformName')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_status,
                    key: const Key('status'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: sharing && _rendererReady
                          ? RTCVideoView(_renderer,
                              objectFit: RTCVideoViewObjectFit
                                  .RTCVideoViewObjectFitContain)
                          : Center(
                              child: Text(
                                ScreenSharePlugin.isSupported
                                    ? 'Not sharing'
                                    : 'Screen sharing is not supported here',
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_audioSupported)
                  SwitchListTile(
                    title: const Text('Capture system audio'),
                    value: _captureAudio,
                    onChanged: sharing
                        ? null
                        : (v) => setState(() => _captureAudio = v),
                  ),
                FilledButton.icon(
                  key: const Key('toggle'),
                  icon: Icon(sharing ? Icons.stop : Icons.screen_share),
                  label: Text(sharing ? 'Stop sharing' : 'Start screen sharing'),
                  onPressed: _busy || !ScreenSharePlugin.isSupported
                      ? null
                      : (sharing ? _stop : _start),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _audioSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
}

/// Desktop picker showing thumbnails of every screen and window.
class SourcePickerDialog extends StatelessWidget {
  const SourcePickerDialog({super.key, required this.sources});

  final List<DesktopCapturerSource> sources;

  @override
  Widget build(BuildContext context) {
    final screens = sources.where((s) => s.type == SourceType.Screen).toList();
    final windows = sources.where((s) => s.type == SourceType.Window).toList();
    return AlertDialog(
      title: const Text('Choose what to share'),
      content: SizedBox(
        width: 640,
        height: 420,
        child: ListView(
          children: [
            if (screens.isNotEmpty) _section(context, 'Screens', screens),
            if (windows.isNotEmpty) _section(context, 'Windows', windows),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
      ],
    );
  }

  Widget _section(
      BuildContext context, String title, List<DesktopCapturerSource> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final s in items)
              InkWell(
                onTap: () => Navigator.pop(context, s),
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 180,
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: s.thumbnail != null
                            ? Image.memory(s.thumbnail!,
                                fit: BoxFit.contain, gaplessPlayback: true)
                            : const Icon(Icons.desktop_windows, size: 48),
                      ),
                      const SizedBox(height: 4),
                      Text(s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
