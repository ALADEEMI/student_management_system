import 'package:flutter/material.dart';
import 'dart:math' as math;

class RadialFab extends StatefulWidget {
  final List<Widget> children;
  final IconData openIcon;
  final IconData closeIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const RadialFab({
    Key? key,
    required this.children,
    this.openIcon = Icons.menu,
    this.closeIcon = Icons.close,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  _RadialFabState createState() => _RadialFabState();
}

class _RadialFabState extends State<RadialFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(),
          ..._buildExpandingActionButtons(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: 56.0,
      height: 56.0,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.close,
                color: widget.foregroundColor ?? Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    // Define angles for expansion towards top-right quadrant
    const double startAngle = 0.0; // Start angle towards right (0 degrees)
    const double endAngle = math.pi * 0.5; // End angle towards up (90 degrees)
    final step = (endAngle - startAngle) / (count > 1 ? count - 1 : 1);
    final distance = 80.0; // Distance from center FAB

    for (var i = 0; i < count; i++) {
      final double angle = startAngle + i * step;
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angle * 180 / math.pi, // Convert angle to degrees for rotation
          maxDistance: distance,
          progress: _expandAnimation,
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            onPressed: _toggle,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => ScaleTransition(child: child, scale: animation),
              child: _open
                  ? Icon(widget.closeIcon, key: ValueKey<bool>(_open))
                  : Icon(widget.openIcon, key: ValueKey<bool>(_open)),
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    Key? key,
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  }) : super(key: key);

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0), // Convert degrees back to radians
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy,
          child: Transform.rotate(
            // Optional: Rotate the child FABs to align with the arc
            // angle: (1.0 - progress.value) * math.pi / 2,
            angle: 0, // Keep FABs upright
            child: Opacity(
              opacity: progress.value, // Fade in/out
              child: child,
            ),
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}