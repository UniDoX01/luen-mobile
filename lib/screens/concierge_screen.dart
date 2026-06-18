/// Concierge tab — AI chat backed by /api/chat/ai/message.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state.dart';
import '../theme.dart';
import 'package:google_fonts/google_fonts.dart';

class _Msg {
  final String role; // 'user' | 'agent'
  final String text;
  _Msg(this.role, this.text);
  Map<String, String> toApi() => {'role': role == 'user' ? 'user' : 'assistant', 'text': text};
}

class ConciergeTab extends ConsumerStatefulWidget {
  const ConciergeTab({super.key});
  @override
  ConsumerState<ConciergeTab> createState() => _ConciergeTabState();
}

class _ConciergeTabState extends ConsumerState<ConciergeTab> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  bool _sending = false;
  bool _aiEnabled = false;
  String _header = 'LUÉN Concierge';
  String _greeting = 'Hello — welcome to LUÉN. How may we assist you today?';
  String _placeholder = 'Ask about shipping, returns, sizing…';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final cfg = await ref.read(apiProvider).conciergeConfig();
      setState(() {
        _aiEnabled = cfg['ai_enabled'] == true;
        _header = cfg['header_label'] ?? _header;
        _greeting = cfg['greeting'] ?? _greeting;
        _placeholder = cfg['placeholder'] ?? _placeholder;
        if (_messages.isEmpty) _messages.add(_Msg('agent', _greeting));
      });
    } catch (_) {
      if (_messages.isEmpty) setState(() => _messages.add(_Msg('agent', _greeting)));
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _messages.add(_Msg('user', text));
      _sending = true;
    });
    _scrollDown();
    try {
      final hist = _messages.where((m) => m.role == 'user' || m.role == 'agent').toList()..removeLast();
      final reply = await ref.read(apiProvider).conciergeMessage(text, hist.map((m) => m.toApi()).toList());
      setState(() {
        _messages.add(_Msg('agent', reply ?? "I'm not certain I can answer that here. Please email concierge@houseofluen.com or open a ticket and our team will respond within one business day."));
      });
    } catch (_) {
      setState(() => _messages.add(_Msg('agent', 'The concierge is briefly unavailable. Please try again shortly.')));
    } finally {
      setState(() => _sending = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: LuenColors.border))),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_header, style: GoogleFonts.playfairDisplay(fontSize: 18, color: LuenColors.foreground)),
            const SizedBox(height: 2),
            Text(_aiEnabled ? 'LIVE · AI-ASSISTED' : 'LIVE · PRE-SET RESPONSES',
              style: const TextStyle(color: LuenColors.primary, fontSize: 9, letterSpacing: 3)),
          ])),
        ]),
      ),
      Expanded(child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length + (_sending ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == _messages.length && _sending) {
            return const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Concierge is typing…', style: TextStyle(color: LuenColors.mutedFg, fontSize: 12)));
          }
          final m = _messages[i];
          final me = m.role == 'user';
          return Align(
            alignment: me ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              decoration: BoxDecoration(
                color: me ? LuenColors.primary.withOpacity(0.10) : LuenColors.surface,
                border: Border.all(color: me ? LuenColors.primary.withOpacity(0.4) : LuenColors.border),
              ),
              child: Text(m.text, style: const TextStyle(color: LuenColors.foreground, fontSize: 13, height: 1.45)),
            ),
          );
        },
      )),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SafeArea(
          top: false,
          child: Row(children: [
            Expanded(child: TextField(
              controller: _controller,
              minLines: 1, maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(hintText: _placeholder, hintStyle: const TextStyle(color: LuenColors.mutedFg)),
            )),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sending ? null : _send,
              icon: _sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send, color: LuenColors.primary),
            ),
          ]),
        ),
      ),
    ]);
  }
}
