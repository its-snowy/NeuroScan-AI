// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image/image.dart' as img;
// import 'dart:typed_data';

// class ScanClassifier extends StatefulWidget {
//   @override
//   _ScanClassifierState createState() => _ScanClassifierState();
// }

// class _ScanClassifierState extends State<ScanClassifier> {
//   Interpreter? _interpreter;
//   File? _image;
//   String _classificationResult = '';
//   final ImagePicker _picker = ImagePicker();

//   @override
//   void initState() {
//     super.initState();
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

//   Future<void> _getImageFromCamera() async {
//     final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//       });
//       _processAndClassifyImage();
//     }
//   }

//   Future<void> _processAndClassifyImage() async {
//     if (_image == null) return;

//     String result = await classifyImage(_image!);
//     setState(() {
//       _classificationResult = result;
//     });
//   }

//   Future<String> classifyImage(File imageFile) async {
//     if (_interpreter == null) {
//       return 'Model not initialized';
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
//     var outputArray = List.filled(1 * 4, 0.0).reshape([1, 4]);
//     _interpreter!.run(inputArray.reshape([1, 224, 224, 3]), outputArray);

//     // Process the output
//     List<String> labels = ['glioma', 'healthy', 'meningioma', 'pituitary'];
//     int maxIndex = 0;
//     double maxValue = outputArray[0][0];
//     for (int i = 1; i < 4; i++) {
//       if (outputArray[0][i] > maxValue) {
//         maxValue = outputArray[0][i];
//         maxIndex = i;
//       }
//     }

//     return labels[maxIndex];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('MRI Classifier'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             _image == null
//                 ? Text('No image captured')
//                 : Image.file(_image!),
//             SizedBox(height: 20),
//             Text(
//               'Classification Result: $_classificationResult',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _getImageFromCamera,
//               child: Text('Capture MRI Image'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
