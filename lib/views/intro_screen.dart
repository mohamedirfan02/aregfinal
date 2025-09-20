import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  int _currentIndex = 0;

  final List<Map<String, String>> _slides = [
    {
      "image": 'assets/image/intro1.png',
      "titleTop": "Transform Waste, Fuel",
      "titleBottom": "Sustainability",
      "description": "Turn your used cooking oil into sustainable biodiesel and fuel a greener tomorrow with every drop",
    },
    {
      "image": 'assets/image/intro2.png',
      "titleTop": "Hassle-Free Oil",
      "titleBottom": "Logistics",
      "description": "A round-the-clock vendor self-service app designed to simplify oil transport operations and elevate service efficiency for business partners.",
    },
    {
      "image": 'assets/image/intro3.png',
      "titleTop": "Greener Future with",
      "titleBottom": "Biodiesel",
      "description": "Turn your used cooking oil into sustainable biodiesel and fuel a greener tomorrow with every drop",
    },
  ];

  void _onNext() {
    if (_currentIndex < _slides.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      context.go('/start');
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    final fontTitle = screenWidth * (isTablet ? 0.045 : 0.05);
    final fontDesc = screenWidth * (isTablet ? 0.032 : 0.037);
    final fontButton = screenWidth * (isTablet ? 0.035 : 0.04);
    //final buttonHeight = screenHeight * 0.06;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // 🟢 Top Section
                      Stack(
                        children: [
                          Container(
                            height: constraints.maxHeight * 0.45,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.white],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Image.asset(
                              'assets/image/cuve.png',
                              width: constraints.maxWidth,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Image.asset(
                                slide["image"]!,
                                width: constraints.maxWidth * 0.6,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 🔤 Titles & Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28.0),
                        child: Column(
                          children: [
                            Text(
                              slide["titleTop"]!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: fontTitle,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            Text(
                              slide["titleBottom"]!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: fontTitle,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              slide["description"]!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: fontDesc,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // 🔘 Pagination + Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _slides.length,
                                    (index) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentIndex == index
                                        ? AppColors.primaryColor
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _onNext,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                minimumSize:
                                Size(double.infinity, screenHeight * 0.06),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _currentIndex == _slides.length - 1
                                    ? "Finish"
                                    : "Continue",
                                style: TextStyle(
                                  fontSize: fontButton,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/start'),
                              child: Text(
                                "Skip",
                                style: TextStyle(
                                  fontSize: fontButton,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),

    );
  }
}
