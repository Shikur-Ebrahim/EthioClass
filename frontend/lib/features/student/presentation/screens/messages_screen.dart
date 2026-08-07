import 'package:flutter/material.dart';
import 'course_details_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _searchController = TextEditingController();

  static const _conversations = [
    _ConvoData(
      name: 'Abel Bekele',
      lastMessage: 'Hello! The new chapter is now available. Check it out.',
      time: '10:45 AM',
      unread: 2,
      color: Color(0xFF1E50FF),
      icon: Icons.science,
    ),
    _ConvoData(
      name: 'Mesfin Tadesse',
      lastMessage: 'Don\'t forget about tomorrow\'s quiz. Good luck!',
      time: '9:20 AM',
      unread: 1,
      color: Color(0xFF7C3AED),
      icon: Icons.calculate,
    ),
    _ConvoData(
      name: 'EthioClass Support',
      lastMessage: 'Thank you for reaching out. We will get back to you soon.',
      time: 'Yesterday',
      unread: 1,
      color: Color(0xFFFFC107),
      icon: Icons.support_agent,
    ),
    _ConvoData(
      name: 'Rahel Worku',
      lastMessage: 'Can you please share the notes for chapter 2?',
      time: 'Yesterday',
      unread: 0,
      color: Color(0xFF059669),
      icon: Icons.biotech,
    ),
    _ConvoData(
      name: 'Yonatan Alemu',
      lastMessage: 'Great job on the last quiz! Keep it up.',
      time: 'May 15',
      unread: 0,
      color: Color(0xFF16A34A),
      icon: Icons.eco,
    ),
    _ConvoData(
      name: 'Study Group \u2013 Physics 12',
      lastMessage: 'Selam: I found some useful resources for chapter 3.',
      time: 'May 14',
      unread: 3,
      color: Color(0xFF0891B2),
      icon: Icons.group,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourseColors.bg,
      appBar: AppBar(
        backgroundColor: CourseColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: CourseColors.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Messages',
            style: TextStyle(color: CourseColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, color: CourseColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: CourseColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CourseColors.border),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: CourseColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search messages',
                  hintStyle: TextStyle(color: CourseColors.textSecondary, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: CourseColors.textSecondary, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          // Conversation list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _conversations.length,
              separatorBuilder: (_, __) => const Divider(color: CourseColors.border, height: 1),
              itemBuilder: (context, i) => _ConversationTile(data: _conversations[i]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: CourseColors.bg,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: CourseColors.yellow,
      unselectedItemColor: CourseColors.textSecondary,
      currentIndex: 4,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Courses'),
        BottomNavigationBarItem(icon: Icon(Icons.download_for_offline_outlined), label: 'Downloads'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: 'Bookmarks'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}

class _ConvoData {
  final String name, lastMessage, time;
  final int unread;
  final Color color;
  final IconData icon;
  const _ConvoData({
    required this.name, required this.lastMessage, required this.time,
    required this.unread, required this.color, required this.icon,
  });
}

class _ConversationTile extends StatelessWidget {
  final _ConvoData data;
  const _ConversationTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatScreen(convoData: data)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          // Avatar
          Stack(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: data.color.withOpacity(0.4)),
              ),
              child: Icon(data.icon, color: data.color, size: 24),
            ),
            if (data.name != 'EthioClass Support')
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: CourseColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: CourseColors.bg, width: 2),
                  ),
                ),
              ),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(data.name,
                      style: TextStyle(
                          color: CourseColors.textPrimary,
                          fontSize: 14,
                          fontWeight: data.unread > 0 ? FontWeight.bold : FontWeight.w500)),
                ),
                Text(data.time,
                    style: TextStyle(
                        color: data.unread > 0 ? CourseColors.primaryBlue : CourseColors.textSecondary,
                        fontSize: 11,
                        fontWeight: data.unread > 0 ? FontWeight.w600 : FontWeight.normal)),
              ]),
              const SizedBox(height: 5),
              Row(children: [
                Expanded(
                  child: Text(data.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: data.unread > 0 ? CourseColors.textPrimary : CourseColors.textSecondary,
                          fontSize: 12)),
                ),
                if (data.unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: const BoxDecoration(color: CourseColors.primaryBlue, shape: BoxShape.circle),
                    child: Text('${data.unread}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
            ],
          )),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHAT SCREEN
// ─────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final _ConvoData convoData;
  const ChatScreen({super.key, required this.convoData});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hello! The new chapter is now available. Check it out.', 'isMe': false, 'time': '10:45 AM'},
    {'text': 'Thank you! I\'ll start watching it now.', 'isMe': true, 'time': '10:47 AM'},
    {'text': 'Great! Let me know if you have any questions.', 'isMe': false, 'time': '10:48 AM'},
    {'text': 'Sure, will do. The content looks really helpful!', 'isMe': true, 'time': '10:50 AM'},
  ];

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'text': text, 'isMe': true, 'time': 'Now'});
      _msgController.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourseColors.bg,
      appBar: AppBar(
        backgroundColor: CourseColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: CourseColors.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: widget.convoData.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.convoData.icon, color: widget.convoData.color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(widget.convoData.name,
              style: const TextStyle(color: CourseColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.videocam_outlined, color: CourseColors.textSecondary), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call_outlined, color: CourseColors.textSecondary), onPressed: () {}),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (ctx, i) {
              final msg = _messages[i];
              final isMe = msg['isMe'] as bool;
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(ctx).size.width * 0.72),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? CourseColors.primaryBlue : CourseColors.cardBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isMe ? 14 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 14),
                    ),
                    border: isMe ? null : Border.all(color: CourseColors.border),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(msg['text'] as String,
                        style: TextStyle(color: isMe ? Colors.white : CourseColors.textPrimary, fontSize: 13, height: 1.4)),
                    const SizedBox(height: 4),
                    Text(msg['time'] as String,
                        style: TextStyle(color: isMe ? Colors.white60 : CourseColors.textSecondary, fontSize: 10)),
                  ]),
                ),
              );
            },
          ),
        ),
        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: CourseColors.bg,
            border: Border(top: BorderSide(color: CourseColors.border)),
          ),
          child: SafeArea(
            child: Row(children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: CourseColors.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: CourseColors.border),
                  ),
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: CourseColors.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: CourseColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(color: CourseColors.primaryBlue, shape: BoxShape.circle),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
