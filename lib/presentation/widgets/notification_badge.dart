// lib/presentation/widgets/notification_badge.dart
import 'package:flutter/material.dart';
import '../../services/parent_message_service.dart';

class NotificationBadge extends StatefulWidget {
  final String userId;
  final String schoolId;
  final String? studentId;
  final VoidCallback onTap;

  const NotificationBadge({
    super.key,
    required this.userId,
    required this.schoolId,
    this.studentId,
    required this.onTap,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final _service = ParentMessageService();
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  @override
  void didUpdateWidget(NotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId || 
        oldWidget.schoolId != widget.schoolId ||
        oldWidget.studentId != widget.studentId) {
      _loadCount();
    }
  }

  Future<void> _loadCount() async {
    if (widget.studentId == null) {
      setState(() {
        _unreadCount = 0;
        _isLoading = false;
      });
      return;
    }

    try {
      final count = await _service.getUnreadCount(
        studentId: widget.studentId!,
        schoolId: widget.schoolId,
      );
      if (mounted) {
        setState(() {
          _unreadCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _unreadCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> refresh() async {
    await _loadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: widget.onTap,
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount > 9 ? '9+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}