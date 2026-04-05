import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/story_model.dart';
import '../../providers/story_provider.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<CookStoryGroup> storyGroups;
  final int initialGroupIndex;

  const StoryViewerScreen({
    super.key,
    required this.storyGroups,
    this.initialGroupIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _groupPageController;
  int _currentGroupIndex = 0;
  int _currentStoryIndex = 0;
  Timer? _timer;
  double _progress = 0.0;
  static const _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex;
    _groupPageController = PageController(initialPage: _currentGroupIndex);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _groupPageController.dispose();
    super.dispose();
  }

  void _markCurrentViewed() {
    final story = widget.storyGroups[_currentGroupIndex].stories[_currentStoryIndex];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StoryProvider>().markStoryViewed(story.id);
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _progress = 0.0;
    _markCurrentViewed();
    const tick = Duration(milliseconds: 50);
    _timer = Timer.periodic(tick, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress += tick.inMilliseconds / _storyDuration.inMilliseconds;
      });
      if (_progress >= 1.0) {
        _nextStory();
      }
    });
  }

  void _nextStory() {
    final group = widget.storyGroups[_currentGroupIndex];
    if (_currentStoryIndex < group.stories.length - 1) {
      setState(() => _currentStoryIndex++);
      _startTimer();
    } else {
      _nextGroup();
    }
  }

  void _prevStory() {
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _startTimer();
    } else {
      _prevGroup();
    }
  }

  void _nextGroup() {
    if (_currentGroupIndex < widget.storyGroups.length - 1) {
      setState(() {
        _currentGroupIndex++;
        _currentStoryIndex = 0;
      });
      _groupPageController.animateToPage(
        _currentGroupIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startTimer();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevGroup() {
    if (_currentGroupIndex > 0) {
      setState(() {
        _currentGroupIndex--;
        _currentStoryIndex = 0;
      });
      _groupPageController.animateToPage(
        _currentGroupIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startTimer();
    }
  }

  String _timeAgo(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.storyGroups[_currentGroupIndex];
    final story = group.stories[_currentStoryIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _prevStory();
          } else {
            _nextStory();
          }
        },
        onLongPressStart: (_) => _timer?.cancel(),
        onLongPressEnd: (_) => _startTimer(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story image
            CachedNetworkImage(
              imageUrl: story.imageUrl,
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child:
                    CircularProgressIndicator(color: AppTheme.primaryOrange),
              ),
              errorWidget: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image,
                    color: Colors.white54, size: 64),
              ),
            ),

            // Top gradient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 150,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            ),

            // Progress bars + header
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  // Progress bars
                  Row(
                    children: List.generate(group.stories.length, (index) {
                      double value;
                      if (index < _currentStoryIndex) {
                        value = 1.0;
                      } else if (index == _currentStoryIndex) {
                        value = _progress;
                      } else {
                        value = 0.0;
                      }
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: value,
                              backgroundColor: Colors.white30,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                              minHeight: 2.5,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Cook info + close
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            AppTheme.primaryOrange.withValues(alpha: 0.3),
                        backgroundImage: group.cookProfileImageUrl != null
                            ? CachedNetworkImageProvider(group.cookProfileImageUrl!)
                            : null,
                        child: group.cookProfileImageUrl == null
                            ? Text(
                                group.cookDisplayName.isNotEmpty
                                    ? group.cookDisplayName[0].toUpperCase()
                                    : 'C',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.cookDisplayName,
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _timeAgo(story.createdAt),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom caption
            if (story.caption.isNotEmpty)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    story.caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
