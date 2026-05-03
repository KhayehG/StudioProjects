import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

import '../../services/sign_detector_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class SignCameraScreen extends StatefulWidget {
  const SignCameraScreen({this.targetLetter, super.key});

  /// When null, runs free practice (no target letter).
  final String? targetLetter;

  @override
  State<SignCameraScreen> createState() => _SignCameraScreenState();
}

class _SignCameraScreenState extends State<SignCameraScreen> {
  CameraController? _cameraController;
  final SignDetectorService _detector = SignDetectorService();

  List<CameraDescription> _cameras = <CameraDescription>[];
  int _selectedCameraIndex = 0;
  bool _isSwitchingCamera = false;

  bool _isAnalyzing = false;
  String _predictedLetter = '?';
  int _confidence = 0;
  String _feedback = '';
  String _detectionStatus = '';
  XFile? _capturedImage;

  bool _modelReady = false;
  String? _cameraError;

  bool _showInstructions = true;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await _detector.initialize();
    if (!mounted) {
      return;
    }
    setState(() {
      _modelReady = _detector.isReady;
    });

    final PermissionStatus cam = await Permission.camera.request();
    if (!cam.isGranted) {
      if (mounted) {
        setState(() {
          _cameraError = 'Camera permission denied';
        });
      }
      return;
    }

    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      if (mounted) {
        setState(() {
          _cameraError = 'No cameras available';
        });
      }
      return;
    }

    final int backIndex = _cameras.indexWhere(
      (CameraDescription c) => c.lensDirection == CameraLensDirection.back,
    );
    _selectedCameraIndex = backIndex >= 0 ? backIndex : 0;

    await _initCamera(_cameras[_selectedCameraIndex]);
  }

  Future<void> _initCamera(CameraDescription camera) async {
    final CameraController controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      await controller.setFocusMode(FocusMode.auto);
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Camera init failed: $e';
        });
      }
      await controller.dispose();
      return;
    }

    if (!mounted) {
      await controller.dispose();
      return;
    }

    _cameraController = controller;
    setState(() {
      _cameraError = null;
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isSwitchingCamera) {
      return;
    }
    setState(() {
      _isSwitchingCamera = true;
    });

    await _cameraController?.dispose();
    _cameraController = null;

    _selectedCameraIndex =
        (_selectedCameraIndex + 1) % _cameras.length;

    await _initCamera(_cameras[_selectedCameraIndex]);

    if (mounted) {
      setState(() {
        _isSwitchingCamera = false;
      });
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_isAnalyzing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _predictedLetter = '?';
      _confidence = 0;
      _feedback = 'Analyzing...';
      _detectionStatus = '';
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      _capturedImage = photo;

      final Uint8List bytes = await photo.readAsBytes();

      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) {
        if (mounted) {
          setState(() {
            _feedback = 'Could not read image';
            _isAnalyzing = false;
          });
        }
        return;
      }

      final Map<String, dynamic> result =
          await _detector.detectFromImage(decoded);

      final String letter = result['letter'] as String? ?? '?';
      final int confidence = result['confidence'] as int? ?? 0;

      final String? targetRaw = widget.targetLetter?.trim();
      final String? targetLetter = targetRaw != null && targetRaw.isNotEmpty
          ? targetRaw.toUpperCase()
          : null;
      final String letterUpper = letter.toUpperCase();

      final String feedback;
      final String detectionStatus;
      if (letter == '?') {
        detectionStatus = 'No hand detected.\n'
            'Hold hand closer and centred in frame.';
        feedback = '';
      } else {
        detectionStatus = '';
        if (targetLetter != null) {
          if (letterUpper == targetLetter) {
            feedback = '✅ Correct! You signed $targetLetter!';
          } else {
            feedback =
                'Detected: $letter. Try again for $targetLetter';
          }
        } else {
          feedback = 'Detected sign: $letter';
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _predictedLetter = letter;
        _confidence = confidence;
        _feedback = feedback;
        _detectionStatus = detectionStatus;
        _isAnalyzing = false;
      });
    } catch (e) {
      debugPrint('CAMERA capture error: $e');
      if (mounted) {
        setState(() {
          _feedback =
              'Error analyzing image. Please try again.';
          _detectionStatus = '';
          _isAnalyzing = false;
        });
      }
    }
  }

  void _retake() {
    setState(() {
      _capturedImage = null;
      _predictedLetter = '?';
      _confidence = 0;
      _feedback = '';
      _detectionStatus = '';
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _detector.dispose();
    super.dispose();
  }

  bool get _showPreview {
    return _cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_isSwitchingCamera;
  }

  String? get _targetLetterTrimmed {
    final String? t = widget.targetLetter?.trim();
    if (t == null || t.isEmpty) {
      return null;
    }
    return t.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final String? target = widget.targetLetter?.trim();
    final bool hasTarget = target != null && target.isNotEmpty;
    final String? targetUpper = _targetLetterTrimmed;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F5),
      appBar: AppBar(
        title: Text(
          hasTarget ? 'Sign the letter $target' : 'Sign Detection',
        ),
        backgroundColor: const Color(0xFFEEF0F5),
        foregroundColor: const Color(0xFF2D2F45),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            color: const Color(0xFF2d2f45),
            tooltip: 'Switch Camera',
            onPressed: (_cameras.length < 2 || _isSwitchingCamera)
                ? null
                : _switchCamera,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (!_modelReady)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: const Color(0xFFE0903A),
              child: const Text(
                'Loading detection models...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _showPreview
                          ? AspectRatio(
                              aspectRatio: 1 /
                                  _cameraController!.value.aspectRatio,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: _cameras.isNotEmpty &&
                                        _cameras[_selectedCameraIndex]
                                                .lensDirection ==
                                            CameraLensDirection.front
                                    ? Matrix4.rotationY(math.pi)
                                    : Matrix4.identity(),
                                child: CameraPreview(
                                  _cameraController!,
                                ),
                              ),
                            )
                          : AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Container(
                                color: const Color(0xFFD1D3D8),
                                alignment: Alignment.center,
                                child: _cameraError != null
                                    ? Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          _cameraError!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFF2D2F45),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    : const CircularProgressIndicator(),
                              ),
                            ),
                    ),
                  ),
                  if (_showInstructions && _showPreview)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          color: const Color(0xFF2d2f45)
                              .withValues(alpha: 0.85),
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: NeuCard(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    const Text(
                                      'HOW TO USE',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9a9eb5),
                                        letterSpacing: 0.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      '1. Hold your hand 20-30cm from camera',
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.8,
                                        color: Color(0xFF2d2f45),
                                      ),
                                    ),
                                    const Text(
                                      '2. Use a plain background',
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.8,
                                        color: Color(0xFF2d2f45),
                                      ),
                                    ),
                                    const Text(
                                      '3. Make sure your hand fills the frame',
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.8,
                                        color: Color(0xFF2d2f45),
                                      ),
                                    ),
                                    const Text(
                                      '4. Keep fingers clearly visible',
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.8,
                                        color: Color(0xFF2d2f45),
                                      ),
                                    ),
                                    const Text(
                                      '5. Tap capture when ready',
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.8,
                                        color: Color(0xFF2d2f45),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    GradientButton(
                                      label: 'Got it',
                                      onPressed: () {
                                        setState(() {
                                          _showInstructions = false;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_isSwitchingCamera)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          color: const Color(0xFF2d2f45)
                              .withValues(alpha: 0.7),
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                            color: Color(0xFF5B6BE8),
                          ),
                        ),
                      ),
                    ),
                  if (_isAnalyzing)
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFF2d2f45)
                            .withValues(alpha: 0.6),
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            CircularProgressIndicator(
                              color: Color(0xFF5B6BE8),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Analyzing sign...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
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
          Container(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  GestureDetector(
                    onTap: _isAnalyzing ? null : _captureAndAnalyze,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isAnalyzing
                            ? const Color(0xFF9a9eb5)
                            : const Color(0xFF5B6BE8),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: const Color(0xFF5B6BE8)
                                .withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isAnalyzing ? 'Analyzing...' : 'Tap to capture',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9a9eb5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_isAnalyzing && _capturedImage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: GestureDetector(
                onTap: _retake,
                child: NeuCard(
                  small: true,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.refresh,
                          color: Color(0xFF5B6BE8),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Retake',
                          style: TextStyle(
                            color: Color(0xFF2d2f45),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Container(
              key: ValueKey<String>(
                '${_capturedImage?.path ?? ''}|'
                '$_predictedLetter|$_feedback|$_detectionStatus|$_isAnalyzing',
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              color: const Color(0xFFEEF0F5),
              child: _predictedLetter != '?'
                  ? NeuCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Text(
                                      'Detected Letter',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9a9eb5),
                                      ),
                                    ),
                                    Text(
                                      _predictedLetter,
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: targetUpper != null &&
                                                _predictedLetter
                                                        .toUpperCase() ==
                                                    targetUpper
                                            ? const Color(0xFF27a06a)
                                            : const Color(0xFF5B6BE8),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: <Widget>[
                                    const Text(
                                      'Confidence',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9a9eb5),
                                      ),
                                    ),
                                    Text(
                                      '$_confidence%',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2d2f45),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            NeuCard(
                              small: true,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 12,
                                ),
                                child: Text(
                                  _feedback,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _feedback.startsWith('✅')
                                        ? const Color(0xFF27a06a)
                                        : const Color(0xFF2d2f45),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : (_predictedLetter == '?' &&
                          !_isAnalyzing &&
                          _detectionStatus.isNotEmpty)
                      ? NeuCard(
                          small: true,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            child: Text(
                              _detectionStatus,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9a9eb5),
                              ),
                            ),
                          ),
                        )
                      : (_feedback.isNotEmpty && !_isAnalyzing)
                          ? NeuCard(
                              small: true,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 16,
                                ),
                                child: Text(
                                  _feedback,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF9a9eb5),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Position your hand clearly in frame,\n'
              'then tap the button to detect your sign.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9a9eb5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
