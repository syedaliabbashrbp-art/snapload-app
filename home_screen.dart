import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/ad_service.dart';
import '../models/download_result.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/platform_chip.dart';
import '../widgets/download_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _urlController = TextEditingController();
  final AdService _adService = AdService();

  // State
  bool _isLoading = false;
  DownloadResult? _result;
  String? _errorMsg;
  String _selectedQuality = '720';
  bool _audioOnly = false;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _adService.loadInterstitialAd();
    _adService.loadRewardedAd();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-paste from clipboard on open
    _autoPaste();
  }

  Future<void> _autoPaste() async {
    try {
      final data = await Clipboard.getData('text/plain');
      final text = data?.text ?? '';
      if (text.startsWith('http') &&
          (text.contains('tiktok') || text.contains('youtu') ||
           text.contains('instagram') || text.contains('twitter') ||
           text.contains('x.com') || text.contains('facebook'))) {
        setState(() => _urlController.text = text);
      }
    } catch (_) {}
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null) {
        setState(() {
          _urlController.text = data!.text!.trim();
          _result = null;
          _errorMsg = null;
        });
      }
    } catch (_) {}
  }

  String _detectPlatform(String url) {
    final u = url.toLowerCase();
    if (u.contains('tiktok'))    return 'TikTok';
    if (u.contains('youtu'))     return 'YouTube';
    if (u.contains('instagram')) return 'Instagram';
    if (u.contains('twitter') || u.contains('x.com')) return 'Twitter/X';
    if (u.contains('facebook') || u.contains('fb.watch')) return 'Facebook';
    if (u.contains('reddit'))    return 'Reddit';
    return 'Video';
  }

  Future<void> _download() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showSnack('Pehle video link paste karein');
      return;
    }
    if (!url.startsWith('http')) {
      _showSnack('Valid URL enter karein');
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
      _errorMsg = null;
    });

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    try {
      final result = await ApiService.getDownloadLinks(
        url: url,
        quality: _selectedQuality,
        audioOnly: _audioOnly,
      );

      setState(() {
        _isLoading = false;
        _result = result;
      });

      // Show interstitial ad after download
      _adService.showInterstitialIfReady();

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A1A26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _urlController.clear();
      _result = null;
      _errorMsg = null;
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _pulseController.dispose();
    _adService.dispose();
    super.dispose();
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // Background gradient blobs
          Positioned(top: -100, left: -80,
            child: _GradientBlob(color: const Color(0xFF7C3AED), size: 300)),
          Positioned(bottom: 100, right: -100,
            child: _GradientBlob(color: const Color(0xFF06B6D4), size: 250)),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // ── HEADER ───────────────────────────────────────────────
                _buildHeader(),

                // ── SCROLLABLE CONTENT ───────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Platform chips
                        _buildPlatformChips(),
                        const SizedBox(height: 24),

                        // URL Input card
                        _buildInputCard(),
                        const SizedBox(height: 16),

                        // Options row
                        _buildOptionsRow(),
                        const SizedBox(height: 20),

                        // Download button
                        _buildDownloadButton(),
                        const SizedBox(height: 20),

                        // Results / Error / Loading
                        if (_isLoading) _buildLoadingState(),
                        if (_errorMsg != null) _buildErrorState(),
                        if (_result != null) _buildResultState(),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),

                // ── BANNER AD (bottom) ───────────────────────────────────
                const BannerAdWidget(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.download_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Color(0xFF06B6D4)],
            ).createShader(bounds),
            child: const Text(
              'SnapLoad',
              style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          // Clear button
          if (_urlController.text.isNotEmpty || _result != null)
            GestureDetector(
              onTap: _clearAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A2A3D)),
                ),
                child: const Text('Clear', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  // ── PLATFORM CHIPS ────────────────────────────────────────────────────────
  Widget _buildPlatformChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [
          PlatformChip(label: 'TikTok',     color: Color(0xFF00F2EA), emoji: '♪'),
          SizedBox(width: 8),
          PlatformChip(label: 'YouTube',    color: Color(0xFFFF4444), emoji: '▶'),
          SizedBox(width: 8),
          PlatformChip(label: 'Instagram',  color: Color(0xFFE4405F), emoji: '◈'),
          SizedBox(width: 8),
          PlatformChip(label: 'Twitter/X',  color: Color(0xFF1DA1F2), emoji: '✦'),
          SizedBox(width: 8),
          PlatformChip(label: 'Facebook',   color: Color(0xFF1877F2), emoji: '📘'),
          SizedBox(width: 8),
          PlatformChip(label: 'Reddit',     color: Color(0xFFFF4500), emoji: '🔴'),
        ],
      ),
    );
  }

  // ── INPUT CARD ────────────────────────────────────────────────────────────
  Widget _buildInputCard() {
    final platform = _urlController.text.isNotEmpty
        ? _detectPlatform(_urlController.text)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A3D)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.08),
            blurRadius: 20, spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Detected platform badge
          if (platform != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF0D1F1A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                border: Border(bottom: BorderSide(color: Color(0xFF1E3A2F))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '$platform link detect hua ✓',
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

          // Text field
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Video ka link',
                  style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: _urlController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'https://vt.tiktok.com/... ya youtu.be/...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                ),
                const SizedBox(height: 12),
                // Paste button
                GestureDetector(
                  onTap: _pasteFromClipboard,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3D),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.content_paste_rounded, color: Colors.white70, size: 15),
                        SizedBox(width: 6),
                        Text('Clipboard se Paste karein',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── OPTIONS ROW ───────────────────────────────────────────────────────────
  Widget _buildOptionsRow() {
    return Row(
      children: [
        // Quality dropdown
        Expanded(
          child: _OptionBox(
            label: 'Quality',
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedQuality,
                dropdownColor: const Color(0xFF1A1A26),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                items: const [
                  DropdownMenuItem(value: 'max',  child: Text('Maximum')),
                  DropdownMenuItem(value: '1080', child: Text('1080p FHD')),
                  DropdownMenuItem(value: '720',  child: Text('720p HD')),
                  DropdownMenuItem(value: '480',  child: Text('480p')),
                  DropdownMenuItem(value: '360',  child: Text('360p')),
                ],
                onChanged: (v) => setState(() => _selectedQuality = v!),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Audio only toggle
        _OptionBox(
          label: 'Sirf Audio',
          child: Switch(
            value: _audioOnly,
            onChanged: (v) => setState(() => _audioOnly = v),
            activeColor: const Color(0xFF7C3AED),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  // ── DOWNLOAD BUTTON ───────────────────────────────────────────────────────
  Widget _buildDownloadButton() {
    return ScaleTransition(
      scale: _isLoading ? const AlwaysStoppedAnimation(1.0) : _pulseAnim,
      child: GestureDetector(
        onTap: _isLoading ? null : _download,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isLoading
                  ? [const Color(0xFF4B2E9E), const Color(0xFF3B2070)]
                  : [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(_isLoading ? 0.2 : 0.4),
                blurRadius: 20, offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _audioOnly ? Icons.music_note_rounded : Icons.download_rounded,
                        color: Colors.white, size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _audioOnly ? 'Audio Download' : 'Video Download',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.bold, letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── LOADING STATE ─────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A3D)),
      ),
      child: Column(
        children: [
          const LinearProgressIndicator(
            backgroundColor: Color(0xFF2A2A3D),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 12),
          Text(
            'Download link dhundha ja raha hai...',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── ERROR STATE ───────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F0F0F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFf43f5e).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFfb7185), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMsg ?? 'Kuch gadbad ho gayi',
              style: const TextStyle(color: Color(0xFFfb7185), fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── RESULT STATE ──────────────────────────────────────────────────────────
  Widget _buildResultState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 8),
            const Text(
              'Download Ready!',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 13, fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Text(
              '${_result!.links.length} link${_result!.links.length > 1 ? "s" : ""}',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._result!.links.map((link) => DownloadCard(link: link, index: 0)),
      ],
    );
  }
}

// ── HELPER WIDGETS ─────────────────────────────────────────────────────────

class _OptionBox extends StatelessWidget {
  final String label;
  final Widget child;
  const _OptionBox({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _GradientBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GradientBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.15), Colors.transparent],
        ),
      ),
    );
  }
}
