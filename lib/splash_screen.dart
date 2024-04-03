import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Authorization/sign_in.dart';
import 'Screens/free_trial.dart';
import 'Screens/home_screen.dart';
import 'Screens/under_verification.dart';
import 'Utils/colors.dart';
import 'Utils/navigator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  checkTrial() {
    DateTime currentDate = DateTime.now();
    DateTime expire1Date = DateTime(2023, 4, 27, 23, 59, 59);

    int currentDuration = currentDate.microsecondsSinceEpoch;
    int expire1Duration = expire1Date.microsecondsSinceEpoch;
    if (currentDuration > expire1Duration) {
      // print('free trial expired');
      Timer(const Duration(milliseconds: 2500), () {
        navRemove(context, const FreeTrail());
      });
    } else {
      timer();
      // print('free trial remaining');
    }
  }

  timer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    if (token == null) {
      Timer(const Duration(milliseconds: 2500), () {
        navRemove(context, const SignInScreen());
      });
    } else {
      var status = prefs.getString('status');

      Timer(const Duration(milliseconds: 2500), () {
        if (status.toString() == 'Approved') {
          navRemove(context, const HomeScreen());
        } else {
          navRemove(context, const UnderVerification());
        }
      });
    }
  }

  // checkStatus() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   var id = prefs.getString('id');
  //   var token = prefs.getString('token');
  //   print("$token\n$id");
  //   Map body = {'id': id.toString()};
  //   try {
  //     http.Response response = await http.post(Uri.parse(findUserURL),
  //         headers: {"Authorization": "Bearer $token"}, body: body);
  //
  //     print(response.body);
  //     Map jsonData = jsonDecode(response.body);
  //     if (jsonData['status'] == 200) {
  //       if (jsonData['user']['status'] == 'Approved') {
  //         navRemove(context, const HomeScreen());
  //       } else {
  //         navRemove(
  //             context, UnderVerification(type: jsonData['user']['status']));
  //       }
  //     }
  //   } catch (e) {
  //     print(e);
  //     navRemove(context, SignInScreen());
  //   }
  // }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // checkTrial();
    timer();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: scaffoldColor,
        body: Stack(
          // fit: StackFit.expand,
          children: [
            Center(
              child: Image.asset(
                'assets/ic_app_logo.png',
                height: 200,
                width: 200,
              ),
            ),
            // Column(
            //   crossAxisAlignment: CrossAxisAlignment.center,
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Image.asset(
            //       'assets/ic_app_logo.png',
            //       height: 120,
            //       width: 120,
            //       fit: BoxFit.cover,
            //     ),
            //     const SizedBox(height: 20),
            //     Text(appName, style: const TextStyle(fontSize: 26)),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}
