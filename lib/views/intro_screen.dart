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
      _goToLogin();
    }
  }

  void _goToLogin() {
    context.go('/start');
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned(
                          top: -screenHeight * 0.18,
                          left: -screenWidth * 0.18,
                          child: Container(
                            width: screenWidth * 1.3,
                            height: screenWidth * 1.3,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF6FA006),
                                  Color.fromRGBO(161, 192, 93, 0.5),
                                ],
                                stops: [0.2116, 0.9588],
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: screenHeight * 0.1),
                            child: Image.asset(
                              slide["image"]!,
                              width: screenWidth * 0.6,
                              height: screenWidth * 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Text(
                    slide["titleTop"]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      color: const Color(0xFF006D04),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    slide["titleBottom"]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      color: const Color(0xFF006D04),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Text(
                      slide["description"]!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
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
                              ? const Color(0xFF6FA006)
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6FA006),
                        minimumSize: Size.fromHeight(screenHeight * 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _currentIndex == _slides.length - 1 ? "Finish" : "Continue",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _goToLogin,
                    child: Text(
                      "Skip",
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
