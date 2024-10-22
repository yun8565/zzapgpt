import 'dart:math';

import 'package:chat_gpt_app/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

void main() {
  runApp(ChatGptApp());
}

class ChatGptApp extends StatefulWidget {
  ChatGptApp({super.key});

  @override
  State<ChatGptApp> createState() => _ChatGptAppState();
}

class _ChatGptAppState extends State<ChatGptApp> {
  final TextEditingController _controller = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  bool _canSendMessage = false;

  ChatRoom _room = ChatRoom(
    chats: [],
    createdAt: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    Gemini.init(apiKey: "");
  }

  @override
  void dispose() {
    // 화면이 더이상 불필요해지는 시점. 해제가 되는 시점을 감지
    _controller.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            "GPT",
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
        ),
        body: Stack(
          children: [
            // 빈 채팅방
            if (_room.chats.isEmpty)
              Align(
                alignment: Alignment.center,
                child: Image.asset(
                  "assets/logo.png",
                  width: 40,
                  height: 40,
                ),
              ),

            ListView(
              padding: EdgeInsets.only(bottom: 100),
              children: [
                for (var chat in _room.chats)
                  chat.isMe
                      ? _buildMyChatBubble(chat)
                      : _buildGptChatBubble(chat),
              ],
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: _buildTextField(),
            ),
          ],
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildGptChatBubble(ChatMessage chat) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(
            left: 20,
            top: 5,
          ),
          child: Image.asset(
            "assets/logo.png",
            width: 20,
            height: 20,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 300,
            ),
            margin: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 5,
              bottom: 40,
            ),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(chat.text),
          ),
        ),
      ],
    );
  }

  Widget _buildMyChatBubble(ChatMessage chat) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 250,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        margin: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(chat.text),
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onSubmitted: (text) {
          _sendMessage();
        },
        onChanged: (text) {
          setState(() {
            _canSendMessage = text.isNotEmpty;
          });
        },
        decoration: InputDecoration(
          hintText: "메시지",
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 15,
          ),
          suffixIcon: IconButton(
            icon: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _canSendMessage ? Colors.black : Colors.black12,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              _sendMessage();
            },
          ),
        ),
        style: TextStyle(
          fontSize: 14,
        ),
      ),
    );
  }

  void _sendMessage() {
    // 텍스트 필드 포커스를 잃었다.
    _focusNode.unfocus();

    final ChatMessage chat = ChatMessage(
      isMe: true, // Random().nextBool(),
      text: _controller.text,
      sentAt: DateTime.now(),
    );

    setState(() {
      _room.chats.add(chat);
      _canSendMessage = false;
    });

    // 사용자가 채팅창에 입력한 문자를 Gemini에게 전달
    String question = "'${_controller.text}'";
    // 삼행시를 위한 튜닝
    question +=
        "   한국어로 된 앞의 키워드로 다음과 같은 답변을 해줘. 내가 3글자로 된 키워드를 줄테니까, 키워드의 각 한국어 문자를 시작으로 하는 문장을 총 3개 만들어줘. 예를 들어 '오리발'이 키워드면, '오': 오늘도 '리': 리듬을 탄다. '발':발이 간지럽도록 이런식으로 만들어줘. 그리고 각 문장이 어느정도 연관성이 있으면 좋겠어. 한국어로 시작하지 않는 문자이면, 영어로 된 것도 괜찮아";

    Gemini.instance.streamGenerateContent(question).listen((event) {
      // Gemini로부터 응답값을 받아볼 수 있도록 한다.
      print(event.output);
      // 응답값을 챗지피티 말풍선에 추가해준다.
      setState(() {
        _room.chats.last.text += (event.output ?? "");
      });
    });

    // 챗지피티 말풍선을 노출 (말풍선의 내용은 비어있다)
    _room.chats.add(
      ChatMessage(isMe: false, text: "", sentAt: DateTime.now()),
    );

    // 텍스트 필드에 있는 값을 조작을 해야한다. (비워주기)
    _controller.clear();
  }
}
