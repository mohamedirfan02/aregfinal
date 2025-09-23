import 'package:flutter/material.dart';

import 'app_colors.dart';

class CustomHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double screenWidth;
  

  const CustomHomeAppBar({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:AppColors.fboColor,
      elevation: 0,
      leading: Padding(
        padding: EdgeInsets.only(left: screenWidth * 0.04), // ✅ Add spacing
         child: IconButton(
          icon: Image.asset(
            "assets/icon/back.png", // ✅ Custom back button image
            width: 24,
            height: 24,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.maybePop(context); // ✅ Prevents multiple pop calls
            }
          },
        ),
      ),
      // actions: [
      //   Padding(
      //     padding: EdgeInsets.only(right: screenWidth * 0.04), // ✅ Add spacing
      //     child: Row(
      //       children: [
      //         IconButton(
      //           icon: Image.asset("assets/icon/cart.png", width: 24, height: 24),
      //           onPressed: () {},
      //         ),
      //         SizedBox(width: 10), // ✅ Space between cart and bell
      //         IconButton(
      //           icon: Image.asset("assets/icon/bell.png", width: 24, height: 24),
      //           onPressed: () {},
      //         ),
      //       ],
      //     ),
      //   ),
      // ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight); // ✅ Fixed AppBar height
}
