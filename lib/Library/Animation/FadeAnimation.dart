// Fade / translate animation utilities (self‑contained replacement for simple_animations usage).
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/widgets.dart';

class FadeAnimation extends StatelessWidget {
  final double delay; // seconds multiplier (semantic kept)
  final Widget child;

  const FadeAnimation(this.delay, this.child, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tween = MultiTrackTween([
      Track("opacity").add(
        const Duration(milliseconds: 500),
        Tween<double>(begin: 0.0, end: 1.0),
        curve: Curves.bounceIn,
      ),
      Track("translateY").add(
        const Duration(milliseconds: 1500),
        Tween<double>(begin: -30.0, end: 0.0),
        curve: Curves.easeOut,
      ),
    ]);

    return ControlledAnimation<Map<String, dynamic>>(
      delay: Duration(milliseconds: (900 * delay).round()),
      duration: tween.duration,
      tween: tween,
      playback: Playback.PLAY_FORWARD,
      builderWithChild: (context, child, values) => Opacity(
        opacity: (values["opacity"] as double?) ?? 1.0,
        child: Transform.translate(
          offset: Offset(0, (values["translateY"] as double?) ?? 0.0),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Animatable that tweens multiple parallel properties (called [Track]s).
/// ---
/// The constructor of [MultiTrackTween] expects a list of [Track] objects.
/// You can fetch the specified total duration via [duration] getter.
/// ---
/// Example:
///
/// ```dart
///   final tween = MultiTrackTween([
///     Track("color")
///       .add(Duration(seconds: 1), ColorTween(begin: Colors.red, end: Colors.blue))
///       .add(Duration(seconds: 1), ColorTween(begin: Colors.blue, end: Colors.yellow)),
///     Track("width")
///       .add(Duration(milliseconds: 500), ConstantTween(200.0))
///       .add(Duration(milliseconds: 1500), Tween(begin: 200.0, end: 400.0),
///            curve: Curves.easeIn)
///   ]);
///
///   return ControlledAnimation(
///     duration: tween.duration,
///     tween: tween,
///     builder: (context, values) {
///        ...
///     }
///   );
/// ```
class MultiTrackTween extends Animatable<Map<String, dynamic>> {
  final Map<String, _TweenData> _tracksToTween = {};
  int _maxDuration = 0;

  MultiTrackTween(List<Track> tracks)
      : assert(tracks.isNotEmpty, "Add a List<Track> to configure the tween."),
        assert(tracks.where((track) => track.items.isEmpty).isEmpty,
            "Each Track needs at least one added Tween via add().") {
    _computeMaxDuration(tracks);
    _computeTrackTweens(tracks);
  }

  void _computeMaxDuration(List<Track> tracks) {
    tracks.forEach((track) {
      final trackDuration = track.items
          .map((item) => item.duration.inMilliseconds)
          .reduce((sum, item) => sum + item);
      _maxDuration = max(_maxDuration, trackDuration);
    });
  }

  void _computeTrackTweens(List<Track> tracks) {
    tracks.forEach((track) {
      final trackDuration = track.items
          .map((item) => item.duration.inMilliseconds)
          .reduce((sum, item) => sum + item);

      final sequenceItems = track.items
          .map((item) => TweenSequenceItem(
              tween: item.tween,
              weight: item.duration.inMilliseconds / _maxDuration))
          .toList();

      if (trackDuration < _maxDuration) {
        sequenceItems.add(TweenSequenceItem(
            tween: ConstantTween(null),
            weight: (_maxDuration - trackDuration) / _maxDuration));
      }

      final sequence = TweenSequence(sequenceItems);

      _tracksToTween[track.name] =
          _TweenData(tween: sequence, maxTime: trackDuration / _maxDuration);
    });
  }

  /// Returns the highest duration specified by [Track]s.
  /// ---
  /// Use it to pass it into an [ControlledAnimation].
  ///
  /// You can also scale it by multiplying a double value.
  ///
  /// Example:
  /// ```dart
  ///   final tween = MultiTrackTween(listOfTracks);
  ///
  ///   return ControlledAnimation(
  ///     duration: tween.duration * 1.25, // stretch animation by 25%
  ///     tween: tween,
  ///     builder: (context, values) {
  ///        ...
  ///     }
  ///   );
  /// ```
  Duration get duration {
    return Duration(milliseconds: _maxDuration);
  }

  /// Computes the map of specific values for the animation.
  /// You don't need to call it yourself. It's been implicitly used by
  /// [Tween]-consuming classes.
  ///
  /// See [Animatable.transform].
  @override
  Map<String, dynamic> transform(double t) {
    final Map<String, dynamic> result = Map();
    _tracksToTween.forEach((name, tweenData) {
      final double tTween = max(0, min(t, tweenData.maxTime - 0.0001));
      result[name] = tweenData.tween.transform(tTween);
    });
    return result;
  }
}

/// Single property to tween. Used by [MultiTrackTween].
class Track<T> {
  final String name;
  final List<_TrackItem> items = [];

  Track(this.name);

  Track<T> add(Duration duration, Animatable<T> tween, {Curve? curve}) {
    items.add(_TrackItem(duration, tween, curve: curve));
    return this;
  }
}

class _TrackItem<T> {
  final Duration duration;
  late final Animatable<T> tween;

  _TrackItem(this.duration, Animatable<T> baseTween, {Curve? curve}) {
    tween = curve != null ? baseTween.chain(CurveTween(curve: curve)) : baseTween;
  }
}

class _TweenData<T> {
  final Animatable<T> tween;
  final double maxTime;

  _TweenData({required this.tween, required this.maxTime});
}

/// Playback tell the controller of the animation what to do.
enum Playback {
  /// Animation stands still.
  PAUSE,

  /// Animation plays forwards and stops at the end.
  PLAY_FORWARD,

  /// Animation plays backwards and stops at the beginning.
  PLAY_REVERSE,

  /// Animation will reset to the beginning and start playing forward.
  START_OVER_FORWARD,

  /// Animation will reset to the end and start play backward.
  START_OVER_REVERSE,

  /// Animation will play forwards and start over at the beginning when it
  /// reaches the end.
  LOOP,

  /// Animation will play forward until the end and will reverse playing until
  /// it reaches the beginning. Then it starts over playing forward. And so on.
  MIRROR
}

/// Widget to create custom, managed, tween-based animations in a very simple way.
///
/// ---
///
/// An internal [AnimationController] will do everything you tell him by
/// dynamically assigning the one [Playback] to [playback] property.
/// By default the animation will start playing forward and stops at the end.
///
/// A minimum set of properties are [duration] (time span of the animation),
/// [tween] (values to interpolate among the animation) and a [builder] function
/// (defines the animated scene).
///
/// Instead of using [builder] as building function you can use for performance
/// critical scenarios [builderWithChild] along with a prebuild [child].
///
/// ---
///
/// The following properties are optional:
///
/// - You can apply a [delay] that forces the animation to pause a
///   specified time before the animation will perform the defined [playback]
///   instruction.
///
/// - You can specify a [curve] that modifies the [tween] by applying a
///   non-linear animation function. You can find curves in [Curves], for
///   example [Curves.easeOut] or [Curves.easeIn].
///
/// - You can track the animation by setting an [AnimationStatusListener] to
///   the property [animationControllerStatusListener]. The internal [AnimationController] then
///   will route out any events that occur. [ControlledAnimation] doesn't filter
///   or modifies these events. These events are currently only reliable for the
///   [playback]-types [Playback.PLAY_FORWARD] and [Playback.PLAY_REVERSE].
///
/// - You can set the start position of animation by specifying [startPosition]
///   with a value between *0.0* and *1.0*. The [startPosition] is only
///   evaluated once during the initialization of the widget.
///
class ControlledAnimation<T> extends StatefulWidget {
  final Playback playback;
  final Animatable<T> tween;
  final Curve curve;
  final Duration duration;
  final Duration delay;
  final Widget Function(BuildContext, T)? builder; // mode A
  final Widget Function(BuildContext, Widget, T)? builderWithChild; // mode B
  final Widget? child; // used with builderWithChild
  final AnimationStatusListener? animationControllerStatusListener;
  final double startPosition; // 0.0 .. 1.0

  const ControlledAnimation({
    Key? key,
    this.playback = Playback.PLAY_FORWARD,
    required this.tween,
    this.curve = Curves.linear,
    required this.duration,
    this.delay = Duration.zero,
    this.builder,
    this.builderWithChild,
    this.child,
    this.animationControllerStatusListener,
    this.startPosition = 0.0,
  })  : assert(startPosition >= 0 && startPosition <= 1,
            'startPosition must be between 0.0 and 1.0'),
        assert(
            (builder != null && builderWithChild == null && child == null) ||
                (builder == null && builderWithChild != null && child != null),
            'Provide either builder OR (builderWithChild + child).'),
        super(key: key);

  @override
  _ControlledAnimationState<T> createState() => _ControlledAnimationState<T>();
}

class _ControlledAnimationState<T> extends State<ControlledAnimation<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<T> _animation;
  bool _isDisposed = false;
  bool _waitingForDelay = true;
  bool _isCurrentlyMirroring = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() => setState(() {}))
      ..value = widget.startPosition;
    _animation = widget.tween.chain(CurveTween(curve: widget.curve)).animate(_controller);
    final statusListener = widget.animationControllerStatusListener;
    if (statusListener != null) _controller.addStatusListener(statusListener);
    _initialize();
  }

  Future<void> _initialize() async {
    if (widget.delay > Duration.zero) {
      await Future.delayed(widget.delay);
    }
    _waitingForDelay = false;
    _executeInstruction();
  }

  @override
  void didUpdateWidget(covariant ControlledAnimation<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.tween != widget.tween || oldWidget.curve != widget.curve) {
      _animation = widget.tween.chain(CurveTween(curve: widget.curve)).animate(_controller);
    }
    _executeInstruction();
  }

  void _executeInstruction() {
    if (_isDisposed || _waitingForDelay) return;
    switch (widget.playback) {
      case Playback.PAUSE:
        _controller.stop();
        break;
      case Playback.PLAY_FORWARD:
        _controller.forward();
        break;
      case Playback.PLAY_REVERSE:
        _controller.reverse();
        break;
      case Playback.START_OVER_FORWARD:
        _controller.forward(from: 0.0);
        break;
      case Playback.START_OVER_REVERSE:
        _controller.reverse(from: 1.0);
        break;
      case Playback.LOOP:
        _controller.repeat();
        break;
      case Playback.MIRROR:
        if (!_isCurrentlyMirroring) {
          _isCurrentlyMirroring = true;
          _controller.repeat(reverse: true);
        }
        break;
    }
    if (widget.playback != Playback.MIRROR) _isCurrentlyMirroring = false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.builder != null) {
      return widget.builder!(context, _animation.value);
    }
    return widget.builderWithChild!(context, widget.child!, _animation.value);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }
}
