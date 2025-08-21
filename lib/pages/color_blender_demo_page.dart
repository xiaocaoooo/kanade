import 'package:flutter/material.dart';
import '../widgets/color_blender.dart';

/// 混色组件演示页面
class ColorBlenderDemoPage extends StatefulWidget {
  const ColorBlenderDemoPage({Key? key}) : super(key: key);

  @override
  State<ColorBlenderDemoPage> createState() => _ColorBlenderDemoPageState();
}

class _ColorBlenderDemoPageState extends State<ColorBlenderDemoPage> {
  final List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
  ];
  double _blendIntensity = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('混色组件演示'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 标题区域
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '颜色混合艺术',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '通过几何图形叠加和模糊效果创建美丽的颜色混合',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // 主要演示区域
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 混色预览
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    child: ColorBlender(
                      colors: _colors,
                      blendIntensity: _blendIntensity,
                      width: MediaQuery.of(context).size.width - 32,
                      height: 250,
                      shapeType: BlendShapeType.circle,
                      enableAnimation: true,
                    ),
                  ),

                  // 控制面板
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '颜色配置',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // 颜色选择器
                          Text(
                            '选择颜色:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _colors.asMap().entries.map((entry) {
                              final index = entry.key;
                              final color = entry.value;
                              return GestureDetector(
                                onTap: () => _pickColor(index),
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: color.computeLuminance() > 0.5 
                                            ? Colors.black 
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          
                          // 混色程度滑块
                          Text(
                            '混色程度: ${_blendIntensity.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.deepPurple,
                              inactiveTrackColor: Colors.deepPurple.withOpacity(0.3),
                              thumbColor: Colors.deepPurple,
                              overlayColor: Colors.deepPurple.withOpacity(0.2),
                            ),
                            child: Slider(
                              value: _blendIntensity,
                              min: 0.0,
                              max: 1.0,
                              divisions: 50,
                              label: _blendIntensity.toStringAsFixed(2),
                              onChanged: (value) {
                                setState(() {
                                  _blendIntensity = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // 预设颜色组合
                          Text(
                            '预设颜色组合:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildPresetButton('彩虹', [
                                Colors.red,
                                Colors.orange,
                                Colors.yellow,
                                Colors.green,
                                Colors.blue,
                                Colors.indigo,
                                Colors.purple,
                              ]),
                              _buildPresetButton('海洋', [
                                Colors.blue.shade900,
                                Colors.blue.shade700,
                                Colors.cyan.shade500,
                                Colors.teal.shade300,
                              ]),
                              _buildPresetButton('日落', [
                                Colors.orange.shade900,
                                Colors.orange.shade600,
                                Colors.yellow.shade600,
                                Colors.red.shade800,
                              ]),
                              _buildPresetButton('森林', [
                                Colors.green.shade900,
                                Colors.green.shade600,
                                Colors.lightGreen.shade400,
                                Colors.lime.shade300,
                              ]),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 形状展示区域
                  const SizedBox(height: 20),
                  Text(
                    '不同形状效果',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    height: 200,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildShapePreview(BendShapeType.circle, '圆形'),
                        const SizedBox(width: 16),
                        _buildShapePreview(BendShapeType.rectangle, '矩形'),
                        const SizedBox(width: 16),
                        _buildShapePreview(BendShapeType.triangle, '三角形'),
                        const SizedBox(width: 16),
                        _buildShapePreview(BendShapeType.hexagon, '六边形'),
                        const SizedBox(width: 16),
                        _buildShapePreview(BendShapeType.star, '星形'),
                        const SizedBox(width: 16),
                        _buildShapePreview(BendShapeType.wave, '波浪形'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String name, List<Color> colors) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _colors.clear();
          _colors.addAll(colors);
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple.withOpacity(0.1),
        foregroundColor: Colors.deepPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(name),
    );
  }

  Widget _buildShapePreview(BlendShapeType shapeType, String label) {
    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          margin: const EdgeInsets.only(bottom: 8),
          child: ColorBlender(
            colors: _colors.take(3).toList(),
            blendIntensity: _blendIntensity,
            shapeType: shapeType,
            enableAnimation: false,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
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
    }
  }
}