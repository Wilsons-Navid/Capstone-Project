import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/themes/app_theme.dart';

class Mp4VideoPlayer extends StatefulWidget {
  final String url;
  final String title;
  final String description;

  const Mp4VideoPlayer({
    super.key,
    required this.url,
    required this.title,
    this.description = '',
  });

  @override
  State<Mp4VideoPlayer> createState() => _Mp4VideoPlayerState();
}

class _Mp4VideoPlayerState extends State<Mp4VideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() { _initialized = true; });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: _initialized ? _controller.value.aspectRatio : 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_initialized)
                VideoPlayer(_controller)
              else
                const Center(child: CircularProgressIndicator()),
              _ControlsOverlay(controller: _controller),
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: AppTheme.primaryColor,
                  bufferedColor: Colors.white70,
                  backgroundColor: Colors.white30,
                ),
              ),
            ],
          ),
        ),
        if (widget.title.isNotEmpty || widget.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.title.isNotEmpty)
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                if (widget.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  final VideoPlayerController controller;
  const _ControlsOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (controller.value.isPlaying) {
          controller.pause();
        } else {
          controller.play();
        }
      },
      child: Stack(
        children: <Widget>[
          if (!controller.value.isPlaying)
            const Center(
              child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white70),
            ),
        ],
      ),
    );
  }
}

