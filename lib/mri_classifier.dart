// import 'dart:io';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image/image.dart' as img;
// import 'dart:typed_data';

// class MRIClassifier {
//   Interpreter? _interpreter;

//   MRIClassifier() {
//     _loadModel();
//   }

//   Future<void> _loadModel() async {
//     try {
//       _interpreter = await Interpreter.fromAsset('assets/mri_model.tflite');
//       print('Model loaded successfully');
//     } catch (e) {
//       print('Failed to load model: $e');
//     }
//   }

//   Future<double> detectAnomaly(File imageFile) async {
//     if (_interpreter == null) {
//       throw Exception('Model not initialized');
//     }

//     // Read and preprocess the image
//     img.Image? image = img.decodeImage(imageFile.readAsBytesSync());
//     img.Image resizedImage = img.copyResize(image!, width: 224, height: 224);

//     // Convert the image to a Float32List
//     Float32List inputArray = Float32List(1 * 224 * 224 * 3);
//     int pixelIndex = 0;
//     for (int y = 0; y < 224; y++) {
//       for (int x = 0; x < 224; x++) {
//         int pixel = resizedImage.getPixel(x, y);
//         inputArray[pixelIndex++] = (img.getRed(pixel) - 127.5) / 127.5;
//         inputArray[pixelIndex++] = (img.getGreen(pixel) - 127.5) / 127.5;
//         inputArray[pixelIndex++] = (img.getBlue(pixel) - 127.5) / 127.5;
//       }
//     }

//     // Run inference
//     var outputArray = List.filled(1 * 224 * 224 * 3, 0.0).reshape([1, 224, 224, 3]);
//     _interpreter!.run(inputArray.reshape([1, 224, 224, 3]), outputArray);

//     // Calculate the anomaly score
//     double anomalyScore = _calculateAnomalyScore(inputArray, outputArray);
//     return anomalyScore;
//   }

//   double _calculateAnomalyScore(Float32List input, List<dynamic> output) {
//     double score = 0.0;
//     for (int i = 0; i < input.length; i++) {
//       score += (input[i] - output[0][i]) * (input[i] - output[0][i]);
//     }
//     return score;
//   }

//   bool isAnomalous(double anomalyScore, double threshold) {
//     return anomalyScore > threshold;
//   }
// }
