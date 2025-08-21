import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 混色组件
/// 通过创建多个几何图形叠加并应用模糊效果实现颜色混合
class ColorBlender extends StatefulWidget {
  /// 颜色列表
  final List<Color> colors;

  /// 混色程度 (0.0 - 1.0)
  final double blendIntensity;

  /// 组件宽度
  final double width;

  /// 组件高度
  final double height;

  /// 形状类型
  final BlendShapeType shapeType;

  /// 动画持续时间
  final Duration animationDuration;

  /// 是否启用动画
  final bool enableAnimation;

  const ColorBlender({
    Key? key,
    required this.colors,
    this.blendIntensity = 0.5,
    this.width = 300,
    this.height = 200,
    this.shapeType = BlendShapeType.circle,
    this.animationDuration = const Duration(seconds: 3),
    this.enableAnimation = true,
  }) : super(key: key);

  @override
  State<ColorBlender> createState() => _ColorBlenderState();
}

/// 形状类型枚举
enum BlendShapeType {
  circle, // 圆形
  rectangle, // 矩形
  triangle, // 三角形
  hexagon, // 六边形
  star, // 星形
  wave, // 波浪形
}

class _ColorBlenderState extends State<ColorBlender>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _positionAnimations;
  late List<Animation<double>> _rotationAnimations;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    if (widget.enableAnimation) {
      _initializeAnimations();
      _controller.repeat(reverse: true);
    }
  }

  void _initializeAnimations() {
    final random = math.Random();
    _positionAnimations = List.generate(widget.colors.length, (index) {
      return Tween<Offset>(
        begin: Offset.zero,
        end: Offset(
          (random.nextDouble() - 0.5) * 50,
          (random.nextDouble() - 0.5) * 50,
        ),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(index * 0.1, 1.0, curve: Curves.easeInOut),
        ),
      );
    });

    _rotationAnimations = List.generate(widget.colors.length, (index) {
      return Tween<double>(begin: 0.0, end: math.pi * 2).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(index * 0.1, 1.0, curve: Curves.easeInOut),
        ),
      );
    });

    _scaleAnimations = List.generate(widget.colors.length, (index) {
      return Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(index * 0.1, 1.0, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void didUpdateWidget(ColorBlender oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.colors != oldWidget.colors ||
        widget.enableAnimation != oldWidget.enableAnimation) {
      if (widget.enableAnimation) {
        _initializeAnimations();
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withOpacity(0.05),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 背景
            Container(color: widget.colors.first),

            // 颜色层
            ..._buildColorLayers(),

            // 模糊效果层
            _buildBlurLayer(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildColorLayers() {
    final centerX = widget.width / 2;
    final centerY = widget.height / 2;
    final radius = math.max(widget.width, widget.height);

    return List.generate(widget.colors.length, (index) {
      final angle = (index * 2 * math.pi) / widget.colors.length;
      final x = centerX + radius * math.cos(angle) * 0.6;
      final y = centerY + radius * math.sin(angle) * 0.6;

      Widget colorShape = _buildShape(
        color: widget.colors[index],
        size: radius * 0.8,
        shapeType: widget.shapeType,
      );

      if (widget.enableAnimation) {
        colorShape = AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: _positionAnimations[index].value,
              child: Transform.rotate(
                angle: _rotationAnimations[index].value,
                child: Transform.scale(
                  scale: _scaleAnimations[index].value,
                  child: child,
                ),
              ),
            );
          },
          child: colorShape,
        );
      }

      return Positioned(
        left: x - radius * 0.4,
        top: y - radius * 0.4,
        child: colorShape,
      );
    });
  }

  Widget _buildShape({
    required Color color,
    required double size,
    required BlendShapeType shapeType,
  }) {
    switch (shapeType) {
      case BlendShapeType.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
        );

      case BlendShapeType.rectangle:
        return Container(
          width: size,
          height: size * 0.7,
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
          ),
        );

      case BlendShapeType.triangle:
        return CustomPaint(
          size: Size(size, size),
          painter: TrianglePainter(color: color.withOpacity(0.7)),
        );

      case BlendShapeType.hexagon:
        return CustomPaint(
          size: Size(size, size),
          painter: HexagonPainter(color: color.withOpacity(0.7)),
        );

      case BlendShapeType.star:
        return CustomPaint(
          size: Size(size, size),
          painter: StarPainter(color: color.withOpacity(0.7)),
        );

      case BlendShapeType.wave:
        return CustomPaint(
          size: Size(size * 1.5, size * 0.8),
          painter: WavePainter(color: color.withOpacity(0.7)),
        );
    }
  }

  Widget _buildBlurLayer() {
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: widget.blendIntensity * 20,
        sigmaY: widget.blendIntensity * 20,
      ),
      child: Container(color: Colors.transparent),
    );
  }
}

/// 三角形绘制器
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 六边形绘制器
class HexagonPainter extends CustomPainter {
  final Color color;

  HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(centerX, centerY) * 0.9;

    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi) / 3;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 星形绘制器
class StarPainter extends CustomPainter {
  final Color color;

  StarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final outerRadius = math.min(centerX, centerY) * 0.9;
    final innerRadius = outerRadius * 0.4;

    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi) / 5;
      final radius = i % 2 == 0 ? outerRadius : innerRadius;
      final x = centerX + radius * math.cos(angle - math.pi / 2);
      final y = centerY + radius * math.sin(angle - math.pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 波浪形绘制器
class WavePainter extends CustomPainter {
  final Color color;

  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();
    final amplitude = size.height * 0.3;
    final frequency = 2.0;

    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x += 1) {
      final y =
          size.height / 2 +
          amplitude * math.sin(x * frequency * 2 * math.pi / size.width);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 混色控制面板
class ColorBlenderPanel extends StatefulWidget {
  final ValueChanged<List<Color>>? onColorsChanged;
  final ValueChanged<double>? onBlendIntensityChanged;

  const ColorBlenderPanel({
    Key? key,
    this.onColorsChanged,
    this.onBlendIntensityChanged,
  }) : super(key: key);

  @override
  State<ColorBlenderPanel> createState() => _ColorBlenderPanelState();
}

class _ColorBlenderPanelState extends State<ColorBlenderPanel> {
  List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
  ];
  double _blendIntensity = 0.5;
  BlendShapeType _shapeType = BlendShapeType.circle;
  bool _enableAnimation = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 预览区域
        Container(
          margin: const EdgeInsets.all(16),
          child: ColorBlender(
            colors: _colors,
            blendIntensity: _blendIntensity,
            shapeType: _shapeType,
            enableAnimation: _enableAnimation,
          ),
        ),

        // 控制面板
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('颜色设置', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _colors.asMap().entries.map((entry) {
                        final index = entry.key;
                        final color = entry.value;
                        return GestureDetector(
                          onTap: () => _pickColor(index),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey, width: 2),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 16),

                Text(
                  '混色程度: ${_blendIntensity.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Slider(
                  value: _blendIntensity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  onChanged: (value) {
                    setState(() {
                      _blendIntensity = value;
                    });
                    widget.onBlendIntensityChanged?.call(value);
                  },
                ),
                const SizedBox(height: 16),

                Text('形状类型', style: Theme.of(context).textTheme.titleMedium),
                DropdownButton<BlendShapeType>(
                  value: _shapeType,
                  isExpanded: true,
                  items:
                      BlendShapeType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_getShapeTypeName(type)),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _shapeType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: const Text('启用动画'),
                  value: _enableAnimation,
                  onChanged: (value) {
                    setState(() {
                      _enableAnimation = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getShapeTypeName(BlendShapeType type) {
    switch (type) {
      case BlendShapeType.circle:
        return '圆形';
      case BlendShapeType.rectangle:
        return '矩形';
      case BlendShapeType.triangle:
        return '三角形';
      case BlendShapeType.hexagon:
        return '六边形';
      case BlendShapeType.star:
        return '星形';
      case BlendShapeType.wave:
        return '波浪形';
    }
  }

  Future<void> _pickColor(int index) async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => ColorPickerDialog(initialColor: _colors[index]),
    );

    if (color != null) {
      setState(() {
        _colors[index] = color;
      });
      widget.onColorsChanged?.call(_colors);
    }
  }
}

/// 颜色选择器对话框
class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const ColorPickerDialog({Key? key, required this.initialColor})
    : super(key: key);

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择颜色'),
      content: SingleChildScrollView(
        child: ColorPicker(
          color: _selectedColor,
          onColorChanged: (color) {
            setState(() {
              _selectedColor = color;
            });
          },
          width: 40,
          height: 40,
          borderRadius: 4,
          spacing: 8,
          runSpacing: 8,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

/// 简化版颜色选择器
class ColorPicker extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;
  final double width;
  final double height;
  final double borderRadius;
  final double spacing;
  final double runSpacing;

  const ColorPicker({
    Key? key,
    required this.color,
    required this.onColorChanged,
    this.width = 40,
    this.height = 40,
    this.borderRadius = 4,
    this.spacing = 8,
    this.runSpacing = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
    ];

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children:
          colors.map((c) {
            return GestureDetector(
              onTap: () => onColorChanged(c),
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: c == color ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}
