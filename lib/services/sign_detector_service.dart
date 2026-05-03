import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// 2D distance in x/y for classification (z ignored).
double _classifyDist(List<double> a, List<double> b) {
  final double dx = a[0] - b[0];
  final double dy = a[1] - b[1];
  return math.sqrt(dx * dx + dy * dy);
}

/// Full calibrated A–Z geometric rules (x/y only; z never used).
/// Safe to call from a [compute] isolate (no TFLite).
Map<String, dynamic> signDetectorClassifyLandmarks(
    List<List<double>> landmarks) {
  if (landmarks.length < 21) {
    return <String, dynamic>{'letter': '?', 'confidence': 0};
  }

  final List<double> wrist = landmarks[0];
  final List<double> thumbMcp = landmarks[2];
  final List<double> thumbIp = landmarks[3];
  final List<double> thumbTip = landmarks[4];
  final List<double> indexMcp = landmarks[5];
  final List<double> indexPip = landmarks[6];
  final List<double> indexTip = landmarks[8];
  final List<double> midMcp = landmarks[9];
  final List<double> midPip = landmarks[10];
  final List<double> midTip = landmarks[12];
  final List<double> ringMcp = landmarks[13];
  final List<double> ringPip = landmarks[14];
  final List<double> ringTip = landmarks[16];
  final List<double> pinkyMcp = landmarks[17];
  final List<double> pinkyPip = landmarks[18];
  final List<double> pinkyTip = landmarks[20];

  final bool iUp = indexTip[1] < indexPip[1];
  final bool mUp = midTip[1] < midPip[1];
  final bool rUp = ringTip[1] < ringPip[1];
  final bool pUp = pinkyTip[1] < pinkyPip[1];

  final bool iCurl = indexTip[1] > indexMcp[1];
  final bool mCurl = midTip[1] > midMcp[1];
  final bool rCurl = ringTip[1] > ringMcp[1];
  final bool pCurl = pinkyTip[1] > pinkyMcp[1];

  final double hs = _classifyDist(wrist, midMcp);
  final double thresh = hs * 0.35;
  final double tightThresh = hs * 0.25;

  final bool tITouch = _classifyDist(thumbTip, indexTip) < thresh;
  final bool tMTouch = _classifyDist(thumbTip, midTip) < thresh;
  final bool tRTouch = _classifyDist(thumbTip, ringTip) < thresh;
  final bool tPTouch = _classifyDist(thumbTip, pinkyTip) < thresh;
  final bool iMClose = _classifyDist(indexTip, midTip) < tightThresh;

  final bool thumbExt = (thumbTip[0] - thumbIp[0]).abs() > hs * 0.2 ||
      thumbTip[1] < thumbMcp[1];

  final bool thumbTucked = thumbTip[0] > indexMcp[0] &&
      thumbTip[0] < ringMcp[0];

  debugPrint(
    'FINGERS iUp=$iUp mUp=$mUp '
    'rUp=$rUp pUp=$pUp',
  );
  debugPrint(
    'CURLS iCurl=$iCurl mCurl=$mCurl '
    'rCurl=$rCurl pCurl=$pCurl',
  );
  debugPrint(
    'TOUCHES tI=$tITouch tM=$tMTouch '
    'tR=$tRTouch tP=$tPTouch',
  );
  debugPrint(
    'thumbExt=$thumbExt '
    'thumbTucked=$thumbTucked hs=$hs',
  );

  String letter = '?';
  int confidence = 0;

  if (!iUp &&
      !mUp &&
      !rUp &&
      !pUp &&
      !tITouch &&
      thumbExt &&
      !thumbTucked) {
    letter = 'A';
    confidence = 85;
  } else if (iUp && mUp && rUp && pUp && !thumbExt) {
    letter = 'B';
    confidence = 90;
  } else if (!iUp &&
      !mUp &&
      !rUp &&
      !pUp &&
      !tITouch &&
      !thumbTucked &&
      _classifyDist(thumbTip, indexTip) < hs * 0.5 &&
      _classifyDist(thumbTip, indexTip) > thresh) {
    letter = 'C';
    confidence = 75;
  } else if (iUp && !mUp && !rUp && !pUp && tMTouch) {
    letter = 'D';
    confidence = 82;
  } else if (iCurl && mCurl && rCurl && pCurl && thumbTucked) {
    letter = 'E';
    confidence = 78;
  } else if (tITouch && mUp && rUp && pUp) {
    letter = 'F';
    confidence = 82;
  } else if (!iUp &&
      !mUp &&
      !rUp &&
      !pUp &&
      (indexTip[1] - indexPip[1]).abs() < hs * 0.2 &&
      thumbExt) {
    letter = 'G';
    confidence = 72;
  } else if (!iUp &&
      !mUp &&
      !rUp &&
      !pUp &&
      (indexTip[1] - indexPip[1]).abs() < hs * 0.2 &&
      (midTip[1] - midPip[1]).abs() < hs * 0.2) {
    letter = 'H';
    confidence = 72;
  } else if (!iUp && !mUp && !rUp && pUp && !thumbExt) {
    letter = 'I';
    confidence = 88;
  } else if (!iUp && !mUp && !rUp && pUp && thumbExt) {
    letter = 'J';
    confidence = 70;
  } else if (iUp &&
      mUp &&
      !rUp &&
      !pUp &&
      thumbExt &&
      !tITouch &&
      !tMTouch) {
    letter = 'K';
    confidence = 78;
  } else if (iUp && !mUp && !rUp && !pUp && thumbExt) {
    letter = 'L';
    confidence = 90;
  } else if (!iUp &&
      !mUp &&
      !rUp &&
      !pUp &&
      thumbTucked &&
      _classifyDist(thumbTip, midTip) < thresh &&
      _classifyDist(thumbTip, ringTip) < thresh) {
    letter = 'M';
    confidence = 73;
  } else if (!iUp &&
      !mUp &&
      !rUp &&
      !pUp &&
      thumbTucked &&
      _classifyDist(thumbTip, indexTip) < thresh &&
      _classifyDist(thumbTip, midTip) < thresh) {
    letter = 'N';
    confidence = 73;
  } else if (!iUp &&
      !mUp &&
      !rUp &&
      !pUp &&
      tITouch &&
      !thumbTucked) {
    letter = 'O';
    confidence = 80;
  } else if (!iUp &&
      !mUp &&
      !rUp &&
      !pUp &&
      thumbExt &&
      !tITouch &&
      indexTip[1] > wrist[1]) {
    letter = 'P';
    confidence = 70;
  } else if (!iUp &&
      !mUp &&
      !rUp &&
      !pUp &&
      thumbExt &&
      tITouch &&
      indexTip[1] > wrist[1]) {
    letter = 'Q';
    confidence = 70;
  } else if (iUp && mUp && !rUp && !pUp && iMClose && !thumbExt) {
    letter = 'R';
    confidence = 78;
  } else if (!iUp &&
      !mUp &&
      !rUp &&
      !pUp &&
      !thumbExt &&
      !thumbTucked &&
      !tITouch) {
    letter = 'S';
    confidence = 78;
  } else if (!iUp &&
      !mUp &&
      !rUp &&
      !pUp &&
      thumbTucked &&
      tITouch) {
    letter = 'T';
    confidence = 73;
  } else if (iUp && mUp && !rUp && !pUp && iMClose) {
    letter = 'U';
    confidence = 82;
  } else if (iUp && mUp && !rUp && !pUp && !iMClose) {
    letter = 'V';
    confidence = 85;
  } else if (iUp && mUp && rUp && !pUp) {
    letter = 'W';
    confidence = 85;
  } else if (!iUp &&
      !mUp &&
      !rUp &&
      !pUp &&
      indexTip[1] < indexMcp[1] &&
      indexTip[1] > indexPip[1]) {
    letter = 'X';
    confidence = 70;
  } else if (!iUp && !mUp && !rUp && pUp && thumbExt) {
    letter = 'Y';
    confidence = 85;
  } else if (iUp &&
      !mUp &&
      !rUp &&
      !pUp &&
      !thumbExt &&
      !tITouch) {
    letter = 'Z';
    confidence = 68;
  }

  debugPrint('CLASSIFIED: $letter ($confidence%)');
  return <String, dynamic>{
    'letter': letter,
    'confidence': confidence,
  };
}

/// Isolate entry: serializable landmark lists for [compute].
Map<String, dynamic> signDetectorClassifyLandmarksForCompute(
    List<List<num>> landmarks) {
  if (landmarks.length < 21) {
    return <String, dynamic>{'letter': '?', 'confidence': 0};
  }
  final List<List<double>> asDouble = List<List<double>>.generate(
    landmarks.length,
    (int i) => landmarks[i].map((num n) => n.toDouble()).toList(),
  );
  return signDetectorClassifyLandmarks(asDouble);
}

class SignDetectorService {
  Interpreter? _palmDetector;
  Interpreter? _landmarkDetector;
  bool _isReady = false;

  bool get isReady => _isReady;

  double _dist(List<double> a, List<double> b) {
    return _classifyDist(a, b);
  }

  bool _isValidHand(List<List<double>> landmarks) {
    final List<double> wrist = landmarks[0];
    final List<double> thumbCmc = landmarks[1];
    final List<double> indexMcp = landmarks[5];
    final List<double> middleTip = landmarks[12];
    final List<double> pinkyMcp = landmarks[17];

    final double handHeight = _dist(wrist, middleTip);
    if (handHeight < 0.1) {
      debugPrint(
        'INVALID: hand too small '
        '(height=${handHeight.toStringAsFixed(3)})',
      );
      return false;
    }

    final double mcpSpread = _dist(indexMcp, pinkyMcp);
    if (mcpSpread < 0.05) {
      debugPrint(
        'INVALID: MCP joints too close '
        '(spread=${mcpSpread.toStringAsFixed(3)})',
      );
      return false;
    }

    final double thumbWristDist = _dist(thumbCmc, wrist);
    if (thumbWristDist > 0.6) {
      debugPrint(
        'INVALID: thumb CMC too far from wrist '
        '(dist=${thumbWristDist.toStringAsFixed(3)})',
      );
      return false;
    }

    debugPrint(
      'VALID HAND DETECTED: '
      'height=${handHeight.toStringAsFixed(3)} '
      'mcpSpread=${mcpSpread.toStringAsFixed(3)} '
      'thumbDist=${thumbWristDist.toStringAsFixed(3)}',
    );
    return true;
  }

  List<List<double>> _normalizeLandmarks(List<List<double>> landmarks) {
    final double minX =
        landmarks.map((List<double> l) => l[0]).reduce(math.min);
    final double maxX =
        landmarks.map((List<double> l) => l[0]).reduce(math.max);
    final double minY =
        landmarks.map((List<double> l) => l[1]).reduce(math.min);
    final double maxY =
        landmarks.map((List<double> l) => l[1]).reduce(math.max);

    final double rangeX = maxX - minX;
    final double rangeY = maxY - minY;

    List<List<double>> normalizedLandmarks = landmarks;
    if (rangeX > 0.001 && rangeY > 0.001) {
      normalizedLandmarks = landmarks
          .map(
            (List<double> l) => <double>[
              (l[0] - minX) / rangeX,
              (l[1] - minY) / rangeY,
              l[2],
            ],
          )
          .toList();
      debugPrint(
        'Landmarks normalized. rangeX=$rangeX rangeY=$rangeY',
      );
    } else {
      debugPrint(
        'WARNING: Landmarks not normalized — '
        'rangeX=$rangeX rangeY=$rangeY',
      );
    }

    return normalizedLandmarks;
  }

  void _logNormalizedLandmarks(List<List<double>> normalizedLandmarks) {
    debugPrint('=== LANDMARK VALUES ===');
    debugPrint('0 WRIST:       ${normalizedLandmarks[0]}');
    debugPrint('4 THUMB_TIP:   ${normalizedLandmarks[4]}');
    debugPrint('5 INDEX_MCP:   ${normalizedLandmarks[5]}');
    debugPrint('8 INDEX_TIP:   ${normalizedLandmarks[8]}');
    debugPrint('9 MIDDLE_MCP:  ${normalizedLandmarks[9]}');
    debugPrint('12 MIDDLE_TIP: ${normalizedLandmarks[12]}');
    debugPrint('16 RING_TIP:   ${normalizedLandmarks[16]}');
    debugPrint('20 PINKY_TIP:  ${normalizedLandmarks[20]}');
  }

  Future<bool> _isPalmDetected(img.Image image) async {
    if (_palmDetector == null) {
      debugPrint('Palm detector not loaded, skipping palm check.');
      return true;
    }

    final Map<int, Object> outputs = <int, Object>{};
    try {
      final Interpreter palm = _palmDetector!;
      final List<int> inputShape = palm.getInputTensor(0).shape;
      final int h = inputShape.length > 1 ? inputShape[1] : 192;
      final int w = inputShape.length > 2 ? inputShape[2] : 192;

      final img.Image resized = img.copyResize(
        image,
        width: w,
        height: h,
        interpolation: img.Interpolation.linear,
      );

      final List<dynamic> input = List<dynamic>.generate(
        1,
        (_) => List<dynamic>.generate(
          h,
          (int y) => List<dynamic>.generate(
            w,
            (int x) {
              final img.Pixel p = resized.getPixel(x, y);
              return <double>[
                p.r.toInt() / 255.0,
                p.g.toInt() / 255.0,
                p.b.toInt() / 255.0,
              ];
            },
          ),
        ),
      );

      final List<Tensor> palmOutputs = palm.getOutputTensors();
      for (int i = 0; i < palmOutputs.length; i++) {
        outputs[i] = _allocateTensor(palmOutputs[i].shape);
      }

      final List<Tensor> palmInputTensors = palm.getInputTensors();
      final List<Object> palmInputs = <Object>[input as Object];
      for (int i = 1; i < palmInputTensors.length; i++) {
        palmInputs.add(_allocateTensor(palmInputTensors[i].shape));
      }

      palm.runForMultipleInputs(palmInputs, outputs);

      outputs.forEach((int key, Object value) {
        final List<double> flattened = _flattenToDoubles(value);
        debugPrint(
          'PALM output[$key] values=${flattened.length} '
          'preview=${flattened.take(8).toList()}',
        );
      });

      return true;
    } catch (e) {
      debugPrint('PALM check error: $e');
      return true;
    } finally {
      outputs.clear();
      debugPrint('Palm check complete');
    }
  }

  Future<void> initialize() async {
    try {
      final InterpreterOptions options = InterpreterOptions()..threads = 2;
      _palmDetector = await Interpreter.fromAsset(
        'assets/models/palm_detection.tflite',
        options: options,
      );
      _landmarkDetector = await Interpreter.fromAsset(
        'assets/models/hand_landmark.tflite',
        options: options,
      );
      _isReady = true;
      final List<int> inputShape =
          _landmarkDetector!.getInputTensor(0).shape;
      debugPrint(
        'SIGN DETECTOR: Both models loaded. '
        'Input: $inputShape, Landmark output: output[2]',
      );
    } catch (e, st) {
      _palmDetector?.close();
      _landmarkDetector?.close();
      _palmDetector = null;
      _landmarkDetector = null;
      _isReady = false;
      debugPrint('SIGN DETECTOR ERROR: $e');
      debugPrint('$st');
    }
  }

  Map<String, dynamic> classifyFromLandmarks(List<List<double>> landmarks) {
    return signDetectorClassifyLandmarks(landmarks);
  }

  Future<List<List<double>>?> extractLandmarksFromImage(
      img.Image inputImage) async {
    if (!_isReady || _palmDetector == null || _landmarkDetector == null) {
      return null;
    }

    final Map<int, Object> outputs = <int, Object>{};
    try {
      final Interpreter landmark = _landmarkDetector!;

      final List<int> inputShape = landmark.getInputTensor(0).shape;
      int inputH = 224;
      int inputW = 224;
      if (inputShape.length >= 4) {
        inputH = inputShape[1];
        inputW = inputShape[2];
      } else if (inputShape.length == 3) {
        inputH = inputShape[0];
        inputW = inputShape[1];
      } else if (inputShape.length == 2) {
        inputH = inputShape[0];
        inputW = inputShape[1];
      }

      final img.Image resized = img.copyResize(
        inputImage,
        width: inputW,
        height: inputH,
        interpolation: img.Interpolation.linear,
      );

      final List<dynamic> inputBuffer = List<dynamic>.generate(
        1,
        (_) => List<dynamic>.generate(
          inputH,
          (int y) => List<dynamic>.generate(
            inputW,
            (int x) {
              final img.Pixel pixel = resized.getPixel(x, y);
              return <double>[
                pixel.r.toInt() / 255.0,
                pixel.g.toInt() / 255.0,
                pixel.b.toInt() / 255.0,
              ];
            },
          ),
        ),
      );

      final List<Tensor> outputTensors = landmark.getOutputTensors();
      if (outputTensors.isEmpty) {
        debugPrint('LANDMARK: No output tensors.');
        return null;
      }

      for (int i = 0; i < outputTensors.length; i++) {
        outputs[i] = _allocateTensor(outputTensors[i].shape);
      }

      final List<Tensor> inputTensors = landmark.getInputTensors();
      final List<Object> inputs = <Object>[inputBuffer as Object];
      for (int i = 1; i < inputTensors.length; i++) {
        inputs.add(_allocateTensor(inputTensors[i].shape));
      }

      landmark.runForMultipleInputs(inputs, outputs);

      if (!outputs.containsKey(2)) {
        debugPrint('LANDMARK: Missing expected output[2] (landmarks).');
        return null;
      }

      final List<double> flatLandmarks = _flattenToDoubles(outputs[2]!);
      debugPrint('Using output[2], flat length: ${flatLandmarks.length}');

      if (flatLandmarks.length < 63) {
        debugPrint('Not enough landmark data: ${flatLandmarks.length}');
        return null;
      }

      final List<List<double>> landmarks = List<List<double>>.generate(
        21,
        (int i) => <double>[
          flatLandmarks[i * 3],
          flatLandmarks[i * 3 + 1],
          flatLandmarks[i * 3 + 2],
        ],
      );

      debugPrint('Landmarks parsed successfully. Wrist: ${landmarks[0]}');
      return landmarks;
    } catch (e, st) {
      debugPrint('SIGN DETECTOR detect error: $e');
      debugPrint('SIGN DETECTOR stack: $st');
      return null;
    } finally {
      outputs.clear();
    }
  }

  Object _allocateTensor(List<int> shape) {
    if (shape.isEmpty) {
      return 0.0;
    }
    if (shape.length == 1) {
      return List<double>.filled(shape[0], 0.0);
    }
    return List<Object>.generate(
      shape[0],
      (_) => _allocateTensor(shape.sublist(1)),
    );
  }

  List<double> _flattenToDoubles(dynamic input) {
    final List<double> result = <double>[];
    if (input is double) {
      result.add(input);
    } else if (input is num) {
      result.add(input.toDouble());
    } else if (input is List<dynamic>) {
      for (final dynamic item in input) {
        result.addAll(_flattenToDoubles(item));
      }
    }
    return result;
  }

  Future<Map<String, dynamic>> detectFromImage(img.Image inputImage) async {
    try {
      final bool palmFound = await _isPalmDetected(inputImage);
      debugPrint('Palm detection result: $palmFound');

      final List<List<double>>? landmarks =
          await extractLandmarksFromImage(inputImage);
      if (landmarks == null) {
        return <String, dynamic>{'letter': '?', 'confidence': 0};
      }

      final List<List<double>> normalizedLandmarks =
          _normalizeLandmarks(landmarks);
      _logNormalizedLandmarks(normalizedLandmarks);

      if (!_isValidHand(normalizedLandmarks)) {
        debugPrint('Geometric hand check failed — no valid hand in frame');
        return <String, dynamic>{'letter': '?', 'confidence': 0};
      }

      final Map<String, dynamic> result =
          classifyFromLandmarks(normalizedLandmarks);
      final String letter = result['letter'] as String? ?? '?';
      final int confidence = result['confidence'] as int? ?? 0;
      debugPrint('RESULT: letter=$letter confidence=$confidence');
      debugPrint('======================');

      return <String, dynamic>{
        'letter': letter,
        'confidence': confidence,
      };
    } catch (e, st) {
      debugPrint('SIGN DETECTOR detectFromImage error: $e');
      debugPrint('SIGN DETECTOR detectFromImage stack: $st');
      return <String, dynamic>{'letter': '?', 'confidence': 0};
    }
  }

  void dispose() {
    _palmDetector?.close();
    _landmarkDetector?.close();
    _palmDetector = null;
    _landmarkDetector = null;
    _isReady = false;
    debugPrint('SIGN DETECTOR: Models disposed.');
  }
}
