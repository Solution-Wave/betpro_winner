import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../Utils/CheckConnection.dart';
import '../Utils/colors.dart';
import '../Utils/messages.dart';
import '../Utils/offline_ui.dart';
import '../Utils/urls.dart';

class AccountHistory extends StatefulWidget {
  const AccountHistory({Key? key}) : super(key: key);

  @override
  State<AccountHistory> createState() => _AccountHistoryState();
}

class _AccountHistoryState extends State<AccountHistory> {
  GlobalKey<ScaffoldState> key = GlobalKey();
  bool loader = true;
  bool checkConnection = false;
  List transactionHistoryList = [];

  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('id');
    var token = prefs.getString('token');

    Map body = {
      'user_id': id.toString(),
    };
    try {
      http.Response response = await http.post(Uri.parse(transactionHistoryURL),
          headers: {"Authorization": "Bearer $token"}, body: body);
      var jsonData = jsonDecode(response.body);
      print(jsonData);

      if (jsonData['status'] == 200) {
        transactionHistoryList.clear();
        for (int i = 0; i < jsonData['data'].length; i++) {
          var InfoMap = {
            'id': jsonData['data'][i]['id'],
            'type': jsonData['data'][i]['type'],
            'bank': jsonData['data'][i]['bank'],
            'accNo': jsonData['data'][i]['ac_number'],
            'accTitle': jsonData['data'][i]['ac_title'],
            'rupees': jsonData['data'][i]['amount'],
            'balance': jsonData['data'][i]['balance'].toString(),
            'status': jsonData['data'][i]['status'],
            'dateTime': jsonData['data'][i]['date']
          };
          transactionHistoryList.add(InfoMap);
        }
        print(transactionHistoryList);
        setState(() {
          loader = false;
        });
      } else {
        setState(() {
          loader = false;
        });
        // showSnackMessage(context, 'Something went wrong');
      }
    } catch (e) {
      print(e);
      setState(() {
        loader = false;
      });
      // showSnackMessage(context, 'Something went wrong');
    }
  }

  checkConnectivity() async {
    if (await connection()) {
      setState(() {
        checkConnection = false;
      });
      getData();
    } else {
      setState(() {
        checkConnection = true;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkConnectivity();
  }

  Future<void> _refresh() async {
    if (await connection()) {
      setState(() {
        checkConnection = false;
      });
      getData();
      return Future.delayed(const Duration(seconds: 4));
    } else {
      setState(() {
        checkConnection = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return checkConnection
        ? OfflineUI(function: checkConnectivity)
        : SafeArea(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Transaction History'),
                backgroundColor: primaryColor,
                foregroundColor: appBarForegroundColorGlobal,
                elevation: 0,
                leading: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.arrow_back_ios),
                ),
              ),
              body: RefreshIndicator(
                onRefresh: _refresh,
                child: loader
                    ? Center(
                        child: Platform.isAndroid
                            ? CircularProgressIndicator(
                                color: primaryColor,
                              )
                            : CupertinoActivityIndicator(
                                color: primaryColor,
                              ),
                      )
                    : transactionHistoryList.isEmpty
                        ? Container(
                            padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.05),
                            height: 200,
                            alignment: Alignment.center,
                            child: const Text(
                                'You don\'t perform any transaction\n OR \nYour transactions are not approved by the admin'),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.05),
                            shrinkWrap: true,
                            itemCount: transactionHistoryList.length,
                            itemBuilder: (context, index) {
                              return historyView(
                                transactionHistoryList: transactionHistoryList,
                                index: index,
                              );
                            },
                          ),
              ),
            ),
          );
  }
}

class historyView extends StatelessWidget {
  const historyView(
      {super.key, required this.transactionHistoryList, required this.index});
  final index;
  final List transactionHistoryList;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: kWhite,
        border: Border.all(width: 1, color: textHeadingColor),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            alignment: Alignment.center,
            height: 95,
            child: transactionHistoryList[index]['status'] == 'Pending'
                ? Image.asset(
                    'assets/pending.jpg',
                    fit: BoxFit.fill,
                    // color: kBlack,
                    // height: 700,
                  )
                : transactionHistoryList[index]['status'] == 'Approved'
                    ? Image.asset(
                        'assets/successful.jpg',
                        fit: BoxFit.fill,
                        // height: 700,
                      )
                    : transactionHistoryList[index]['status'] == 'Blocked'
                        ? Image.asset(
                            'assets/cancelled.png',
                            fit: BoxFit.fill,
                            // height: 700,
                          )
                        : const SizedBox(),
          ),
          Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 23,
                    width: 23,
                    decoration: BoxDecoration(
                      border: Border.all(width: 1.5, color: kBlack),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      transactionHistoryList[index]['type'] == 'deposit' ||
                              transactionHistoryList[index]['type'] ==
                                  'wallet_withdraw'
                          ? Icons.arrow_upward
                          : Icons.arrow_downward_outlined,
                      size: 15,
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${transactionHistoryList[index]['type']}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Bank: ${transactionHistoryList[index]['bank']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text("Ac#: ${transactionHistoryList[index]['accNo']}",
                          style: const TextStyle(fontSize: 12)),
                      Text(
                          "Ac Title: ${transactionHistoryList[index]['accTitle']}",
                          style: const TextStyle(fontSize: 12)),
                    ],
                  )),
                  const SizedBox(
                    width: 4,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rs. ${transactionHistoryList[index]['rupees']}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                      const SizedBox(height: 6),
                      // Text(
                      //   'Balance:${transactionHistoryList[index]['balance']}',
                      //   style: const TextStyle(
                      //       fontSize: 11),
                      // )
                    ],
                  ),
                ],
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: textLightColor,
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${transactionHistoryList[index]['status']}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color:
                            transactionHistoryList[index]['status'] == 'Pending'
                                ? const Color(0xfff5d6a2)
                                : transactionHistoryList[index]['status'] ==
                                        'Approved'
                                    ? Colors.green
                                    : Colors.red),
                  ),
                  transactionHistoryList[index]['type'] == 'withdraw' &&
                          transactionHistoryList[index]['status'] == 'Approved'
                      ? GestureDetector(
                          onTap: () async {
                            await showDialog(
                                context: context,
                                builder: (constext) => ImageDialog(
                                    transactionHistoryList[index]['id']));
                          },
                          child: Text(
                            'Deposit Slip',
                            style: TextStyle(
                                fontSize: 12, color: Colors.lightBlue[900]),
                          ))
                      : Container(),
                  Text(DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(
                      transactionHistoryList[index]['dateTime']))),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}

class ImageDialog extends StatefulWidget {
  ImageDialog(this.id);
  final String id;

  @override
  State<ImageDialog> createState() => _ImageDialogState();
}

class _ImageDialogState extends State<ImageDialog> {
  File? image;
  //ImageProvider? image;
  bool loader = false;
  @override
  Future getImage() async {
    loader = true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    // generate random number.
    var rng = new Random();
    // get temporary directory of device.
    Directory tempDir = await getTemporaryDirectory();
    // get temporary path from temporary directory.
    String tempPath = tempDir.path;
    // create a new file in temporary path with random file name.
    File file = new File('$tempPath' + (rng.nextInt(100)).toString() + '.png');
    print(widget.id);
    //API CALL
    try {
      var response = await http.post(Uri.parse(depositSlipURL),
          headers: {"Authorization": "Bearer $token"},
          body: {'source_id': widget.id});

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          image = File(file.path);
          // image = Image.memory(response.bodyBytes).image;
          // the above would be used to get image in an imageProvider object
          loader = false;
        });
      } else {
        var data = jsonDecode(response.body);
        print(response.statusCode);
        showSnackMessage(context, data['message']);
      }
    } catch (e) {
      print(e);
    }
  }

  void SaveImage() async {
    var imageBytes = await image!.readAsBytes();
    final result = await ImageGallerySaver.saveImage(imageBytes);
    if (result['isSuccess'] == true) {
      showSnackMessage(context, 'Deposit Slip downloaded');
    } else {
      showSnackMessage(context, 'Failed to save the image');
    }
  }

  void initState() {
    // TODO: implement initState
    super.initState();
    getImage();
  }

  Widget build(BuildContext context) {
    return Dialog(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            //width: MediaQuery.of(context).size.width * 2.0,
            height: MediaQuery.of(context).size.height * 0.50,
            child: loader == true
                ? Center(
                    child: CircularProgressIndicator(
                    color: primaryColor,
                  ))
                : image == null
                    ? Image(image: AssetImage('assets/placeholder.png'))
                    : //Image(image: image!)
                    Image(
                        fit: BoxFit.contain,
                        image: FileImage(image!),
                      )),
        TextButton(
            onPressed: () async {
              // image != null? print('image not null'):print('image null');
              // await Permission.storage.request();
              if (Platform.isAndroid) {
                print('this is android side');
                PermissionStatus permission_Result =
                    await Permission.storage.status;
                PermissionStatus permissionResult =
                    await Permission.photos.status;
                if (permission_Result == PermissionStatus.granted ||
                    permissionResult == PermissionStatus.granted) {
                  SaveImage();
                } else {
                  await Permission.storage.request();
                  await Permission.photos.request();
                }
              } else if (Platform.isIOS) {
                print('this is ios side');
                PermissionStatus permissionResult =
                    await Permission.photos.status;
                print(permissionResult);
                switch (permissionResult) {
                  case PermissionStatus.granted:
                    SaveImage();
                    break;
                  case PermissionStatus.limited:
                    SaveImage();
                    break;
                  case PermissionStatus.restricted:
                    SaveImage();
                    break;
                  case PermissionStatus.permanentlyDenied:
                    showSnackMessage(
                        context, 'Give permission to download your receipt!');
                    await openAppSettings();
                    break;
                  case PermissionStatus.denied:
                    await Permission.photos.request();
                    break;
                  case PermissionStatus.provisional:
                    // TODO: Handle this case.
                }
              }
            },
            child: Text('Download Deposit Slip'))
      ],
    ));
  }
}
