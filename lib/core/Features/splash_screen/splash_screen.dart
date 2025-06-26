import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xmasfriend/core/Features/home/views/home_screen.dart';
import 'package:xmasfriend/core/Features/home/widgets/common_text_widget.dart';
import 'package:xmasfriend/core/constants/app_assets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    Timer(Duration(milliseconds: 1250), () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(),)),);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image(image: AssetImage(AppAssets.appLogo)),

          CommonTextWidget(title: 'X-Mas Friend Picker', fontSize: 24, color: Colors.black)
        ],
      ),
    );
  }
}
