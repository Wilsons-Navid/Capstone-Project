import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/themes/app_theme.dart';
import '../pages/ai_chat_page.dart';

class ChatMessageBubble extends StatelessWidget {
  final WilsonChatMessage message;

  /// Signed-in user's profile picture: a `data:image/...;base64,...` URI or a
  /// network URL. Shown next to the user's own messages.
  final String? userPhoto;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.userPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI Avatar (for AI messages)
          if (!message.isUser) ...[
            _buildAIAvatar(),
            const SizedBox(width: 12),
          ],
          
          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? AppTheme.primaryGradient
                    : LinearGradient(
                        colors: [
                          Colors.grey[100]!,
                          Colors.white,
                        ],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (message.isUser 
                        ? AppTheme.primaryColor 
                        : Colors.grey)
                        .withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message content
                  if (message.type == ChatMessageType.typing)
                    _buildTypingIndicator()
                  else
                    _buildMessageContent(),
                  
                  const SizedBox(height: 4),
                  
                  // Timestamp
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: message.isUser 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // User Avatar (for user messages)
          if (message.isUser) ...[
            const SizedBox(width: 12),
            _buildUserAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAIAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: AppTheme.secondaryGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.psychology,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _buildUserAvatar() {
    final photo = userPhoto;
    if (photo != null && photo.isNotEmpty) {
      Widget? image;
      if (photo.startsWith('data:image')) {
        try {
          final bytes = base64Decode(photo.split(',').last);
          image = Image.memory(bytes, width: 32, height: 32, fit: BoxFit.cover);
        } catch (_) {
          image = null;
        }
      } else {
        image = CachedNetworkImage(
          imageUrl: photo,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          placeholder: (_, __) => _avatarFallback(),
          errorWidget: (_, __, ___) => _avatarFallback(),
        );
      }
      if (image != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 32, height: 32, child: image),
        );
      }
    }
    return _avatarFallback();
  }

  Widget _avatarFallback() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _buildMessageContent() {
    // User messages are plain text; AI messages render Markdown (bold, lists,
    // tappable source links).
    if (message.isUser) {
      return Text(
        message.text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          height: 1.4,
        ),
      );
    }

    return MarkdownBody(
      data: message.text,
      onTapLink: (text, href, title) async {
        if (href == null) return;
        final uri = Uri.tryParse(href);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
        strong: const TextStyle(
            fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold),
        em: const TextStyle(
            fontSize: 14, color: Colors.black87, fontStyle: FontStyle.italic),
        listBullet: const TextStyle(fontSize: 14, color: Colors.black87),
        a: TextStyle(
            color: AppTheme.primaryColor,
            decoration: TextDecoration.underline),
        h1: const TextStyle(
            fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold),
        h2: const TextStyle(
            fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold),
        h3: const TextStyle(
            fontSize: 15, color: Colors.black87, fontWeight: FontWeight.bold),
        blockSpacing: 8,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Wilson is thinking...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 20,
          height: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              return Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                  )
                  .fadeIn(
                    delay: Duration(milliseconds: 200 * index),
                    duration: 600.ms,
                  )
                  .then()
                  .fadeOut(duration: 600.ms);
            }),
          ),
        ),
      ],
    );
  }
}