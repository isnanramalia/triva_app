import 'dart:async';
import 'dart:io';
import 'dart:math' as math; // Perlu math untuk animasi orbit
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/trip_service.dart';
import 'ai_review_page.dart';

class AiAddTab extends StatefulWidget {
  final int tripId;
  final List<dynamic> members;
  final Function(bool isProcessing) onProcessingChanged;

  const AiAddTab({
    super.key,
    required this.tripId,
    required this.members,
    required this.onProcessingChanged,
  });

  @override
  State<AiAddTab> createState() => AiAddTabState();
}

class AiAddTabState extends State<AiAddTab> {
  File? _selectedImage;
  final _queryController = TextEditingController();

  // Speech Logic
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onError: (_) => setState(() => _isListening = false),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
    } catch (_) {}
  }

  // --- CAMERA / GALLERY ---
  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.trivaBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.trivaBlue,
                  ),
                ),
                title: const Text(
                  'Ambil Foto',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Colors.purple,
                  ),
                ),
                title: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                  ),
                  title: const Text(
                    'Hapus Gambar',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedImage = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70, // Kompres dikit biar cepet upload
      );
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // --- MIC LOGIC ---
  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      if (!_speechEnabled) _initSpeech();
      setState(() => _isListening = true);
      await _speech.listen(
        localeId: "id_ID",
        onResult: (val) =>
            setState(() => _queryController.text = val.recognizedWords),
      );
    }
  }

  // --- SHOW ANIMATED DIALOG ---
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(
        0.4,
      ), // Background agak gelap biar fokus
      builder: (context) => const _AiProcessingDialog(),
    );
  }

  // --- PUBLIC SUBMIT ---
  Future<void> submit() async {
    if (_selectedImage == null && _queryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Upload struk atau tulis detail pengeluaran dulu ya!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    widget.onProcessingChanged(true);
    _showLoadingDialog();

    try {
      final response = await TripService().prepareAi(
        tripId: widget.tripId,
        image: _selectedImage,
        query: _queryController.text,
      );

      if (mounted) Navigator.pop(context); // Tutup Dialog

      if (mounted && response['status'] == 'success') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AiReviewPage(
              tripId: widget.tripId,
              members: widget.members,
              aiResult: response['data'],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Ups: ${response['message'] ?? 'Gagal memproses AI'}",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      widget.onProcessingChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. UPLOAD AREA (Modern Style)
          GestureDetector(
            onTap: _showImageSourcePicker,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedImage != null
                      ? AppColors.trivaBlue
                      : Colors.grey.shade200,
                  width: _selectedImage != null ? 2 : 1.5,
                ),
              ),
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F5FF),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.trivaBlue.withOpacity(0.1),
                              width: 8,
                            ),
                          ),
                          child: const Icon(
                            Icons.document_scanner_rounded,
                            size: 36,
                            color: AppColors.trivaBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Tap to Scan Receipt",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Supports photos & screenshots",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_selectedImage!, fit: BoxFit.cover),
                          Container(
                            color: Colors.black38,
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Change Photo",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // 2. INPUT TEXT AREA
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  "Additional Notes (Optional)",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              TextField(
                controller: _queryController,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(fontSize: 15, height: 1.4),
                decoration: InputDecoration(
                  hintText: 'Misal: "Martabak dibagi rata, rokok punya Budi"',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),

                  // Clean Border Style
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.trivaBlue,
                      width: 1.5,
                    ),
                  ),

                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? Colors.redAccent
                            : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _toggleListening,
                        icon: Icon(
                          _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                          color: _isListening
                              ? Colors.white
                              : AppColors.trivaBlue,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ==========================================
// 🔥 THE NEW "WOW" ANIMATED DIALOG 🔥
// ==========================================
class _AiProcessingDialog extends StatefulWidget {
  const _AiProcessingDialog();

  @override
  State<_AiProcessingDialog> createState() => _AiProcessingDialogState();
}

class _AiProcessingDialogState extends State<_AiProcessingDialog>
    with TickerProviderStateMixin {
  // -- Controllers --
  late AnimationController _pulseController;
  late AnimationController _orbitController;
  late Timer _timer;

  int _stepIndex = 0;

  final List<Map<String, dynamic>> _steps = [
    {"text": "Uploading to cloud...", "emoji": "☁️", "color": Colors.blue},
    {"text": "Firing up the AI...", "emoji": "🤖", "color": Colors.purple},
    {"text": "Scanning receipt...", "emoji": "🧾", "color": Colors.orange},
    {"text": "Detecting prices...", "emoji": "🏷️", "color": Colors.green},
    {"text": "Doing the math...", "emoji": "🤔", "color": Colors.pink},
    {"text": "Almost ready...", "emoji": "✨", "color": Colors.amber},
  ];

  @override
  void initState() {
    super.initState();

    // 1. Orbit Controller (Partikel berputar terus menerus)
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // 2. Pulse Controller (Napas membesar mengecil)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // 3. Timer ganti text/emoji
    _timer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (mounted) {
        setState(() {
          _stepIndex = (_stepIndex + 1) % _steps.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _orbitController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _steps[_stepIndex];
    final currentColor = currentStep['color'] as Color;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- THE ORBITING BRAIN VISUAL ---
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Layer 1: Outer Orbit Particles
                  RotationTransition(
                    turns: _orbitController,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: Stack(
                        children: [
                          // Dot 1
                          Align(
                            alignment: Alignment.topCenter,
                            child: _buildParticle(Colors.blueAccent, 6),
                          ),
                          // Dot 2
                          Align(
                            alignment: Alignment.bottomRight,
                            child: _buildParticle(Colors.purpleAccent, 5),
                          ),
                          // Dot 3
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: _buildParticle(Colors.orangeAccent, 4),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Layer 2: Pulse Glow Background
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.85, end: 1.05).animate(
                      CurvedAnimation(
                        parent: _pulseController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            currentColor.withOpacity(0.4),
                            currentColor.withOpacity(0.1),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: currentColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                    ),
                  ),

                  // Layer 3: Elastic Bouncing Emoji
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      // Efek membal (Elastic Out)
                      return ScaleTransition(
                        scale: CurvedAnimation(
                          parent: animation,
                          curve: Curves.elasticOut,
                        ),
                        child: child,
                      );
                    },
                    child: Text(
                      currentStep['emoji'],
                      key: ValueKey<String>(
                        currentStep['emoji'],
                      ), // Key penting buat switch
                      style: const TextStyle(fontSize: 42),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- THE CARD (TEXT) ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.black.withOpacity(0.1),
                //     blurRadius: 20,
                //     offset: const Offset(0, 10),
                //   ),
                // ],
              ),
              child: Column(
                children: [
                  // Animated Text Sliding Up
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.5), // Muncul dari bawah
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      currentStep['text'],
                      key: ValueKey<String>(currentStep['text']),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progress Bar Mini
                  SizedBox(
                    width: 100,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.grey[100],
                      valueColor: AlwaysStoppedAnimation<Color>(currentColor),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 5)],
      ),
    );
  }
}
