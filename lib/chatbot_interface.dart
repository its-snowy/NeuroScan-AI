import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'gemini_api.dart'; // Import kelas GeminiApi

class ChatbotInterface extends StatefulWidget {
  final String condition;

  ChatbotInterface({Key? key, required this.condition}) : super(key: key);

  @override
  _ChatbotInterfaceState createState() => _ChatbotInterfaceState();
}

class _ChatbotInterfaceState extends State<ChatbotInterface>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _messages = [
    {
      "content": "Welcome to NeuroScan Bot! How can I assist you today?",
      "isUser": false,
    }
  ];
  final TextEditingController _controller = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final GeminiApi _geminiApi = GeminiApi(); // Instansiasi GeminiApi

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Menambahkan pesan berdasarkan kondisi yang ditetapkan
    _messages.add({
      "content":
          "I see you're interested in ${widget.condition}. How can I assist you further?",
      "isUser": false,
    });

    // Mengirim respons otomatis setelah kondisi ditetapkan
    _sendAutomaticResponse(widget.condition);

    _animationController.forward();
  }

  void _sendAutomaticResponse(String condition) async {
    final userMessage =
        "$condition brain"; // Menggunakan format yang diinginkan
    final botResponse = await _geminiApi.sendMessage(userMessage);

    setState(() {
      _messages.add({"content": botResponse, "isUser": false});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleSend() async {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _messages.add({"content": _controller.text, "isUser": true});
      });

      final userMessage = _controller.text;
      _controller.clear();

      // Tampilkan pesan pemrosesan
      setState(() {
        _messages.add({
          "content": "Let me process your request... Thinking...",
          "isUser": false,
        });
      });

      // Kirim pesan ke Gemini API
      final botResponse = await _geminiApi.sendMessage(userMessage);

      // Update UI dengan respons dari API
      setState(() {
        _messages.add({"content": botResponse, "isUser": false});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(FontAwesomeIcons.brain, color: Colors.grey.shade300, size: 28),
            SizedBox(width: 12),
            Text(
              'NeuroScan Bot',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade300,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.amberAccent,
        elevation: 4,
        shadowColor: Colors.grey.shade200,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.lightBlueAccent, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessage(message);
                },
              ),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isUser = message['isUser'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.blueAccent.withOpacity(0.8),
              child: Icon(FontAwesomeIcons.robot, color: Colors.white),
            ),
            SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [Colors.blueAccent, Colors.lightBlueAccent],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade200, Colors.white],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                  bottomLeft: Radius.circular(isUser ? 24 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: RichText(
                text: TextSpan(
                  children: _buildTextSpans(message['content']),
                ),
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 12),
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.blueAccent,
              child: Icon(FontAwesomeIcons.user, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

// Fungsi untuk membangun TextSpan dari string dengan format
  List<TextSpan> _buildTextSpans(String text) {
    List<TextSpan> spans = [];
    RegExp exp = RegExp(r'(\*\*(.*?)\*\*|#(.*?))');
    int lastMatchEnd = 0;

    for (final match in exp.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        // Menambahkan teks biasa sebelum match
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(color: Colors.blueGrey.shade800, fontSize: 16),
        ));
      }
      if (match.group(1) != null) {
        // Teks bold
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
        ));
      } else if (match.group(3) != null) {
        // Teks header
        spans.add(TextSpan(
          text: match.group(3),
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.blueGrey.shade800),
        ));
      }
      lastMatchEnd = match.end;
    }

    // Menambahkan sisa teks setelah match terakhir
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(color: Colors.blueGrey.shade800, fontSize: 16),
      ));
    }

    return spans;
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade900),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.blueGrey.shade50,
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.blueGrey.shade400),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.lightBlueAccent, Colors.blueAccent],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                FontAwesomeIcons.paperPlane,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
