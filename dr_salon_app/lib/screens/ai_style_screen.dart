import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/face_analysis_result.dart';
import '../models/recommendation.dart';
import '../services/api_exception.dart';
import '../services/face_analysis_service.dart';
import '../services/photo_fix.dart';
import '../services/recommendation_service.dart';

class AiStyleScreen extends StatefulWidget {
  const AiStyleScreen({
    super.key,
    required this.analysisService,
    required this.recommendationService,
    this.imagePicker,
    this.initialImage,
  });

  final FaceAnalysisService analysisService;
  final RecommendationService recommendationService;
  final ImagePicker? imagePicker;
  final File? initialImage;

  @override
  State<AiStyleScreen> createState() => _AiStyleScreenState();
}

class _AiStyleScreenState extends State<AiStyleScreen> {
  static const _background = Color(0xFF060816);
  static const _card = Color(0x14FFFFFF);
  static const _purple = Color(0xFF6C63FF);
  static const _violet = Color(0xFF8B5CF6);
  static const _muted = Color(0xFF9CA3AF);
  static const _gold = Color(0xFFD4AF37);

  String _gender = 'male';
  File? _image;
  bool _loading = false;
  String? _error;
  FaceAnalysisResult? _analysis;
  RecommendationResult? _recommendations;
  Map<String, String> _styleImages = {};

  @override
  void initState() {
    super.initState();
    _image = widget.initialImage;
  }

  ImagePicker get _picker => widget.imagePicker ?? ImagePicker();

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked == null) {
      return;
    }
    var file = File(picked.path);
    if (source == ImageSource.camera) {
      file = await unmirrorCameraPhoto(file);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _image = file;
      _error = null;
      _analysis = null;
      _recommendations = null;
    });
  }

  Future<void> _analyze() async {
    final image = _image;
    if (image == null) {
      setState(() => _error = 'Choose a photo before analyzing.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _analysis = null;
      _recommendations = null;
    });
    try {
      final analysis = await widget.analysisService.analyze(image);
      RecommendationResult? recommendations;
      Map<String, String> images = {};
      try {
        recommendations = await widget.recommendationService.fetch(
          gender: _gender,
          faceShape: analysis.predictedFaceShape,
        );
        images = await widget.recommendationService.styleImages();
      } on ApiException catch (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _analysis = analysis;
          _error = error.message;
        });
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _analysis = analysis;
        _recommendations = recommendations;
        _styleImages = images;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'Face analysis failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            const Text(
              'AI Style Finder',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Discover hairstyles for your face shape',
              style: TextStyle(color: _muted, fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text('Select Gender', style: TextStyle(color: _muted)),
            const SizedBox(height: 12),
            Row(
              children: [
                _genderButton('male', 'Male'),
                const SizedBox(width: 12),
                _genderButton('female', 'Female'),
              ],
            ),
            const SizedBox(height: 20),
            _imageCard(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_purple, _violet]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                key: const Key('analyze-button'),
                onPressed: _loading ? null : _analyze,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white70,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Analyze', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            if (_loading) ...[
              const SizedBox(height: 28),
              const Center(child: CircularProgressIndicator(color: _purple)),
              const SizedBox(height: 12),
              const Text(
                'Analyzing Your Face',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 20),
              _messageCard(_error!, const Color(0xFFEF4444)),
            ],
            if (_analysis != null) ...[
              const SizedBox(height: 24),
              _result(),
            ],
          ],
          ),
        ),
      ),
    );
  }

  Widget _genderButton(String value, String label) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: _loading
            ? null
            : () => setState(() {
                  _gender = value;
                  _recommendations = null;
                  _analysis = null;
                }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? const LinearGradient(colors: [_purple, _violet]) : null,
            color: selected ? null : _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? Colors.transparent : const Color(0x22FFFFFF)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageCard() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x886C63FF), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: _image == null
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_camera_outlined, color: _purple, size: 48),
                SizedBox(height: 8),
                Text('Upload Your Selfie', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Use good lighting and face the camera', style: TextStyle(color: _gold, fontSize: 13)),
              ],
            )
          : Image.file(
              _image!,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stack) => const ColoredBox(
                color: Color(0xFF1D233A),
                child: Center(child: Icon(Icons.image_outlined, color: _muted, size: 48)),
              ),
            ),
    );
  }

  Widget _result() {
    final analysis = _analysis!;
    final recommendations = _recommendations;
    final showBeards = _gender == 'male';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Face Shape', style: TextStyle(color: _muted)),
        Text(
          analysis.predictedFaceShape,
          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700),
        ),
        if (recommendations != null) ...[
          const SizedBox(height: 20),
          const Text('Recommended Hairstyles', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...recommendations.hairstyles.map(_styleCard),
          if (showBeards) ...[
            const SizedBox(height: 8),
            const Text('Recommended Beard Styles', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...recommendations.beards.map(_styleCard),
          ],
        ],
      ],
    );
  }

  Widget _styleCard(StyleRecommendation style) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_styleImages[style.styleName] != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _styleImages[style.styleName]!.startsWith('/')
                    ? '${widget.analysisService.baseUrl}${_styleImages[style.styleName]}'
                    : _styleImages[style.styleName]!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(style.styleName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text(style.description, style: const TextStyle(color: _muted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _messageCard(String message, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(message, style: const TextStyle(color: Colors.white)),
    );
  }
}
