import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Utils/CheckConnection.dart';
import '../Utils/colors.dart';
import '../Utils/messages.dart';
import '../Utils/navigator.dart';
import '../Utils/offline_ui.dart';
import '../Utils/text.dart';
import '../Utils/urls.dart';
import 'package:permission_handler/permission_handler.dart';

import '../components/textStyle.dart';
import 'home_screen.dart';

class TransferFunds extends StatefulWidget {
  const TransferFunds({
    Key? key,
    required this.bank,
    required this.ac_number,
    required this.ac_title,
    required this.amount,
    required this.id,
  }) : super(key: key);

  final String bank;

  final String ac_number;

  final String ac_title;

  final String amount;

  final String id;

  @override
  State<TransferFunds> createState() => _TransferFundsState();
}

class _TransferFundsState extends State<TransferFunds> {
  File? image;
  bool loader = false;
  bool checkConnection = false;

  Future pickImage() async {
    print('picking image from gallery');
    try {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (img == null) return;
      final imagePermanent = File(img.path);
      setState(() {
        image = imagePermanent;
      });
    } catch (e) {
      print(e);
      debugPrint(e.toString());
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
                  saveData();
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

  saveData() async {
    setState(() {
      loader = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    // Map body = {
    //   'user_id':id.toString(),
    //   'type':'deposit',
    //   'bank':widget.bank,
    //   'ac_number':widget.ac_number,
    //   'ac_title':widget.ac_title,
    //   'amount':widget.amount,
    //   'image_proof':image,
    //   'remark':'',
    // };
    try {
      http.MultipartRequest request =
          http.MultipartRequest('POST', Uri.parse(depositRequestURL));

      var headers = {"Authorization": "Bearer $token"};

      // request.fields['user_id'] = id.toString();

      request.fields['reciept'] = widget.amount;
      request.fields['payment_method'] = widget.bank;
      request.fields['account'] = widget.ac_number;
      request.fields['type'] = '1';
      request.fields['bank_id'] = widget.id; //add bank id
      // request.fields['ac_title'] = widget.ac_title;
      // request.fields['remark'] = '';
      request.files.add(
          await http.MultipartFile.fromPath('file', '${image!.absolute.path}'));

      request.headers.addAll(headers);
      request.send().then((response) {
        print(response.toString());
        print(response.request);
        print(response.statusCode.toString());
        if (response.statusCode == 200) {
          print("Uploaded files");
          showSnackMessage(context, "Request submitted successfully");
          Timer(const Duration(seconds: 1), () {
            navRemove(context, const HomeScreen());
          });
        } else {
          setState(() {
            loader = false;
          });
          print("Not uploaded");
          showSnackMessage(context, "Something went wrong!");
        }
      });
    } catch (e) {
      print(e);
      setState(() {
        loader = false;
      });
      print("SomeThing went wront");
      showSnackMessage(context, "Something went wrong!");
    }
  }

  copyToClipBoard(String text) {
    print(text.toString());
    showSnackMessage(context, 'copied...');
  }

  @override
  Widget build(BuildContext context) {
    return checkConnection
        ? OfflineUI(function: checkConnectivity)
        : SafeArea(
            child: Scaffold(
            body: loader
                ? Center(
                    child: Platform.isAndroid ?
                    CircularProgressIndicator( color: primaryColor,):
                    CupertinoActivityIndicator(color: primaryColor,),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                        vertical: 10),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 4,
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            alignment: Alignment.centerLeft,
                            child: const Icon(
                              Icons.arrow_back_ios,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: textWidget(
                              'Transfer Funds',
                              TextAlign.center,
                              2,
                              TextOverflow.clip,
                              18,
                              textHeadingColor,
                              FontWeight.w600,
                              font_family),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: textWidget(
                              'Transfer Rs. ${widget.amount} on below account, attach payment proof and click submit',
                              TextAlign.start,
                              3,
                              TextOverflow.clip,
                              14,
                              kRed,
                              FontWeight.w600,
                              font_family),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(width: 1.5, color: kBlack)),
                          child: Column(
                            children: [
                              Container(
                                alignment: Alignment.centerLeft,
                                child: textWidget(
                                    ' ${widget.bank}',
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    width: 6,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          child: textWidget(
                                              'Ac #: ${widget.ac_number}',
                                              TextAlign.center,
                                              2,
                                              TextOverflow.clip,
                                              13,
                                              textHeadingColor,
                                              FontWeight.w500,
                                              font_family),
                                        ),
                                        // const SizedBox(height: 8,),
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          child: textWidget(
                                              'Ac Title: ${widget.ac_title}',
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
                                  InkWell(
                                      onTap: () async {
                                        await Clipboard.setData(ClipboardData(
                                            text: widget.ac_number));
                                        copyToClipBoard(
                                            widget.ac_number.toString());
                                        // copied successfully
                                      },
                                      child: const Icon(
                                        Icons.copy,
                                      ))
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: textWidget(
                              'Upload Payment Proof',
                              TextAlign.start,
                              2,
                              TextOverflow.clip,
                              14,
                              textHeadingColor,
                              FontWeight.w600,
                              font_family),
                        ),
                        Container(
                          // height: MediaQuery.of(context).size.height * 0.25,
                          height: 220,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(width: 1.5, color: kBlack)),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              // Image.asset(''),
                              Row(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 6),
                                    width:
                                        MediaQuery.of(context).size.width / 1.9,
                                    // alignment: Alignment.centerLeft,
                                    child: image != null
                                        ? Image.file(
                                            image!,
                                            fit: BoxFit.fill,
                                          )
                                        : const Center(
                                            child: Text('Upload Image'),
                                          ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 6),
                                child: InkWell(
                                  onTap: () async {
                                      // (permissionResult == PermissionStatus.denied || permissionResult == PermissionStatus.permanentlyDenied)
                                    if(Platform.isAndroid)
                                    {
                                    PermissionStatus permission_Result =
                                    await Permission.storage.status;
                                    PermissionStatus permissionResult =
                                    await Permission.photos.status;
                                    if (permission_Result == PermissionStatus.granted ||
                                        permissionResult == PermissionStatus.granted) {
                                      pickImage();
                                    } else {
                                      await Permission.storage.request();
                                      await Permission.photos.request();
                                    }
                                    }
                                    else if(Platform.isIOS)
                                    {
                                    PermissionStatus permissionResult =
                                    await Permission.photos.status;
                                    print(permissionResult);
                                    switch(permissionResult){
                                      case PermissionStatus.granted:
                                        pickImage();
                                        break;
                                      case PermissionStatus.limited:
                                        pickImage();
                                        break;
                                      case PermissionStatus.restricted:
                                        pickImage();
                                        break;
                                      case PermissionStatus.permanentlyDenied:
                                        showSnackMessage(context, 'Give permission to download your receipt!');
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
                                  child: const CircleAvatar(
                                      radius: 23,
                                      child: Icon(Icons.camera_alt)),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: textWidget(
                              'Instructions:',
                              TextAlign.start,
                              2,
                              TextOverflow.clip,
                              16,
                              textHeadingColor,
                              FontWeight.w600,
                              font_family),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: textWidget(
                              '1. Send payment on above account.',
                              TextAlign.start,
                              2,
                              TextOverflow.clip,
                              14,
                              kRed,
                              FontWeight.w500,
                              font_family),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: textWidget(
                              '2. Upload payment proof and submit.',
                              TextAlign.start,
                              2,
                              TextOverflow.clip,
                              14,
                              kRed,
                              FontWeight.w500,
                              font_family),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: textWidget(
                              '3. Payment will be approved in 30 minutes.',
                              TextAlign.start,
                              2,
                              TextOverflow.clip,
                              14,
                              kRed,
                              FontWeight.w500,
                              font_family),
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '1. اوپر والے اکاؤنٹ پر ادائیگی بھیجیں.',
                            textAlign: TextAlign.start,
                            overflow: TextOverflow.clip,
                            maxLines: 2,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: kRed,
                                fontFamily: font_family),
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '2. ادائیگی کا ثبوت اپ لوڈ کریں اور جمع کریں.',
                            textAlign: TextAlign.start,
                            overflow: TextOverflow.clip,
                            maxLines: 2,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: kRed,
                                fontFamily: font_family),
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '3. ادائیگی 30 منٹ میں منظور کی جائے گی.',
                            textAlign: TextAlign.start,
                            overflow: TextOverflow.clip,
                            maxLines: 2,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: kRed,
                                fontFamily: font_family),
                          ),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        InkWell(
                          onTap: () {
                            if (image != null) {
                              checkConnectivity();
                            }
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: image != null
                                  ? primaryColor
                                  : primaryColor.withOpacity(0.4),
                            ),
                            child:
                                // loader
                                //     ?  Center(
                                //         child: CircularProgressIndicator(color: primaryColor,),
                                //       )
                                //     :
                                textWidget(
                                    'SUBMIT',
                                    TextAlign.center,
                                    1,
                                    TextOverflow.clip,
                                    16,
                                    image != null
                                        ? kWhite
                                        : kWhite.withOpacity(0.4),
                                    FontWeight.w600,
                                    font_family),
                          ),
                        )
                      ],
                    ),
                  ),
          ));
  }
}
