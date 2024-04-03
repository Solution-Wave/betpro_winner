import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Utils/CheckConnection.dart';
import '../Utils/colors.dart';
import '../Utils/messages.dart';
import '../Utils/navigator.dart';
import '../Utils/offline_ui.dart';
import '../Utils/text.dart';
import '../Utils/themes.dart';
import '../Utils/urls.dart';
import '../components/textStyle.dart';
import '../controllers/get_time_controller.dart';
import 'home_screen.dart';

class Withdraw extends StatefulWidget {
  const Withdraw({Key? key}) : super(key: key);

  @override
  State<Withdraw> createState() => _WithdrawState();
}

class _WithdrawState extends State<Withdraw> {
  TextEditingController amountController = TextEditingController();
  TextEditingController accountController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController remarkController = TextEditingController();

  bool loader = false;
  bool bank = false;
  bool check = false;
  String value = '';
  bool error = false;
  int type = 0;
  bool checkConnection = false;
  var token;
  var BankNo;
  var bp_username;

  var timeCheck= true;
  var Frtime;
  var Totime;
  formValidate() {
    if (amountController.text.isEmpty || amountController.text == '0') {
      showSnackMessage(context, 'Please Enter amount to withdraw');
    }
    if (remarkController.text.isEmpty) {
      showSnackMessage(context, 'Please Enter remark to withdraw');
    } else {
      checkConnectivity();
    }
  }

  checkConnectivity() async {
    if (await connection()) {
      setState(() {
        checkConnection = false;
      });
      confirmDialog();
    } else {
      setState(() {
        checkConnection = true;
      });
    }
  }

  confirmDialog() {
    return showDialog(
      useSafeArea: true,
      barrierDismissible: false,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, StateSetter setState) {
          return AlertDialog(
            title: const Text("Confirmation"),
            titleTextStyle: TextStyle(
                fontSize: 22,
                fontFamily: font_family,
                color: textHeadingColor,
                fontWeight: FontWeight.w500),
            content: const Text("Are you sure to perform this transaction"),
            contentTextStyle: TextStyle(
                fontFamily: font_family, fontSize: 16, color: textLightColor),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                },
                child: Text(
                  "No",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontFamily: font_family,
                      fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  callApi();
                },
                child: Text(
                  "Yes",
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

  Future getBankNo() async {
    try {
      var response = await http.post(
        Uri.parse('$baseURL/get_banks_name'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      var data = jsonDecode(response.body);

      if (data['status'] == 200) {
        data = data['data'];
        for (int i = 0; i < data.length; i++) {
          if (data[i]['category'] == value && data[i]['ac_number'] != null) {
            BankNo = data[i]['ac_number'];
          }
        }
        return int.parse(BankNo);
      } else {
        return 'Some issue occured';
      }
    } catch (e) {
      return "Check internet";
    }
  }

  void getToken()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    print(token);
  }

  callApi() async {
    setState(() {
      loader = true;
    });
    await getBankNo();

    Map body = {
      'payment': amountController.text,
      'payment_method': value,
      'type': '2',
      'account': '.',
      'description': remarkController.text,
    };
    try {
      http.Response response = await http.post(Uri.parse(withdrawRequestURL),
          headers: {"Authorization": "Bearer $token"}, body: body);
      print(response.body);
      Map jsonData = jsonDecode(response.body);
      print(jsonData);

      if (jsonData['status'] == 200) {
        setState(() {
          loader = false;
          amountController.clear();
          accountController.clear();
          titleController.clear();
          remarkController.clear();
          value = '';
          check = false;
        });
        dialog();
      } else {
        setState(() {
          loader = false;
        });
        showSnackMessage(context, jsonData['message']);
      }
    } catch (e) {
      print(e);
      setState(() {
        loader = false;
      });
      showSnackMessage(context, 'Something went wrong');
    }
  }

  dialog() {
    return showDialog(
      useSafeArea: true,
      barrierDismissible: false,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, StateSetter setState) {
          return AlertDialog(
            title: const Text("Success"),
            titleTextStyle: TextStyle(
                fontSize: 22,
                fontFamily: font_family,
                color: textHeadingColor,
                fontWeight: FontWeight.w500),
            content: const Text(
                "Your request is successfully submitted.\nOnce request is approved, desired amount will be deducted from your wallet and send to beneficiary account"),
            contentTextStyle: TextStyle(
                fontFamily: font_family, fontSize: 16, color: textLightColor),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  navRemove(context, const HomeScreen());
                },
                child: Text(
                  "Ok",
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

  void GetTime()async{
    GetTimeController _getTimeController = GetTimeController();
    var responseFromApi = await _getTimeController.getTimeAPiData();
    if(responseFromApi is !String)
      {
        var temp1 = DateFormat.jm().format(DateFormat("hh:mm:ss").parse(responseFromApi['Data'][0]["from_time"]));
        var temp2 = DateFormat.jm().format(DateFormat("hh:mm:ss").parse(responseFromApi['Data'][0]["to_time"]));
       setState(() {
         timeCheck=responseFromApi['isWithinRange'];
         Frtime =  temp1;
         Totime =  temp2;
       });
      }
    else{
      showSnackMessage(context, responseFromApi);
    }

  }

  int balance = 0;
  int showBalance = 0;

  getBalance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      bp_username = prefs.getString('bp_username');
      var bal = prefs.getString('balance');
      print(bal);
      if (bal != null) {
        double bb = double.parse(bal.toString());
        balance = bb.toInt();
        showBalance = balance;
      }
      print('$balance\n$showBalance');
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getBalance();
    getToken();
    GetTime();
  }

  @override
  Widget build(BuildContext context) {
    return checkConnection
        ? OfflineUI(function: checkConnectivity)
        : Scaffold(
            appBar: AppBar(
              // leading: Container(),
              // leadingWidth: 0,
              // elevation: 0,
              foregroundColor: appBarForegroundColorGlobal,
              backgroundColor: primaryColor,
              centerTitle: true,
              title: Text(
                'Withdraw Balance',
                textAlign: TextAlign.center,
                overflow: TextOverflow.clip,
                style: appbarTitleTheme,
              )
              // SizedBox(
              //   child: Row(
              //     children: [
              //       InkWell(
              //           onTap: () {
              //             Navigator.pop(context);
              //           },
              //           child: Icon(
              //             Icons.arrow_back_ios,
              //             size: 22,
              //             color: kWhite,
              //           )),
              //       Expanded(
              //           child: Container(
              //         alignment: Alignment.center,
              //         child: Text(
              //           'Withdraw Balance',
              //           textAlign: TextAlign.center,
              //           overflow: TextOverflow.clip,
              //           style: appbarTitleTheme,
              //         )
              //         // textWidget(
              //         //     'Withdraw Balance',
              //         //     TextAlign.center,
              //         //     1,
              //         //     TextOverflow.clip,
              //         //     18,
              //         //     kWhite,
              //         //     FontWeight.w600,
              //         //     font_family),
              //       ))
              //     ],
              //   ),
              // ),
            ),
            body: loader == true
                ? Center(child: Platform.isAndroid ?
            CircularProgressIndicator( color: primaryColor,):
            CupertinoActivityIndicator(color: primaryColor,),)
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              alignment: Alignment.centerLeft,
                              child: textWidget(
                                  'Bp username',
                                  TextAlign.center,
                                  1,
                                  TextOverflow.clip,
                                  20,
                                  textHeadingColor,
                                  FontWeight.w600,
                                  font_family),
                            ),
                            Text(
                              bp_username ?? '',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: textWidget(
                              'Amount to withdraw',
                              TextAlign.center,
                              1,
                              TextOverflow.clip,
                              14,
                              textHeadingColor,
                              FontWeight.w600,
                              font_family),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          autofocus: false,
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'\d'))
                          ],
                          decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    width: 1,
                                  )),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      width: 1, color: primaryColor)),
                              errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      width: 1, color: primaryColor)),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      width: 1, color: primaryColor)),
                              hintText: "0",
                              isDense: true),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: textWidget(
                              ' Account Details',
                              TextAlign.start,
                              1,
                              TextOverflow.clip,
                              14,
                              textHeadingColor,
                              FontWeight.w600,
                              font_family),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kBlack, width: 1.5)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 12),
                          child: Column(
                            children: [
                              Container(
                                alignment: Alignment.centerLeft,
                                child: textWidget(
                                    'Choose Payment Method',
                                    TextAlign.start,
                                    1,
                                    TextOverflow.clip,
                                    14,
                                    textHeadingColor,
                                    FontWeight.w600,
                                    font_family),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    check = true;
                                    bank = true;
                                    type = 1;
                                    value = 'Bank';
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: kBlack, width: 1)),
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        value == 'Bank'
                                            ? Icons.circle
                                            : Icons.circle_outlined,
                                        color: value == 'Bank'
                                            ? primaryColor
                                            : primaryColor.withOpacity(0.4),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Image.asset(
                                        'assets/bank.png',
                                        width: 45,
                                        height: 45,
                                        fit: BoxFit.fill,
                                      ),
                                      const SizedBox(
                                        width: 6,
                                      ),
                                      textWidget(
                                          'Bank',
                                          TextAlign.start,
                                          1,
                                          TextOverflow.clip,
                                          16,
                                          textHeadingColor,
                                          FontWeight.w600,
                                          font_family),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5.0),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    bank = false;
                                    check = true;
                                    type = 3;
                                    value = 'Jazz Cash';
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: kBlack, width: 1)),
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        value == 'Jazz Cash'
                                            ? Icons.circle
                                            : Icons.circle_outlined,
                                        color: value == 'Jazz Cash'
                                            ? primaryColor
                                            : primaryColor.withOpacity(0.4),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Image.asset(
                                        'assets/jazzcash.png',
                                        width: 50,
                                        height: 50,
                                      ),
                                      const SizedBox(
                                        width: 6,
                                      ),
                                      textWidget(
                                          'Jazz Cash',
                                          TextAlign.start,
                                          1,
                                          TextOverflow.clip,
                                          16,
                                          textHeadingColor,
                                          FontWeight.w600,
                                          font_family),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5.0),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    check = true;
                                    bank = false;
                                    type = 2;
                                    value = 'Easy Paisa';
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: kBlack, width: 1)),
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        value == 'Easy Paisa'
                                            ? Icons.circle
                                            : Icons.circle_outlined,
                                        color: value == 'Easy Paisa'
                                            ? primaryColor
                                            : primaryColor.withOpacity(0.4),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Image.asset(
                                        'assets/easypaisa.png',
                                        width: 35,
                                        height: 35,
                                      ),
                                      const SizedBox(
                                        width: 6,
                                      ),
                                      textWidget(
                                          'Easy Paisa',
                                          TextAlign.start,
                                          1,
                                          TextOverflow.clip,
                                          16,
                                          textHeadingColor,
                                          FontWeight.w600,
                                          font_family),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              // Container(
                              //   alignment: Alignment.centerLeft,
                              //   child: textWidget(
                              //       bank
                              //           ? 'Enter IBN Number'
                              //           : 'Enter Account Number',
                              //       TextAlign.start,
                              //       1,
                              //       TextOverflow.clip,
                              //       14,
                              //       textHeadingColor,
                              //       FontWeight.w600,
                              //       font_family),
                              // ),
                              // TextFormField(
                              //   controller: accountController,
                              //   keyboardType: TextInputType.number,
                              //   decoration: InputDecoration(
                              //       enabledBorder: OutlineInputBorder(
                              //           borderRadius: BorderRadius.circular(8),
                              //           borderSide: const BorderSide(
                              //             width: 1,
                              //           )),
                              //       focusedBorder: OutlineInputBorder(
                              //           borderRadius: BorderRadius.circular(8),
                              //           borderSide: BorderSide(
                              //               width: 1, color: primaryColor)),
                              //       hintText: bank ? "IBN Number" : "Account Number",
                              //       isDense: true),
                              // ),
                              // const SizedBox(
                              //   height: 10,
                              // ),
                              // Container(
                              //   alignment: Alignment.centerLeft,
                              //   child: textWidget(
                              //       'Enter Account Title',
                              //       TextAlign.start,
                              //       1,
                              //       TextOverflow.clip,
                              //       14,
                              //       textHeadingColor,
                              //       FontWeight.w600,
                              //       font_family),
                              // ),
                              // TextFormField(
                              //   controller: titleController,
                              //   keyboardType: TextInputType.text,
                              //   decoration: InputDecoration(
                              //       enabledBorder: OutlineInputBorder(
                              //           borderRadius: BorderRadius.circular(8),
                              //           borderSide: const BorderSide(
                              //             width: 1,
                              //           )),
                              //       focusedBorder: OutlineInputBorder(
                              //           borderRadius: BorderRadius.circular(8),
                              //           borderSide: BorderSide(
                              //               width: 1, color: primaryColor)),
                              //       hintText: "Account Title",
                              //       isDense: true),
                              // ),
                              // const SizedBox(
                              //   height: 10,
                              // ),
                              Container(
                                alignment: Alignment.centerLeft,
                                child: textWidget(
                                    'Enter Account Details',
                                    TextAlign.start,
                                    1,
                                    TextOverflow.clip,
                                    14,
                                    textHeadingColor,
                                    FontWeight.w600,
                                    font_family),
                              ),
                              const SizedBox(height: 6),
                              // TextArea(
                              //   validation: false,
                              //   textEditingController: remarkController,
                              // ),
                              TextFormField(
                                autofocus: false,
                                controller: remarkController,
                                onChanged: (vs) {},
                                maxLines: 5,
                                decoration: InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          width: 1,
                                        )),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            width: 1, color: primaryColor)),
                                    hintText: "Remark",
                                    isDense: true),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        timeCheck ==false? Text(' Withdrawl Time is from $Frtime to $Totime',
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: font_family ,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ): InkWell(
                          onTap: () async{
                            if (check == true && loader == false) {
                              formValidate();
                            } else {
                              print('not validate');
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: (check == true && error == false)
                                  ? primaryColor
                                  : primaryColor.withOpacity(0.4),
                            ),
                            width: MediaQuery.of(context).size.width,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            alignment: Alignment.center,
                            child:
                            textWidget(
                                'WITHDRAW',
                                TextAlign.start,
                                1,
                                TextOverflow.clip,
                                14,
                                (check == true && error == false)
                                    ? kWhite
                                    : kWhite.withOpacity(0.4),
                                FontWeight.w500,
                                font_family),
                          ),
                        )
                      ],
                    ),
                  ),
          );
  }
}
