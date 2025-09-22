import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'dart:math' as math;
import 'dart:async';

import 'package:intl/intl.dart';

class InteractiveWheelPieChart extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(String category, dynamic data) onCategorySelected;

  const InteractiveWheelPieChart({
    Key? key,
    required this.userData,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<InteractiveWheelPieChart> createState() => _InteractiveWheelPieChartState();
}

class _InteractiveWheelPieChartState extends State<InteractiveWheelPieChart>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  double _currentRotation = 0.0;
  String _selectedCategory = 'Total';
  bool _isDragging = false;
  Timer? _autoRotateTimer;

  final List<PieChartData> _chartData = [];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _initializeChartData();

    _startAutoRotation();
  }


  void _initializeChartData() {
    final total = widget.userData['total'];
    final onlinePayment = widget.userData['total_online_payment'] ?? 0;
    final cashPayment = widget.userData['total_cash_payment'] ?? 0;
    final totalRevenue = total['revenue'] ?? 0;

    _chartData.addAll([
      PieChartData(
        category: 'Total Revenue',
        value: totalRevenue.toDouble(),
        color: AppColors.primaryColor, // bright green
        icon: FontAwesome5Solid.money_bill_alt, // Revenue icon
        data: {'amount': totalRevenue, 'quantity': total['quantity'] ?? 0, 'type': 'total'},
      ),
      PieChartData(
        category: 'Online Payment',
        value: onlinePayment.toDouble(),
        color: AppColors.secondaryColor, // dark green
        icon: FontAwesome5Solid.credit_card, // online payment
        data: {'amount': onlinePayment, 'type': 'online'},
      ),
      PieChartData(
        category: 'Cash Payment',
        value: cashPayment.toDouble(),
        color: AppColors.fboColor, // oil green
        icon: FontAwesome5Solid.money_check, // cash icon
        data: {'amount': cashPayment, 'type': 'cash'},
      ),
    ]);

    final monthly = widget.userData['monthly'] as List?;
    if (monthly != null && monthly.isNotEmpty) {
      var monthData = monthly[0];
      _chartData.add(PieChartData(
        category: 'Month ${monthData['month']}',
        value: monthData['revenue'].toDouble(),
        color: AppColors.lightGreen, // lighter oil green
        icon: FontAwesome5Solid.calendar_alt, // month icon
        data: monthData,
      ));
    } else {
      final weekly = widget.userData['weekly'] as List?;
      if (weekly != null && weekly.isNotEmpty) {
        var weekData = weekly[0];
        _chartData.add(PieChartData(
          category: 'Week ${weekData['week']}',
          value: weekData['revenue'].toDouble(),
          color: AppColors.primaryGreen, // medium green
          icon: FontAwesome5Solid.calendar_week, // week icon
          data: weekData,
        ));
      } else {
        _chartData.add(PieChartData(
          category: 'Oil Quantity',
          value: (total['quantity'] ?? 0).toDouble(),
          color: AppColors.darkGreen, // dark oil green
          icon: FontAwesome5Solid.oil_can, // oil bottle icon
          data: {'quantity': total['quantity'] ?? 0, 'type': 'quantity'},
        ));
      }
    }
  }



  void _startAutoRotation() {
    _autoRotateTimer?.cancel();
    _autoRotateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isDragging && mounted) {
        _snapToNextCategory();
      }
    });
  }

  void _snapToNextCategory() {
    if (_chartData.isEmpty) return;

    int currentIndex = _chartData.indexWhere((d) => d.category == _selectedCategory);
    int nextIndex = (currentIndex + 1) % _chartData.length;

    double sectionAngle = (math.pi * 2) / _chartData.length;
    double targetAngle = nextIndex * sectionAngle;

    Animation<double> animation = Tween<double>(
      begin: _currentRotation,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOutCubic,
    ));

    animation.addListener(() {
      setState(() {
        _currentRotation = animation.value;
      });
    });

    _rotationController.forward(from: 0).then((_) {
      setState(() {
        _selectedCategory = _chartData[nextIndex].category;
      });
      widget.onCategorySelected(_selectedCategory, _chartData[nextIndex].data);
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _autoRotateTimer?.cancel();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) {
      _isDragging = true;
      _scaleController.forward();
      _autoRotateTimer?.cancel();
    }

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final center = renderBox.size.center(Offset.zero);
    final position = details.localPosition;

    final angle = math.atan2(
      position.dy - center.dy,
      position.dx - center.dx,
    );

    setState(() {
      _currentRotation += (angle - _currentRotation) * 0.1;
    });

    _selectCategoryFromAngle(_currentRotation);
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    _scaleController.reverse();
    _snapToNearestCategory();
    _startAutoRotation();
  }

  void _selectCategoryFromAngle(double angle) {
    if (_chartData.isEmpty) return;

    double normalizedAngle = (angle + math.pi * 2) % (math.pi * 2);
    double sectionAngle = (math.pi * 2) / _chartData.length;

    int selectedIndex =
        ((normalizedAngle + sectionAngle / 2) / sectionAngle).floor() % _chartData.length;

    if (selectedIndex >= 0 && selectedIndex < _chartData.length) {
      final selectedData = _chartData[selectedIndex];
      if (_selectedCategory != selectedData.category) {
        setState(() {
          _selectedCategory = selectedData.category;
        });
        widget.onCategorySelected(selectedData.category, selectedData.data);
      }
    }
  }

  void _snapToNearestCategory() {
    if (_chartData.isEmpty) return;

    double sectionAngle = (math.pi * 2) / _chartData.length;
    double normalizedAngle = (_currentRotation + math.pi * 2) % (math.pi * 2);
    int nearestIndex = (normalizedAngle / sectionAngle).round() % _chartData.length;
    double targetAngle = nearestIndex * sectionAngle;

    Animation<double> animation = Tween<double>(
      begin: _currentRotation,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOutCubic,
    ));

    animation.addListener(() {
      setState(() {
        _currentRotation = animation.value;
      });
    });

    _rotationController.forward(from: 0).then((_) {
      setState(() {
        _selectedCategory = _chartData[nearestIndex].category;
      });
      widget.onCategorySelected(_selectedCategory, _chartData[nearestIndex].data);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sizes relative to screen
    final chartSize = screenWidth * 0.6; // pie chart container
    final centerCircleSize = chartSize * 0.4; // center circle

    return Container(
      width: chartSize,
      height: chartSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: AnimatedBuilder(
              animation: _scaleController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_scaleController.value * 0.1),
                  child: Transform.rotate(
                    angle: _currentRotation,
                    child: CustomPaint(
                      size: Size(chartSize, chartSize),
                      painter: WheelPieChartPainter(
                        data: _chartData,
                        selectedCategory: _selectedCategory,
                        animationValue: _scaleController.value,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            width: centerCircleSize,
            height: centerCircleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.grey[800] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: chartSize * 0.075,
                  spreadRadius: chartSize * 0.015,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getSelectedIcon(),
                  color: _getSelectedColor(),
                  size: centerCircleSize * 0.3, // responsive icon
                ),
                SizedBox(height: centerCircleSize * 0.05),
                Text(
                  _getSelectedLabel(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: centerCircleSize * 0.12, // responsive font
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  IconData _getSelectedIcon() {
    final selectedData = _chartData.firstWhere(
          (data) => data.category == _selectedCategory,
      orElse: () => _chartData.first,
    );

    // Already using FontAwesome5Solid icons from _initializeChartData
    return selectedData.icon;
  }


  Color _getSelectedColor() {
    final selectedData = _chartData.firstWhere(
          (data) => data.category == _selectedCategory,
      orElse: () => _chartData.first,
    );
    return selectedData.color;
  }

  /// Show meaningful label instead of %
  String _getSelectedLabel() {
    final selectedData = _chartData.firstWhere(
          (data) => data.category == _selectedCategory,
      orElse: () => _chartData.first,
    );

    final formatter = NumberFormat.decimalPattern('hi'); // Indian numbering format

    if (selectedData.data.containsKey('amount')) {
      return "₹${formatter.format(selectedData.data['amount'])}";
    } else if (selectedData.data.containsKey('quantity')) {
      return "${formatter.format(selectedData.data['quantity'])} KG";
    } else if (selectedData.data.containsKey('revenue')) {
      return "₹${formatter.format(selectedData.data['revenue'])}";
    } else {
      return selectedData.category;
    }
  }

}

class PieChartData {
  final String category;
  final double value;
  final Color color;
  final IconData icon;
  final Map<String, dynamic> data;

  PieChartData({
    required this.category,
    required this.value,
    required this.color,
    required this.icon,
    required this.data,
  });
}

class WheelPieChartPainter extends CustomPainter {
  final List<PieChartData> data;
  final String selectedCategory;
  final double animationValue; // 0 to 1 for scale effect

  WheelPieChartPainter({
    required this.data,
    required this.selectedCategory,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final thickness = 20.0; // depth of 3D slice
    double startAngle = -math.pi / 2;

    final sectionAngle = (math.pi * 2) / data.length;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];

      // --- Draw bottom shadow layer for depth ---
      final bottomPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.black.withOpacity(0.15),
            Colors.black.withOpacity(0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromCircle(center: center.translate(0, thickness), radius: radius))
        ..style = PaintingStyle.fill;

      final bottomPath = Path()
        ..moveTo(center.dx, center.dy + thickness)
        ..arcTo(
          Rect.fromCircle(center: center.translate(0, thickness), radius: radius),
          startAngle,
          sectionAngle,
          false,
        )
        ..close();

      canvas.drawPath(bottomPath, bottomPaint);

      // --- Top slice with gradient ---
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            item.color,
            item.color.withOpacity(0.7),
          ],
          center: Alignment.center,
          radius: 0.8,
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;

      // Slightly pop out if selected
      final sliceRadius =
      item.category == selectedCategory ? radius + 10 * animationValue : radius;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: sliceRadius), startAngle, sectionAngle, false)
        ..close();

      canvas.drawPath(path, paint);

      // Border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = item.category == selectedCategory ? 3 : 1;

      canvas.drawPath(path, borderPaint);

      startAngle += sectionAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

