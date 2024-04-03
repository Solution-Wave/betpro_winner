import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Authorization/sign_in.dart';
import '../Utils/CheckConnection.dart';
import '../Utils/colors.dart';
import '../Utils/constants.dart';
import '../Utils/messages.dart';
import '../Utils/navigator.dart';
import '../Utils/offline_ui.dart';
import '../Utils/text.dart';
import '../Utils/urls.dart';
import '../components/app_bar.dart';
import '../components/textStyle.dart';
import 'home_screen.dart';

class UnderVerification extends StatefulWidget {
  const UnderVerification({Key? key}) : super(key: key);

  @override
  State<UnderVerification> createState() => _UnderVerificationState();
}

class _UnderVerificationState extends State<UnderVerification> {
  bool checkConnection = false;

  accountDeleted() {
    return showDialog(
      useSafeArea: true,
      barrierDismissible: false,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, StateSetter setState) {
          return AlertDialog(
            title: const Text("Alert"),
            titleTextStyle: TextStyle(
                fontSize: 22,
                fontFamily: font_family,
                color: textHeadingColor,
                fontWeight: FontWeight.w500),
            content: const Text(
                "Your account has been deleted\nFor further detail contact Admin"),
            contentTextStyle: TextStyle(
                fontFamily: font_family, fontSize: 16, color: textLightColor),
          );
        },
      ),
    );
  }

  noInternet() {
    return showDialog(
      useSafeArea: true,
      barrierDismissible: false,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, StateSetter setState) {
          return AlertDialog(
            title: const Text("Connection Failed"),
            titleTextStyle: TextStyle(
                fontSize: 22,
                fontFamily: font_family,
                color: textHeadingColor,
                fontWeight: FontWeight.w500),
            content: const Text(
                "Failed to host lookup\nIt seems due to weak/no internet connection"),
            contentTextStyle: TextStyle(
                fontFamily: font_family, fontSize: 16, color: textLightColor),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  checkConnectivity();
                },
                child: Text(
                  "Retry",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontFamily: font_family,
                      fontSize: 16),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  checkConnectivity() async {
    if (await connection()) {
      setState(() {
        checkConnection = false;
      });
      checkStatus();
    } else {
      setState(() {
        checkConnection = true;
      });
    }
  }

  Future<void> _refresh() async {
    checkStatus();
    return Future.delayed(const Duration(seconds: 4));
  }

  var status;
  bool loader = true;

  checkStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('id');
    var token = prefs.getString('token');

    Map body = {'id': id.toString()};
    try {
      http.Response response = await http.post(Uri.parse(findUserURL),
          headers: {"Authorization": "Bearer $token"}, body: body);

      Map jsonData = jsonDecode(response.body);
      if (jsonData['status'] == 200) {
        if (jsonData['user']['status'] == 'Approved') {
          showSnackMessage(
              context, "Congratulation:\nyou are approved by admin");
          navRemove(context, const HomeScreen());
        } else {
          setState(() {
            status = jsonData['user']['status'];
          });
          prefs.setString('status', status.toString());
        }
      } else {
        setState(() {
          loader=false;
        });
        accountDeleted();
        Timer(const Duration(seconds: 7), () {
          navRemove(context, const SignInScreen());
        });
      }
    } catch (e) {
      noInternet();
    }
    setState(() {
      loader = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    return checkConnection
        ? OfflineUI(function: checkConnectivity)
        : Scaffold(
            // backgroundColor: Colors.red,
            appBar: appBar(
              context,
              'User Profile',
            ),
            body: loader
                ?  Center(child: CircularProgressIndicator(color: primaryColor,))
                : RefreshIndicator(
                    onRefresh: _refresh,
                    semanticsLabel: "Pull to refresh",
                    displacement: 10,
                    semanticsValue: 'pull ',
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                          vertical: 25),
                      // mainAxisAlignment: MainAxisAlignment.start,
                      // crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.12,
                        ),
                        Image.asset(
                          'assets/patience.png',
                          height: MediaQuery.of(context).size.height *0.2,
                          width: MediaQuery.of(context).size.width *0.2,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            textWidget(
                                'Status:',
                                TextAlign.center,
                                2,
                                TextOverflow.clip,
                                MediaQuery.of(context).size.width *0.04,
                                textLightColor,
                                FontWeight.w500,
                                font_family),
                            const SizedBox(
                              width: 60,
                            ),
                            textWidget(
                                status.toString(),
                                TextAlign.center,
                                2,
                                TextOverflow.clip,
                                MediaQuery.of(context).size.width *0.04,
                                Colors.red,
                                FontWeight.w500,
                                font_family)
                          ],
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Container(
                            alignment: Alignment.center,
                            child: textWidget(
                                lblUnderVerificationTitle,
                                TextAlign.center,
                                3,
                                TextOverflow.clip,
                                MediaQuery.of(context).size.width *0.04,
                                textLightColor,
                                FontWeight.w500,
                                font_family)),
                        const SizedBox(
                          height: 10,
                        ),
                        Container(
                            alignment: Alignment.center,
                            child: textWidget(
                                lblUnderVerificationSubtitle,
                                TextAlign.center,
                                3,
                                TextOverflow.clip,
                                MediaQuery.of(context).size.width *0.04,
                                textLightColor,
                                FontWeight.w500,
                                font_family)),
                                
                        const SizedBox(
                          height: 10,
                        ),
                        Container(
                            alignment: Alignment.center,
                            child: textWidget(
                                lblUnderVerificationTitleUrdu,
                                TextAlign.center,
                                3,
                                TextOverflow.clip,
                                MediaQuery.of(context).size.width *0.04,
                                textLightColor,
                                FontWeight.w500,
                                font_family,
                                
                                )),
                                        
                        const SizedBox(
                          height: 10,
                        ),
                        Container(
                            alignment: Alignment.center,
                            child: textWidget(
                                lblUnderVerificationSubtitleUrdu,
                                TextAlign.center,
                                3,
                                TextOverflow.clip,
                                MediaQuery.of(context).size.width *0.04,
                                textLightColor,
                                FontWeight.w500,
                                font_family,
                                
                                )),
                                
                      ],
                    ),
                  ),
          );
  }
}
