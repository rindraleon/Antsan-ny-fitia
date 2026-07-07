import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/content_provider.dart';
import '../services/export_service.dart';
import '../main.dart';

class DetailScreen extends StatefulWidget {
  final Song song;
  const DetailScreen({super.key, required this.song});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _showFontControls = false;
  final ScrollController _scrollController = ScrollController();

  // Auto-scroll
  bool _isAutoScrolling = false;
  Timer? _scrollTimer;
  double _scrollSpeed = 1.2; // pixels per frame ~ 72px/sec at 60fps
  // Vitesses: lent, normal, rapide
  final List<double> _speeds = [0.6, 1.2, 2.0, 3.0];
  int _speedIndex = 1;

  @override
  void dispose() {
    _stopAutoScroll();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleAutoScroll() {
    if (_isAutoScrolling) {
      _stopAutoScroll();
    } else {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    if (_isAutoScrolling) return;
    setState(() => _isAutoScrolling = true);

    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      if (current >= max) {
        _stopAutoScroll();
        return;
      }
      _scrollController.jumpTo(
        (current + _scrollSpeed).clamp(0.0, max),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Auto-scroll activé • vitesse ${_speedIndex + 1}/4'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _stopAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    if (_isAutoScrolling && mounted) {
      setState(() => _isAutoScrolling = false);
    }
  }

  void _changeSpeed() {
    _speedIndex = (_speedIndex + 1) % _speeds.length;
    _scrollSpeed = _speeds[_speedIndex];
    if (_isAutoScrolling) {
      // redémarre pour appliquer
      _stopAutoScroll();
      Future.delayed(const Duration(milliseconds: 50), _startAutoScroll);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vitesse auto-scroll: ${_speedLabel()}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  String _speedLabel() {
    switch (_speedIndex) {
      case 0: return 'Très lent';
      case 1: return 'Normal';
      case 2: return 'Rapide';
      case 3: return 'Très rapide';
      default: return 'Normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final themeData = themeProvider.current;
    final primary = themeData.primary;
    final isDark = themeData.brightness == Brightness.dark;

    return Consumer<ContentProvider>(
      builder: (context, provider, _) {
        final isFav = provider.isFavorite(widget.song);
        final fontSize = provider.fontSize;
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFD5D5D0),
          appBar: AppBar(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            title: Text(
              widget.song.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red.shade300 : Colors.white),
                onPressed: () => provider.toggleFavorite(widget.song),
                tooltip: 'Favori',
              ),
              // Play / Pause auto-scroll
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: CircleAvatar(
                  backgroundColor: _isAutoScrolling ? Colors.white : Colors.white24,
                  child: IconButton(
                    icon: Icon(
                      _isAutoScrolling ? Icons.pause : Icons.play_arrow,
                      color: _isAutoScrolling ? primary : Colors.white,
                    ),
                    tooltip: _isAutoScrolling ? 'Pause auto-scroll' : 'Auto-scroll',
                    onPressed: _toggleAutoScroll,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) async {
                  switch (value) {
                    case 'speed':
                      _changeSpeed();
                      break;
                    case 'share_text':
                      await ExportService.shareSongText(widget.song);
                      break;
                    case 'share_pdf':
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Génération PDF...')));
                      }
                      await ExportService.shareSongPdf(widget.song);
                      break;
                    case 'print':
                      await ExportService.printSong(widget.song);
                      break;
                    case 'top':
                      _scrollController.animateTo(0,
                          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
                      _stopAutoScroll();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'speed',
                    child: Row(children: [
                      const Icon(Icons.speed, size: 18),
                      const SizedBox(width: 8),
                      Text('Vitesse: ${_speedLabel()}'),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'share_text', child: Row(children: [Icon(Icons.share, size: 18), SizedBox(width: 8), Text('Partager texte')])),
                  const PopupMenuItem(value: 'share_pdf', child: Row(children: [Icon(Icons.picture_as_pdf, size: 18), SizedBox(width: 8), Text('Exporter PDF')])),
                  const PopupMenuItem(value: 'print', child: Row(children: [Icon(Icons.print, size: 18), SizedBox(width: 8), Text('Imprimer')])),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'top', child: Row(children: [Icon(Icons.vertical_align_top, size: 18), SizedBox(width: 8), Text('Retour haut')])),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              // Si l'utilisateur scroll manuellement, stop auto-scroll
              if (_isAutoScrolling && notification.direction != ScrollDirection.idle) {
                _stopAutoScroll();
              }
              return false;
            },
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.song.lyrics,
                          style: TextStyle(
                            fontSize: fontSize,
                            height: 1.85,
                            color: isDark ? Colors.grey.shade200 : const Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: Text(
                            '— Fin —\nChorale Antsan\'ny Fitia',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).hintColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Auto-scroll indicator
                if (_isAutoScrolling)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      color: primary.withOpacity(0.9),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Auto-scroll • ${_speedLabel()} • touchez pour pause',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Floating font / scroll controls
                Positioned(
                  right: 20,
                  bottom: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_showFontControls) ...[
                        _roundBtn(
                          icon: Icons.remove,
                          tooltip: 'Texte -',
                          onTap: provider.decreaseFont,
                          bg: Theme.of(context).cardColor,
                          fg: primary,
                        ),
                        const SizedBox(height: 10),
                        _roundBtn(
                          icon: Icons.add,
                          tooltip: 'Texte +',
                          onTap: provider.increaseFont,
                          bg: Theme.of(context).cardColor,
                          fg: primary,
                        ),
                        const SizedBox(height: 10),
                        _roundBtn(
                          icon: Icons.speed,
                          tooltip: 'Vitesse scroll',
                          onTap: _changeSpeed,
                          bg: Theme.of(context).cardColor,
                          fg: primary,
                        ),
                        const SizedBox(height: 10),
                        _roundBtn(
                          icon: Icons.close,
                          onTap: () => setState(() => _showFontControls = false),
                          bg: primary,
                          fg: Colors.white,
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Play/Pause flottant aussi
                      if (_isAutoScrolling)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _roundBtn(
                            icon: Icons.pause,
                            tooltip: 'Pause',
                            onTap: _stopAutoScroll,
                            bg: Colors.orange.shade600,
                            fg: Colors.white,
                          ),
                        ),
                      GestureDetector(
                        onTap: () => setState(() => _showFontControls = !_showFontControls),
                        child: Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Aa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: fontSize.clamp(18.0, 24.0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Tap to pause overlay when auto-scrolling
                if (_isAutoScrolling)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _stopAutoScroll,
                      behavior: HitTestBehavior.translucent,
                      child: Container(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _roundBtn({
    required IconData icon,
    required VoidCallback onTap,
    required Color bg,
    required Color fg,
    String? tooltip,
  }) {
    final btn = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))
        ],
        border: bg == Colors.white || bg == Theme.of(context).cardColor
            ? Border.all(color: Colors.grey.shade300)
            : null,
      ),
      child: Icon(icon, color: fg, size: 22),
    );
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(onTap: onTap, child: btn),
    );
  }
}
