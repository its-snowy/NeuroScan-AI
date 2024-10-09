import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:flutter_animate/flutter_animate.dart';
import 'chatbot_interface.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroScan AI',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF4F46E5),
        scaffoldBackgroundColor: Color(0xFFF3F4F6),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF4F46E5),
          secondary: Color(0xFF10B981),
          surface: Colors.white,
          background: Color(0xFFF3F4F6),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF1F2937),
          onBackground: Color(0xFF1F2937),
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: Color(0xFF1F2937),
                displayColor: Color(0xFF1F2937),
              ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Color(0xFF4F46E5),
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.white,
        ),
      ),
      home: MyHomePage(title: 'NeuroScan AI'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  Interpreter? _interpreter;
  File? _image;
  String _result = '';
  bool _isAnalyzing = false;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadModel();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/mri_model.tflite');
      print('Model loaded successfully');
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  void _resetState() {
    setState(() {
      _image = null;
      _result = '';
      _isAnalyzing = false;
    });
  }

  Future<void> _getImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isAnalyzing = true;
        _result = '';
      });

      // Mulai animasi loading
      _animationController.repeat();

      // Scroll to show the analyzing indicator
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });

      await _classifyImage();
    } else {
      print('No image selected.');
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _classifyImage() async {
    if (_image != null && _interpreter != null) {
      // Read and preprocess the image
      img.Image? image = img.decodeImage(_image!.readAsBytesSync());
      img.Image resizedImage = img.copyResize(image!, width: 224, height: 224);

      // Convert the image to a Float32List
      Float32List inputArray = Float32List(1 * 224 * 224 * 3);
      int pixelIndex = 0;
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          int pixel = resizedImage.getPixel(x, y);
          inputArray[pixelIndex++] = (img.getRed(pixel) - 127.5) / 127.5;
          inputArray[pixelIndex++] = (img.getGreen(pixel) - 127.5) / 127.5;
          inputArray[pixelIndex++] = (img.getBlue(pixel) - 127.5) / 127.5;
        }
      }

      // Run inference
      var outputArray = List.filled(1 * 4, 0.0).reshape([1, 4]);
      _interpreter!.run(inputArray.reshape([1, 224, 224, 3]), outputArray);

      // Process the output
      List<String> labels = ['glioma', 'healthy', 'meningioma', 'pituitary'];
      int maxIndex = 0;
      double maxValue = outputArray[0][0];
      for (int i = 1; i < 4; i++) {
        if (outputArray[0][i] > maxValue) {
          maxValue = outputArray[0][i];
          maxIndex = i;
        }
      }

      setState(() {
        _result = labels[maxIndex];
        _isAnalyzing = false;
      });
      _animationController.stop();
    }
  }

  void _navigateToChatbot() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatbotInterface(condition: "$_result symptoms"),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(horizontal: 24),
          children: [
            _buildAppBar(),
            SizedBox(height: 32),
            _buildWelcomeSection(),
            SizedBox(height: 32),
            _buildImageUploadSection(),
            SizedBox(height: 24),
            _buildResultContainer(), // Selalu tampilkan container ini
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.psychology,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Text(
                'NeuroScan AI',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          if (_image != null)
            IconButton(
              icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor),
              onPressed: _resetState,
              tooltip: 'Reset',
            ),
        ],
      ),
    );
  }

  Widget _buildResultContainer() {
    return Container(
      constraints: BoxConstraints(
        minHeight: 120, // Memberikan tinggi minimum
      ),
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: child,
            ),
          );
        },
        child: _isAnalyzing
            ? _buildAnalyzingIndicator()
            : _result.isNotEmpty
                ? _buildResultSection()
                : SizedBox.shrink(),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWelcomeSection(),
          SizedBox(height: 32),
          _buildImageUploadSection(),
          SizedBox(height: 24),
          if (_isAnalyzing) _buildAnalyzingIndicator(),
          if (_result.isNotEmpty && !_isAnalyzing) _buildResultSection(),
          SizedBox(height: 32),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI-Powered',
          style: GoogleFonts.inter(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).primaryColor,
            height: 1.2,
            letterSpacing: -1,
          ),
        ),
        Text(
          'Brain MRI Analysis',
          style: GoogleFonts.inter(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onBackground,
            height: 1.2,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: 20),
        Card(
          elevation: 8,
          shadowColor: Theme.of(context).primaryColor.withOpacity(0.2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: Theme.of(context).primaryColor, size: 28),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Upload or capture a brain MRI for instant AI-powered analysis',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    )
        .animate()
        .slideX(begin: -0.1, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }

  Widget _buildImageUploadSection() {
    return Card(
      elevation: 16,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => _getImage(ImageSource.gallery),
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                color: Color(0xFFF3F4F6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: _image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.2),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 48,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Select MRI Image',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _getImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library_rounded, size: 24),
                    label: Text(
                      'Gallery',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      elevation: 4,
                      shadowColor:
                          Theme.of(context).primaryColor.withOpacity(0.4),
                      padding: EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _getImage(ImageSource.camera),
                    icon: Icon(Icons.camera_alt_rounded, size: 24),
                    label: Text(
                      'Camera',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      elevation: 4,
                      shadowColor: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.4),
                      padding: EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().scale(
          begin: Offset(0.95, 0.95),
          end: Offset(1.0, 1.0),
          duration: 500.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildAnalyzingIndicator() {
    return Card(
      key: ValueKey<String>('analyzing'),
      elevation: 8,
      shadowColor: Theme.of(context).primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating circle
                      RotationTransition(
                        turns: _animationController,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                Theme.of(context).primaryColor.withOpacity(0.0),
                                Theme.of(context).primaryColor,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Inner white circle
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Brain icon
                      Icon(
                        Icons.psychology,
                        color: Theme.of(context).primaryColor,
                        size: 32,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'AI Analysis in Progress',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Processing your MRI scan...',
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            LinearProgressIndicator(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 16),
            _buildAnalysisSteps(),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }

  Widget _buildAnalysisSteps() {
    return Column(
      children: [
        _buildAnalysisStep(
          icon: Icons.image_search,
          text: 'Preprocessing image',
          isCompleted: true,
        ),
        SizedBox(height: 12),
        _buildAnalysisStep(
          icon: Icons.analytics,
          text: 'Analyzing patterns',
          isInProgress: true,
        ),
        SizedBox(height: 12),
        _buildAnalysisStep(
          icon: Icons.check_circle_outline,
          text: 'Generating results',
          isUpcoming: true,
        ),
      ],
    );
  }

  Widget _buildAnalysisStep({
    required IconData icon,
    required String text,
    bool isCompleted = false,
    bool isInProgress = false,
    bool isUpcoming = false,
  }) {
    Color stepColor = isCompleted
        ? Theme.of(context).colorScheme.secondary
        : isInProgress
            ? Theme.of(context).primaryColor
            : Colors.grey;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: stepColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: stepColor,
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: stepColor,
            fontWeight: isInProgress ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        if (isCompleted)
          Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.secondary,
              size: 16,
            ),
          ),
      ],
    );
  }

  Widget _buildResultSection() {
    return Card(
      elevation: 12,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE0E7FF),
              Color(0xFFECFDF5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 32,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analysis Complete',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'MRI Classification Result',
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 28),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    blurRadius: 15,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                _result,
                style: TextStyle(
                  fontSize: 28,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 28),
            _buildConfidenceIndicator(),
            SizedBox(height: 28),
            ElevatedButton(
              onPressed: _navigateToChatbot,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Discuss with AI Assistant',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .scale(
          begin: Offset(0.95, 0.95),
          end: Offset(1.0, 1.0),
          duration: 500.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 300.ms);
  }

  Widget _buildConfidenceIndicator() {
    double confidence = 0.87; // Example confidence value

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Confidence Level',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${(confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: confidence),
            duration: Duration(seconds: 1),
            builder: (context, value, child) {
              return FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
