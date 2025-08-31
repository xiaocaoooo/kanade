import 'package:flutter/material.dart';

class KanadeSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final KanadeSliderStyle style;

  const KanadeSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.style,
    this.onChangeStart,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  State<KanadeSlider> createState() => _KanadeSliderState();
}

class _KanadeSliderState extends State<KanadeSlider> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    // 计算滑块的进度百分比，确保值在0到1之间
    final double progress = ((widget.value - widget.min) /
            (widget.max - widget.min))
        .clamp(0.0, 1.0);

    // 计算轨道和滑块的垂直位置
    final double trackHeight = _isDragging ? 12.0 : 6.0;
    final double trackVerticalMargin = (48.0 - trackHeight) / 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 使用父容器的宽度，而不是屏幕宽度
        final double trackWidth = constraints.maxWidth;

        return GestureDetector(
          // 处理拖动开始事件
          onPanStart: (details) {
            setState(() {
              _isDragging = true;
            });
            if (widget.onChangeStart != null) {
              widget.onChangeStart!(widget.value);
            }
          },

          // 处理拖动更新事件
          onPanUpdate: (details) {
            if (widget.onChanged == null) return;

            // 获取滑块容器的大小和位置
            final RenderBox box = context.findRenderObject() as RenderBox;
            final Offset localOffset = box.globalToLocal(
              details.globalPosition,
            );

            // 计算新的滑块值
            final double newValue =
                widget.min +
                (localOffset.dx / trackWidth).clamp(0.0, 1.0) *
                    (widget.max - widget.min);
            widget.onChanged!(newValue);
          },

          // 处理拖动结束事件
          onPanEnd: (details) {
            if (widget.onChangeEnd != null) {
              widget.onChangeEnd!(widget.value);
            }
            setState(() {
              _isDragging = false;
            });
          },

          // 处理点击事件
          onTapDown: (details) {
            if (widget.onChangeStart != null) {
              widget.onChangeStart!(widget.value);
            }

            final RenderBox box = context.findRenderObject() as RenderBox;
            final Offset localOffset = box.globalToLocal(
              details.globalPosition,
            );
            final double newValue =
                widget.min +
                (localOffset.dx / trackWidth).clamp(0.0, 1.0) *
                    (widget.max - widget.min);
            if (widget.onChanged != null) {
              widget.onChanged!(newValue);
            }

            if (widget.onChangeEnd != null) {
              widget.onChangeEnd!(newValue);
            }
          },

          child: SizedBox(
            height: 48.0,
            width: trackWidth,
            child: Stack(
              children: [
                // 背景轨道
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  top: trackVerticalMargin,
                  left: 0,
                  right: 0,
                  bottom: trackVerticalMargin,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.style.inactiveColor,
                      borderRadius: BorderRadius.circular(trackHeight / 2),
                    ),
                  ),
                ),

                // 已填充部分轨道
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  left: 0,
                  right: 0,
                  top: trackVerticalMargin,
                  bottom: trackVerticalMargin,
                  // width: trackWidth * progress,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.style.activeColor,
                            borderRadius: BorderRadius.circular(
                              trackHeight / 2,
                            ),
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration:
                            _isDragging
                                ? const Duration(milliseconds: 0)
                                : const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        width: trackWidth * (1 - progress),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class KanadeSliderStyle {
  final Color activeColor;
  final Color inactiveColor;

  const KanadeSliderStyle({
    required this.activeColor,
    required this.inactiveColor,
  });
}
