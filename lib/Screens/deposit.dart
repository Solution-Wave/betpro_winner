import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/BankNameModel.dart';
import '../Utils/CheckConnection.dart';
import '../Utils/colors.dart';
import '../Utils/messages.dart';
import '../Utils/navigator.dart';
import '../Utils/offline_ui.dart';
import '../Utils/text.dart';
import '../Utils/themes.dart';
import '../Utils/urls.dart';
import '../components/desposit_SegmentedView.dart';
import '../components/textStyle.dart';
import 'deposit_amount.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({Key? key}) : super(key: key);

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  bool check = false;
  String dropdownValue = 'Select Payment Method';

  bool loader = false;
  bool checkConnection = false;

  int _index = -1;

  var bank;
  var ac_title;
  var ac_number;
  var bankId;

  List<BankName> list = <BankName>[];
  List<BankName> bankList = <BankName>[];
  List<BankName> easyPaisaList = <BankName>[];
  List<BankName> jazzCashList = <BankName>[];

  nextScreen() {
    navPush(
        context,
        DepositAmountScreen(
          ac_number: ac_number.toString(),
          ac_title: ac_title.toString(),
          bank: bank.toString(),
          bankId: bankId,
        ));
  }

  checkConnectivity() async {
    if (await connection()) {
      setState(() {
        checkConnection = false;
      });
      getBankName();
    } else {
      setState(() {
        checkConnection = true;
      });
    }
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
              ),
            ],
          );
        },
      ),
    );
  }

  getBankName() async {
    setState(() {
      loader = true;
    });
    list.clear();
    bankList.clear();
    easyPaisaList.clear();
    jazzCashList.clear();

    SharedPreferences prefs = await SharedPreferences.getInstance();

    var token = prefs.getString('token');
    try {
      http.Response response = await http.get(
        Uri.parse(getBanksNameURL),
        headers: {"Authorization": "Bearer $token"},
      );

      Map jsonData = jsonDecode(response.body);
      print(jsonData);

      if (jsonData['status'] == 200) {
        for (int i = 0; i < jsonData['data'].length; i++) {
          Map<String, dynamic> obj = jsonData['data'][i];
          BankName pos = BankName();
          pos = BankName.fromJson(obj);
          if (pos.category.toString() == "Bank") {
            bankList.add(pos);
          }
          if (pos.category.toString() == "JazzCash") {
            jazzCashList.add(pos);
          }
          if (pos.category.toString() == "EasyPaisa") {
            easyPaisaList.add(pos);
          }
        }
        print("bankList=${bankList.length}"
            "\njazzcashList=${jazzCashList.length}"
            "\neasyPaisaList=${easyPaisaList.length}");
        setState(() {
          loader = false;
          if (selectedValue == "Bank") {
            print('bank is selected');
            list = List<BankName>.from(bankList);
          }
          if (selectedValue == "EasyPaisa") {
            list = List<BankName>.from(easyPaisaList);
          }
          if (selectedValue == "JazzCash") {
            print('jazzcash is selected');
            list = List<BankName>.from(jazzCashList);
          }
        });
      } else {
        setState(() {
          loader = false;
        });
        showSnackMessage(context, 'No bank data found');
      }
    } catch (e) {
      print(e);
      setState(() {
        loader = false;
      });
      noInternet();
      showSnackMessage(context, 'Something went wrong');
    }
  }

  getList() {
    setState(() {
      for (int i = 0; i < list.length; i++) {
        list[i].value = false;
      }
      bank = '';
      ac_number = '';
      ac_title = '';
      check = false;
    });

    setState(() {
      list.clear();
      if (selectedValue == "Bank") {
        print('bank is selected');
        list = List<BankName>.from(bankList);
      }
      if (selectedValue == "EasyPaisa") {
        list = List<BankName>.from(easyPaisaList);
      }
      if (selectedValue == "JazzCash") {
        print('jazzcash is selected');
        list = List<BankName>.from(jazzCashList);
      }
    });
  }

  void cardTap(int index) {
    setState(() {
      for (int i = 0; i < list.length; i++) {
        list[i].value = false;
      }
      check = true;
      list[index].value = true;
      bank = list[index].name.toString();
      ac_number = list[index].acNumber.toString();
      ac_title = list[index].acTitle.toString();
      bankId = list[index].BankId;
    });

    print(bank);
  }

  @override
  void initState() {
    super.initState();
    getBankName();
  }

  @override
  Widget build(BuildContext context) {
    return checkConnection
        ? OfflineUI(function: checkConnectivity)
        : SafeArea(
        child: Scaffold(
          appBar: AppBar(
              backgroundColor: primaryColor,
              centerTitle: true,
              foregroundColor: appBarForegroundColorGlobal,
              title: Text(
                'Deposit Balance',
                textAlign: TextAlign.center,
                overflow: TextOverflow.clip,
                style: appbarTitleTheme,
              )
          ),
          bottomNavigationBar: InkWell(
            onTap: () {
              if (check) {
                nextScreen();
              }
            },
            child: Container(
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: check ? primaryColor : primaryColor.withOpacity(0.4),
              ),
              margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                  vertical: 2),
              child: textWidget(
                  'TRANSFER',
                  TextAlign.center,
                  2,
                  TextOverflow.clip,
                  16,
                  check ? kWhite : kWhite.withOpacity(0.4),
                  FontWeight.w600,
                  font_family),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.05),
            child: Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                // Container(
                //   alignment: Alignment.centerLeft,
                //   child: InkWell(
                //     onTap: () {
                //       Navigator.pop(context);
                //     },
                //     child: const Icon(Icons.arrow_back_ios, size: 22),
                //   ),
                // ),
                const SizedBox(height: 30),
                Container(
                  alignment: Alignment.centerLeft,
                  child: textWidget(
                      'Select an account',
                      TextAlign.center,
                      2,
                      TextOverflow.clip,
                      18,
                      textHeadingColor,
                      FontWeight.w600,
                      font_family),
                ),
                const SizedBox(height: 8),
                Container(
                  alignment: Alignment.centerLeft,
                  child: textWidget(
                      'Transfer funds on selected account and click Transfer Button',
                      TextAlign.start,
                      2,
                      TextOverflow.clip,
                      14,
                      textLightColor,
                      FontWeight.w500,
                      font_family),
                ),
                const SizedBox(height: 15),
                SegmentedWidget(
                    onChanged: (i) {
                      setState(() {
                        _index = i;
                        if (i == 0) {
                          selectedValue = 'Bank';
                          getBankName();
                        } else if (i == 1) {
                          selectedValue = 'JazzCash';
                          getBankName();
                        } else {
                          selectedValue = 'EasyPaisa';
                          getBankName();
                        }
                      });
                    },
                    index: _index,
                    children: const [
                      Text('Bank'),
                      Text('JazzCash'),
                      Text('EasyPaisa'),
                    ]),
                const SizedBox(height: 15),
                loader
                    ? Center(
                  child: Platform.isAndroid
                      ? CircularProgressIndicator(
                    color: primaryColor,
                  )
                      : CupertinoActivityIndicator(
                    color: primaryColor,
                  ),
                )
                    : list.isEmpty
                    ? Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: const Text('No Bank details are added yet!'),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(
                          top: 8.0, bottom: 8.0),
                      child: InkWell(
                        onTap: () => cardTap(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: list[index].value
                                  ? primaryColor.withOpacity(0.6)
                                  : kWhite,
                              border: Border.all(
                                  width: 1.5,
                                  color: list[index].value
                                      ? primaryColor.withOpacity(0.6)
                                      : kBlack)),
                          child: Column(
                            children: [
                              Container(
                                alignment: Alignment.centerLeft,
                                child: textWidget(
                                    list[index].name.toString(),
                                    TextAlign.start,
                                    2,
                                    TextOverflow.clip,
                                    16,
                                    textHeadingColor,
                                    FontWeight.w600,
                                    font_family),
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              Row(
                                children: [
                                  Container(
                                    alignment: Alignment.center,
                                    child: ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(8),
                                      child: CachedNetworkImage( // Replace FadeInImage with CachedNetworkImage
                                        imageUrl: list[index].iconName.toString(),
                                        placeholder: (context, url) => Image.asset('assets/placeholder.png', width: 55, height: 55),
                                        errorWidget: (context, url, error) => Image.asset('assets/placeholder.png', width: 55, height: 55),
                                        width: 55,
                                        height: 55,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 6,
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 2,
                                        ),
                                        Container(
                                          alignment:
                                          Alignment.centerLeft,
                                          child: textWidget(
                                              'Ac#: ${list[index].acNumber.toString()}',
                                              TextAlign.center,
                                              2,
                                              TextOverflow.clip,
                                              13,
                                              textHeadingColor,
                                              FontWeight.w500,
                                              font_family),
                                        ),
                                        Container(
                                          alignment:
                                          Alignment.centerLeft,
                                          child: textWidget(
                                              'Ac Title: ${list[index].acTitle.toString()}',
                                              TextAlign.center,
                                              2,
                                              TextOverflow.clip,
                                              13,
                                              textHeadingColor,
                                              FontWeight.w500,
                                              font_family),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 2,
                                  ),
                                  InkWell(
                                    onTap: () => cardTap(index),
                                    child: Container(
                                      alignment: Alignment.topCenter,
                                      child: Icon(list[index].value
                                          ? Icons.check_box
                                          : Icons
                                          .check_box_outline_blank_sharp),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
          ),
        ));
  }
  String? selectedValue;
//   final List<String> items = [
//     'Bank',
//     'JazzCash',
//     'EasyPaisa',
//   ];
//

//   List<DropdownMenuItem<String>> _addDividersAfterItems(List<String> items) {
//     List<DropdownMenuItem<String>> menuItems = [];
//     for (var item in items) {
//       menuItems.addAll(
//         [
//           DropdownMenuItem<String>(
//             value: item,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8.0),
//               child: Text(
//                 item,
//                 style: const TextStyle(
//                   fontSize: 14,
//                 ),
//               ),
//             ),
//           ),
//           //If it's last item, we will not add Divider after it.
//           if (item != items.last)
//             const DropdownMenuItem<String>(
//               enabled: false,
//               child: Divider(),
//             ),
//         ],
//       );
//     }
//     return menuItems;
//   }

//   List<double> _getCustomItemsHeights() {
//     List<double> itemsHeights = [];
//     for (var i = 0; i < (items.length * 2) - 1; i++) {
//       if (i.isEven) {
//         itemsHeights.add(40);
//       }
//       //Dividers indexes will be the odd indexes
//       if (i.isOdd) {
//         itemsHeights.add(4);
//       }
//     }
//     return itemsHeights;
//   }
}
