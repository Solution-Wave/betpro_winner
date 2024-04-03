import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Authorization/sign_in.dart';
import '../Screens/start_page.dart';

import 'package:url_launcher/url_launcher.dart';

import '../Utils/CheckConnection.dart';
import '../Utils/colors.dart';
import '../Utils/constants.dart';
import '../Utils/drawer.dart';
import '../Utils/messages.dart';
import '../Utils/navigator.dart';
import '../Utils/offline_ui.dart';
import '../Utils/text.dart';
import '../Utils/themes.dart';
import '../Utils/urls.dart';
import '../components/textStyle.dart';
import '../controllers/get_time_controller.dart';
import '../controllers/whatsapp.dart';
import 'account_history.dart';
import 'deposit.dart';
import 'under_verification.dart';
import 'withdraw.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GlobalKey<ScaffoldState> key = GlobalKey();

  bool loader = true;
  bool checkConnection = false;

  Whatsapp whatsappController = Whatsapp();

  var name;
  var email;
  var phone;
  var bp_username;
  var bp_password;

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

  getUserProfile(bool check) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('id');
    var token = prefs.getString('token');
    Map body = {
      'id': id.toString(),
    };
    try {
      http.Response response = await http.post(Uri.parse(findUserURL),
          headers: {"Authorization": "Bearer $token"}, body: body);
      Map jsonData = jsonDecode(response.body);

      if (jsonData['status'] == 200) {
        if (jsonData['user']['status'] == "Approved") {
          setState(() {
            name = jsonData['user']['name'];
            email = jsonData['user']['email'];
            phone = jsonData['user']['phone'];
            bp_username = jsonData['user']['bp_username'];
            bp_password = jsonData['user']['bp_password'];
            loader = false;
          });
          prefs.setString('bp_username', bp_username ?? '');
          prefs.setString('balance', jsonData['user']['balance']);
          prefs.setString('status', jsonData['user']['status']);
        } else {
          setState(() {
            loader = false;
          });
          showSnackMessage(context,
              "Oh no!\nYour status has been changed by admin to ${jsonData['user']['status']}");
          navRemove(context, const UnderVerification());
        }
      } else {
        setState(() {
          loader = false;
        });
        // showSnackMessage(context, 'status code changed in api server');
        prefs.clear();
        accountDeleted();
        Timer(const Duration(seconds: 7), () {
          navRemove(context, const SignInScreen());
        });
      }
    } catch (e) {
      setState(() {
        loader = false;
      });
      // showSnackMessage(context, 'Something went wrong');
      noInternet();
    }
  }

  checkConnectivity() async {
    if (await connection()) {
      setState(() {
        checkConnection = false;
      });
      getUserProfile(true);
    } else {
      setState(() {
        checkConnection = true;
      });
    }
  }

  Future<void> _refresh() async {
    getUserProfile(true);
    return Future.delayed(const Duration(seconds: 4));
  }

  void GetwhatsappNumber()async{
    GetTimeController _getTimeController = GetTimeController();
    var responseFromApi = await _getTimeController.getTimeAPiData();
    if(responseFromApi is !String ){
      print(responseFromApi['Data'][0]["whatsapp_no"]);
      whatsappController.updateContact(responseFromApi['Data'][0]["whatsapp_no"]);
    } else{
      showSnackMessage(context, responseFromApi);
    }
  }

  @override
  void initState() {

    super.initState();
    GetwhatsappNumber();
    getUserProfile(false);

  }
  @override
  Widget build(BuildContext context) {
    var platform = Theme.of(context).platform;
    
    return checkConnection
        ? OfflineUI(function: checkConnectivity)
        : Scaffold(
            backgroundColor: scaffoldColor,
            key: key,
            endDrawer: const DrawerScreen(),
            bottomNavigationBar: navBar(),
            floatingActionButton: IconButton(
                onPressed: () {
                  whatsappController.redirect(platform, context);
                  // navPush(context, LiveChatScreen(link:chatLink));
                },
                icon: Container(
                  height: 25,
                  decoration: const BoxDecoration(
                      color: Color(0xFF31B946),
                      borderRadius: BorderRadius.all(Radius.circular(4))
                  ),
                  child: Image.asset(
                      'assets/whatsapp.png',
                      fit: BoxFit.scaleDown
                  ),
                ),
              // iconSize: MediaQuery.of(context).size.width >950? MediaQuery.of(context).size.width * 0.04:null,
            ),
            appBar: AppBar(
              title: FittedBox(
                fit: BoxFit.scaleDown,
                  child:  Text('BetPro Winner', style: appbarTitleTheme)),
              centerTitle: true,
              foregroundColor: appBarForegroundColorGlobal,
              titleTextStyle: TextStyle(fontFamily: font_family, fontSize: 20),
              backgroundColor: primaryColor,
              leading: Container(),
              elevation: 0,
              actions: [
                Container(
                  padding: const EdgeInsets.all(10),
                  child: InkWell(
                    onTap: () {
                      key.currentState!.openEndDrawer();
                    },
                    child: const Icon(Icons.menu),
                  ),
                )
              ],
            ),
            body: loader
                ?  Center(
                    child: Platform.isAndroid ?
                    CircularProgressIndicator( color: primaryColor,):
                        CupertinoActivityIndicator(color: primaryColor,),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                          vertical: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            // height: MediaQuery.of(context).size.height * 0.12,
                            height: 10,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width<400?  MediaQuery.of(context).size.width*0.9:null,
                            height: MediaQuery.of(context).size.width<400 ? MediaQuery.of(context).size.height*0.25: null,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: textFieldBackgroundColor,
                            ),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 20),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 20),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        alignment: Alignment.topLeft,
                                        child: textWidget(
                                            lblHomeName,
                                            TextAlign.center,
                                            2,
                                            TextOverflow.clip,
                                            16 *MediaQuery.of(context).textScaleFactor,
                                            textLightColor,
                                            FontWeight.w500,
                                            font_family),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child: Container(
                                          alignment: Alignment.centerRight,
                                          child: textWidget(
                                              name.toString(),
                                              TextAlign.center,
                                              2,
                                              TextOverflow.clip,
                                              15*MediaQuery.of(context).textScaleFactor,
                                              textLightColor,
                                              FontWeight.w600,
                                              font_family),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  Container(
                                    height: 1.4,
                                    width: double.infinity,
                                    color: textFieldBackgroundColor,
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        alignment: Alignment.topLeft,
                                        child: textWidget(
                                            'Betpro id',
                                            TextAlign.center,
                                            2,
                                            TextOverflow.clip,
                                            16*MediaQuery.of(context).textScaleFactor,
                                            textLightColor,
                                            FontWeight.w500,
                                            font_family),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child: Container(
                                          alignment: Alignment.centerRight,
                                          child: textWidget(
                                              bp_username == null
                                                  ? ''
                                                  : bp_username.toString(),
                                              TextAlign.center,
                                              2,
                                              TextOverflow.clip,
                                              15*MediaQuery.of(context).textScaleFactor,
                                              textLightColor,
                                              FontWeight.w600,
                                              font_family),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  Container(
                                    height: 1.4,
                                    width: double.infinity,
                                    color: textFieldBackgroundColor,
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        alignment: Alignment.topLeft,
                                        child: textWidget(
                                            'Betpro Password',
                                            TextAlign.center,
                                            2,
                                            TextOverflow.clip,
                                            16*MediaQuery.of(context).textScaleFactor,
                                            textLightColor,
                                            FontWeight.w500,
                                            font_family),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child: Container(
                                          alignment: Alignment.centerRight,
                                          child: textWidget(
                                              bp_password == null
                                                  ? ''
                                                  : bp_password.toString(),
                                              TextAlign.center,
                                              2,
                                              TextOverflow.clip,
                                              15*MediaQuery.of(context).textScaleFactor,
                                              textLightColor,
                                              FontWeight.w600,
                                              font_family),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // const SizedBox(
                                  //   height: 15,
                                  // ),
                                  // Container(
                                  //   height: 1.4,
                                  //   width: double.infinity,
                                  //   color: textFieldBackgroundColor,
                                  // ),
                                  // const SizedBox(
                                  //   height: 15,
                                  // ),

                                  // Row(
                                  //   mainAxisAlignment: MainAxisAlignment.start,
                                  //   crossAxisAlignment: CrossAxisAlignment.start,
                                  //   children: [
                                  //     Container(
                                  //       alignment: Alignment.topLeft,
                                  //       child: textWidget(
                                  //           lblHomePhone,
                                  //           TextAlign.center,
                                  //           2,
                                  //           TextOverflow.clip,
                                  //           16*MediaQuery.of(context).textScaleFactor,
                                  //           textLightColor,
                                  //           FontWeight.w500,
                                  //           font_family),
                                  //     ),
                                  //     const SizedBox(
                                  //       width: 25,
                                  //     ),
                                  //     Expanded(
                                  //       child: Container(
                                  //         alignment: Alignment.centerRight,
                                  //         child: textWidget(
                                  //             phone.toString(),
                                  //             TextAlign.center,
                                  //             2,
                                  //             TextOverflow.clip,
                                  //             15*MediaQuery.of(context).textScaleFactor,
                                  //             textLightColor,
                                  //             FontWeight.w600,
                                  //             font_family),
                                  //       ),
                                  //     ),
                                  //   ],
                                  // ),
                                  // const SizedBox(
                                  //   height: 15,
                                  // ),
                                  // Container(
                                  //   height: 1.4,
                                  //   width: double.infinity,
                                  //   color: textFieldBackgroundColor,
                                  // ),
                                  // const SizedBox(
                                  //   height: 15,
                                  // ),
                                  // Row(
                                  //   mainAxisAlignment: MainAxisAlignment.start,
                                  //   crossAxisAlignment: CrossAxisAlignment.start,
                                  //   children: [
                                  //     Container(
                                  //       alignment: Alignment.topLeft,
                                  //       child: textWidget(
                                  //           lblHomeEmail,
                                  //           TextAlign.center,
                                  //           2,
                                  //           TextOverflow.clip,
                                  //           16*MediaQuery.of(context).textScaleFactor,
                                  //           textLightColor,
                                  //           FontWeight.w500,
                                  //           font_family),
                                  //     ),
                                  //     const SizedBox(
                                  //       width: 35,
                                  //     ),
                                  //     Expanded(
                                  //       child: Container(
                                  //         alignment: Alignment.centerRight,
                                  //         child: textWidget(
                                  //             email.toString(),
                                  //             TextAlign.center,
                                  //             3,
                                  //             TextOverflow.ellipsis,
                                  //             15*MediaQuery.of(context).textScaleFactor,
                                  //             textLightColor,
                                  //             FontWeight.w600,
                                  //             font_family),
                                  //       ),
                                  //     ),
                                  //   ],
                                  // ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  // Container(
                                  //   height: 1.4,
                                  //   width: double.infinity,
                                  //   color: textFieldBackgroundColor,
                                  // ),
                                  // const SizedBox(
                                  //   height: 15,
                                  // ),
                                  // Row(
                                  //   mainAxisAlignment: MainAxisAlignment.start,
                                  //   crossAxisAlignment: CrossAxisAlignment.start,
                                  //   children: [
                                  //     Container(
                                  //       alignment: Alignment.topLeft,
                                  //       child: textWidget(
                                  //           lblHomeBalance,
                                  //           TextAlign.center,
                                  //           2,
                                  //           TextOverflow.clip,
                                  //           16,
                                  //           textLightColor,
                                  //           FontWeight.w500,
                                  //           font_family),
                                  //     ),
                                  //     const SizedBox(
                                  //       width: 35,
                                  //     ),
                                  //     Expanded(
                                  //       child: Container(
                                  //         alignment: Alignment.centerRight,
                                  //         child: textWidget(
                                  //             "Rs:$balance",
                                  //             TextAlign.center,
                                  //             2,
                                  //             TextOverflow.ellipsis,
                                  //             15,
                                  //             textLightColor,
                                  //             FontWeight.w600,
                                  //             font_family),
                                  //       ),
                                  //     ),
                                  //   ],
                                  // ),
                                  // const SizedBox(
                                  //   height: 10,
                                  // ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          InkWell(
                            onTap: () {
                              navPush(context, const AccountHistory());
                            },
                            child: Container(
                              // height: MediaQuery.of(context).size.height*0.1,
                              constraints: BoxConstraints(
                                minWidth: MediaQuery.of(context).size.width*0.8,
                                maxHeight: MediaQuery.of(context).size.height*0.07,
                              ),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: primaryColor),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: textWidget(
                                    'View History',
                                    TextAlign.center,
                                    2,
                                    TextOverflow.clip,
                                    16,
                                    kWhite,
                                    FontWeight.w600,
                                    font_family),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
          );
  }
}

class navBar extends StatelessWidget {
  const navBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      selectedItemColor: Colors.blueGrey,
        selectedFontSize: 11.0,
        items: [
          BottomNavigationBarItem(
            icon: IconButton(
              onPressed: () {
                navPush(context, const Withdraw());
              },
              icon: const Icon(
                Icons.credit_card ,
                // size: MediaQuery.of(context).size.width*0.08,
                color: Colors.blueGrey,
              )
          ),
          label: 'Withdraw'
          ),
          BottomNavigationBarItem(
              icon: IconButton(
              onPressed: () {
                navPush(context, const DepositScreen());
              },
              icon:  const Icon(
                //deposit
                Icons.wallet,
                // size: MediaQuery.of(context).size.width * 0.08,
                semanticLabel: 'Deposit',
                color: Colors.blueGrey,
              )
          ),
            label: 'Deposit'
          ),
          BottomNavigationBarItem(
              icon:  IconButton(
                  onPressed: () {
                    navPush(context, LinkScreen(link: linkUrl));
                  },
                  icon:  const Icon(
                    Icons.link,
                    // size: MediaQuery.of(context).size.width*0.08,
                    color: Colors.blueGrey,
                  )),
            label: 'Betro Login'
          )
        ]
    );


      Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Container(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    onPressed: () {
                      navPush(context, const Withdraw());
                    },
                    icon: Icon(
                     Icons.credit_card ,
                      size: MediaQuery.of(context).size.width*0.08,
                      color: Colors.blueGrey,
                    )
                  ),
                   SizedBox(height: MediaQuery.of(context).size.height *0.007,),
                   Text(
                    'Withdraw',
                    style: homeIconTitleTheme.copyWith(fontSize: 13*MediaQuery.of(context).textScaleFactor, )
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                      onPressed: () {
                        navPush(context, const DepositScreen());
                      },
                      icon:  Icon(
                        //deposit
                        Icons.wallet,
                        size: MediaQuery.of(context).size.width * 0.08,
                        semanticLabel: 'Deposit',
                        color: Colors.blueGrey,
                      )
                  ),
                       SizedBox(height: MediaQuery.of(context).size.height *0.007,),
                   Text(
                    'Deposit',
                    style: homeIconTitleTheme.copyWith(fontSize: MediaQuery.of(context).size.width*0.03),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                      onPressed: () {
                        navPush(context, LinkScreen(link: linkUrl));
                      },
                      icon:  Icon(
                        Icons.link,
                        size: MediaQuery.of(context).size.width*0.08,
                        color: Colors.blueGrey,
                      )),
                     SizedBox(height: MediaQuery.of(context).size.height *0.007,),
                   Text(
                    'Betpro Login',
                    style: homeIconTitleTheme.copyWith(fontSize: MediaQuery.of(context).size.width*0.03),
                  ),
                ],
              ),
            ]),
      ),
    );
  }
}
