import 'package:flutter/foundation.dart';

class NirmaanYoutubeValue {
  final bool isReady;
  final bool isPlaying;
  final bool isMuted;
  final bool showControls;
  final Duration position;
  final Duration duration;
  final double playbackRate;

  const NirmaanYoutubeValue({
    this.isReady = false,
    this.isPlaying = false,
    this.isMuted = false,
    this.showControls = true,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playbackRate = 1.0,
  });

  NirmaanYoutubeValue copyWith({
    bool? isReady,
    bool? isPlaying,
    bool? isMuted,
    bool? showControls,
    Duration? position,
    Duration? duration,
    double? playbackRate,
  }) {
    return NirmaanYoutubeValue(
      isReady: isReady ?? this.isReady,
      isPlaying: isPlaying ?? this.isPlaying,
      isMuted: isMuted ?? this.isMuted,
      showControls: showControls ?? this.showControls,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playbackRate: playbackRate ?? this.playbackRate,
    );
  }
}

class NirmaanYoutubeController extends ValueNotifier<NirmaanYoutubeValue> {
  NirmaanYoutubeController() : super(const NirmaanYoutubeValue());

  Future<void> Function()? _play;
  Future<void> Function()? _pause;
  Future<void> Function()? _mute;
  Future<void> Function()? _unMute;
  Future<void> Function(Duration position)? _seekTo;
  Future<void> Function(double rate)? _setPlaybackRate;

  void bind({
    required Future<void> Function() play,
    required Future<void> Function() pause,
    required Future<void> Function() mute,
    required Future<void> Function() unMute,
    required Future<void> Function(Duration position) seekTo,
    required Future<void> Function(double rate) setPlaybackRate,
  }) {
    _play = play;
    _pause = pause;
    _mute = mute;
    _unMute = unMute;
    _seekTo = seekTo;
    _setPlaybackRate = setPlaybackRate;
  }

  Future<void> setPlaybackRate(double rate) async {
    await _setPlaybackRate?.call(rate);
    value = value.copyWith(playbackRate: rate);
  }

  Future<void> play() async {
    await _play?.call();
  }

  Future<void> pause() async {
    await _pause?.call();
  }

  Future<void> togglePlayPause() async {
    if (value.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> mute() async {
    await _mute?.call();
  }

  Future<void> unMute() async {
    await _unMute?.call();
  }

  Future<void> toggleMute() async {
    if (value.isMuted) {
      await unMute();
    } else {
      await mute();
    }
  }

  Future<void> seekTo(Duration position) async {
    final safePosition = position.inMilliseconds < 0 ? Duration.zero : position;

    await _seekTo?.call(safePosition);
  }

  Future<void> seekBackward10() async {
    await seekTo(value.position - const Duration(seconds: 10));
  }

  Future<void> seekForward10() async {
    await seekTo(value.position + const Duration(seconds: 10));
  }

  void showControls() {
    value = value.copyWith(showControls: true);
  }

  void hideControls() {
    value = value.copyWith(showControls: false);
  }

  void toggleControls() {
    value = value.copyWith(showControls: !value.showControls);
  }

  void updateValue(NirmaanYoutubeValue newValue) {
    value = newValue;
  }
}
