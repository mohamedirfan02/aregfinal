import 'dart:typed_data';
import 'package:flutter/material.dart';

class Heading extends StatefulWidget {
  final String imagePath;
  final String text1;
  final String text2;
  final bool isNewUser; // New parameter to check if user is new

  const Heading({
    super.key,
    required this.imagePath,
    required this.text1,
    required this.text2,
    this.isNewUser = false, // Default value set to false
  });

  @override
  State<Heading> createState() => _HeadingState();
}

class _HeadingState extends State<Heading> {
  Uint8List? get decodedBytes => null;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          child: Row(
            children: [
              // Conditional to show the avatar image if the user is new
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: widget.isNewUser
                    ? Center(
                  child: Icon(
                    Icons.person, // Default avatar icon
                    size: 30,
                    color: Colors.grey, // Placeholder color
                  ),
                )
                    : ClipOval(child: _buildProfileImage(widget.imagePath)),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.text1,
                      style: const TextStyle(
                          fontFamily: "Nunito",
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 17),
                    ),
                    Text(
                      widget.text2,
                      style: const TextStyle(
                          fontFamily: "Nunito",
                          color:Color(0xFF504E5F),
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Image.asset(
        'assets/images/profile.png',
        fit: BoxFit.cover,
        width: 50,
        height: 50,
      );
    } else {
      try {
        // final decodedBytes = base64Decode(imagePath.split(',').last);
        return Image.memory(
          decodedBytes!,
          fit: BoxFit.cover,
          width: 50,
          height: 50,
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return Image.asset(
          'assets/images/profile.png',
          fit: BoxFit.cover,
          width: 50,
          height: 50,
        );
      }
    }
  }
}
