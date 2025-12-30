import 'dart:async';
import 'dart:io';
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.trivaBlue),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.trivaBlue,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Image',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedImage = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
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

  // --- COOL LOADING DIALOG ---
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _AiProcessingDialog(),
    );
  }

  // --- PUBLIC SUBMIT (Dipanggil Parent) ---
  Future<void> submit() async {
    // Validation
    if (_selectedImage == null && _queryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload a receipt OR type details."),
        ),
      );
      return;
    }

    // Trigger loading di Parent Button (opsional, krn kita pake dialog)
    // Tapi tetap berguna biar tombol parent gak bisa diklik 2x
    widget.onProcessingChanged(true);

    _showLoadingDialog(); // Blocking Dialog

    try {
      final response = await TripService().prepareAi(
        tripId: widget.tripId,
        image: _selectedImage,
        query: _queryController.text,
      );

      if (mounted) Navigator.pop(context); // Tutup Loading Dialog

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
            content: Text("AI Error: ${response['message'] ?? 'Unknown'}"),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Tutup loading jika error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      // Matikan loading state di parent
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
          // 1. UPLOAD SECTION
          GestureDetector(
            onTap: _showImageSourcePicker,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedImage != null
                      ? AppColors.trivaBlue
                      : Colors.grey.shade300,
                  width: _selectedImage != null ? 2 : 1,
                ),
              ),
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.trivaBlue.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            size: 32,
                            color: AppColors.trivaBlue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Scan Receipt (Optional)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tap to capture or pick from gallery",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_selectedImage!, fit: BoxFit.cover),
                          Container(color: Colors.black26),
                          const Center(
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // 2. INPUT DETAIL
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Additional Details / Text Only",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _queryController,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(fontSize: 14, height: 1.5),
                decoration: InputDecoration(
                  hintText: 'e.g., "Sate 2 for Budi, Ice Tea shared by all"',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.trivaBlue),
                  ),

                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: IconButton(
                      onPressed: _toggleListening,
                      style: IconButton.styleFrom(
                        backgroundColor: _isListening
                            ? Colors.redAccent
                            : Colors.white,
                        shadowColor: Colors.black12,
                        elevation: _isListening ? 0 : 2,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(8),
                      ),
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
            ],
          ),

          // BUTTON DIHAPUS DISINI ❌

          // Spacer agar konten tidak tertutup tombol parent di bawah layar
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// --- WIDGET KHUSUS LOADING ---
class _AiProcessingDialog extends StatefulWidget {
  const _AiProcessingDialog();

  @override
  State<_AiProcessingDialog> createState() => _AiProcessingDialogState();
}

class _AiProcessingDialogState extends State<_AiProcessingDialog> {
  int _textIndex = 0;
  final List<String> _loadingTexts = [
    "Uploading data...",
    "Connecting to Gemini AI...",
    "Scanning receipts...",
    "Identifying items...",
    "Splitting the bill...",
    "Almost there...",
  ];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _textIndex = (_textIndex + 1) % _loadingTexts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.trivaBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _loadingTexts[_textIndex],
                  key: ValueKey<int>(_textIndex),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please wait, this might take a moment.",
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
