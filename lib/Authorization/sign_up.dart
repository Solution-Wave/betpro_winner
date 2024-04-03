import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../Utils/CheckConnection.dart';
import '../Utils/colors.dart';
import '../Utils/constants.dart';
import '../Utils/messages.dart';
import '../Utils/navigator.dart';
import '../Utils/text.dart';
import '../Utils/themes.dart';
import '../Utils/urls.dart';
import '../components/passwordTextField.dart';
import '../components/textField.dart';
import '../components/textStyle.dart';
import '../controllers/get_time_controller.dart';
import '../controllers/whatsapp.dart';
import 'sign_in.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController commissionController = TextEditingController();

  bool loader = false;
  bool nameError = false;
  bool usernameError = false;
  bool mailError = false;
  bool mailValidate = false;
  bool phoneError = false;
  bool passError = false;
  bool confirmPassError = false;
  bool agree =false;
  Whatsapp whatsappController = Whatsapp();
  List commisionList = [];
  bool reseller = false;
  String? commissionValue;
  final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');

  formValidate() {
    setState(() {
      nameError = false;
      usernameError = false;
      // mailError = false;
      phoneError = false;
      // mailValidate = false;
      passError = false;
      confirmPassError = false;
    });
    if (nameController.text.isEmpty ||
        usernameController.text.isEmpty ||
        // emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty) {
      /////////////////////
      if (nameController.text.isEmpty) {
        setState(() {
          nameError = true;
        });
      }
      if (usernameController.text.isEmpty) {
        setState(() {
          usernameError = true;
        });
      }
      if (phoneController.text.isEmpty) {
        setState(() {
          phoneError = true;
        });
      }
      if (passwordController.text.isEmpty) {
        setState(() {
          passError = true;
        });
      }
    } else {
        if (passwordController.text != confirmPasswordController.text) {
        setState(() {
          confirmPassError = true;
        });
      } else {
        checkConnectivity();
      }
    }
  }

  checkConnectivity() async {
    if (await connection()) {
      signUpApi();
    } else {
      showSnackMessage(context, "You are not connected to internet");
    }
  }

  signUpApi() async {
    setState(() {
      loader = true;
    });

    Map body = {
      'name': nameController.text,
      "email": "example@gmail.com",
      "phone": phoneController.text,
      "username": usernameController.text,
      'password': passwordController.text,
      "role" : reseller ==false?"User":"Reseller"  ,
      "commission": commissionValue??"",
    };
  // print(body);
    try {
      http.Response response =
          await http.post(Uri.parse(signUpURL), body: body);

      Map jsonData = jsonDecode(response.body);
      print(jsonData);
      if (jsonData["status"] == 200) {
        setState(() {
          loader = false;
        });

        showSnackMessage(context, 'Your account has been successfully created');
        navRemove(context, const SignInScreen());
      } else {
        setState(() {
          loader = false;
        });
        print("error message    ${jsonData['message']}");
        if (jsonData['message'].length > 1) {
          showSnackMessage(
              context, '${jsonData['message'][0]}\n${jsonData['message'][1]}');
        } else {
          showSnackMessage(context, '${jsonData['message'][0]}');
        }
      }
    } catch (e) {
      print(e);
      showSnackMessage(
          context, 'Check your internet connection\nTry again later');
      setState(() {
        loader = false;
      });
    }
  }

  void GetwhatsappNumber()async{
    GetTimeController _getTimeController = GetTimeController();
    var responseFromApi = await _getTimeController.getTimeAPiData();
    if(responseFromApi is !String ){
      whatsappController.updateContact(responseFromApi['Data'][0]["whatsapp_no"]);
    } else{
      showSnackMessage(context, responseFromApi);
    }
  }

  void getCommissionList()async{
    try {
      http.Response response =
          await http.get(Uri.parse(getCommission));

      Map jsonData = jsonDecode(response.body);
      print(jsonData);
      if (jsonData["status"] == 200) {
       setState(() {
         commisionList = jsonData["data"].map((value)=>value).toList();
       });
      }
    } catch (e) {
      // print(e);
      showSnackMessage(
          context, 'Check your internet connection\nTry again later');
    }
  }
  @override
  void initState() {
    // TODO: implement initState
    GetwhatsappNumber();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    var platform = Theme.of(context).platform;

    return SafeArea(
      child: Scaffold(
        backgroundColor: scaffoldColor,
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.06,
              vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.08,
              ),
              CircleAvatar(
                radius: 35,
                backgroundColor: primaryColor,
                child: Image.asset(
                  'assets/person.png',
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              textWidget(
                  lblForgotPassTitle,
                  TextAlign.center,
                  2,
                  TextOverflow.clip,
                  20,
                  textHeadingColor,
                  FontWeight.w500,
                  font_family),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.015,
              ),
              Container(
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width / 1.9,
                // padding: const EdgeInsets.symmetric(horizontal: 55),
                child: textWidget(
                    lblSignUpSubtitle,
                    TextAlign.center,
                    3,
                    TextOverflow.clip,
                    16,
                    textLightColor,
                    FontWeight.w300,
                    font_family),
              ),
              SizedBox(height: 10 ,),
              reseller == true?
              InkWell(
                  onTap: (){
                    setState(() {
                      reseller = false;
                    });
                  },
                  child: Text("Become a user", style: hyperlinkTextTheme ,)):
              InkWell(
                  onTap: () {
                    setState(() {
                      reseller = true;
                    });
                    getCommissionList();
                  },
                  child: Text("Become a Partner", style: hyperlinkTextTheme,)),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.045,
              ),
              textField(context, nameController, 'Name', TextInputType.name),
              nameError
                  ? Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '  name is required',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                            fontSize: 12, color: kRed, fontFamily: font_family),
                      ))
                  : const SizedBox(),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.025,
              ),
              textField(
                  context, usernameController, 'Username', TextInputType.name),
              usernameError
                  ? Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '  username is required',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                            fontSize: 12, color: kRed, fontFamily: font_family),
                      ))
                  : const SizedBox(),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.025,
              ),
              // textField(context, emailController, 'Email',
              //     TextInputType.emailAddress),
              // mailError
              //     ? Container(
              //         alignment: Alignment.centerLeft,
              //         child: Text(
              //           '  email is required',
              //           textAlign: TextAlign.start,
              //           style: TextStyle(
              //               fontSize: 12, color: kRed, fontFamily: font_family),
              //         ))
              //     : mailValidate
              //         ? Container(
              //             alignment: Alignment.centerLeft,
              //             child: Text(
              //               '  invalid email',
              //               textAlign: TextAlign.start,
              //               style: TextStyle(
              //                   fontSize: 12,
              //                   color: kRed,
              //                   fontFamily: font_family),
              //             ),
              //           )
              //         : const SizedBox(),
              // SizedBox(
              //   height: MediaQuery.of(context).size.height * 0.025,
              // ),
              textField(context, phoneController, 'Phone number',
                  TextInputType.phone),
              phoneError
                  ? Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '  phone number is required',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                            fontSize: 12, color: kRed, fontFamily: font_family),
                      ))
                  : const SizedBox(),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.025,
              ),
              PasswordTextField(
                controller: passwordController,
                hint: 'Password',
              ),
              passError
                  ? Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '  password is required',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                            fontSize: 12, color: kRed, fontFamily: font_family),
                      ))
                  : const SizedBox(),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.025,
              ),
              PasswordTextField(
                controller: confirmPasswordController,
                hint: 'Confirm password',
              ),
              confirmPassError
                  ? Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '  password don\'t match',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                            fontSize: 12, color: kRed, fontFamily: font_family),
                      ))
                  : const SizedBox(),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.035,
              ),
              Visibility(
                visible: reseller,
                child: DropdownButtonFormField(
                  hint: Text("Select your share"),
                    items: commisionList.map(
                            (e) => DropdownMenuItem(
                              value: e["amount"],
                                child: Text(" ${e["commission"]} %"))).toList(),
                    onChanged: (value){
                    commissionValue = value.toString();
                    commissionController.text = commissionValue!;
                    }),
              ),
        Visibility(
          visible: reseller,
             child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.035,
              ),),
              Visibility(
                  visible: reseller,
                  child: Row(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width *0.57,
                          child: textField(context,commissionController,"Share Amount",TextInputType.text,enabled: false),),
                      Text(" /100,000-", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),)
                    ],
                  ),),
        Visibility(
          visible: reseller,
              child:SizedBox(
                height: MediaQuery.of(context).size.height * 0.035,
              ),),
              Row(
                children: [
                  GestureDetector(
                    onTap: (){
                      launchUrl(Uri.parse('https://betprodeals.com/privacy/policy'));
                    },
                    child: Text('User Agreement', style: hyperlinkTextTheme,),
                  ),
                  Checkbox(
                      activeColor: primaryColor,
                      // MaterialStateProperty.resolveWith((states) => primaryColor),
                      value: agree, onChanged: (newVal){
                    setState(() {
                      agree = newVal!;
                    });
                  }),
                ],),
              InkWell(
                  onTap: agree ?() {
                    formValidate();

                  } : (){},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: agree?primaryColor:Colors.grey),
                    alignment: Alignment.center,
                    child: loader
                        ? Center(
                            child: Platform.isAndroid ?
                            CircularProgressIndicator( color: kWhite,):
                            CupertinoActivityIndicator(color: kWhite,),
                    )
                        : textWidget(
                            'SignUp',
                            TextAlign.center,
                            1,
                            TextOverflow.clip,
                            18,
                            kWhite,
                            FontWeight.bold,
                            font_family),
                  )),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.035,
              ),
              Text.rich(TextSpan(children: [
                TextSpan(
                    text: 'Already have an account?',
                    style: TextStyle(fontFamily: font_family)),
                const TextSpan(text: '   '),
                TextSpan(
                    text: 'Sign In',
                    style: hyperlinkTextTheme,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        navPush(context, const SignInScreen());
                      }),
              ])),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [

                  SizedBox(width: 50,),
                  GestureDetector(
                    onTap: (){
                      whatsappController.redirect(platform, context);
                    }, child: Container(
                    height: 25,
                    decoration: BoxDecoration(
                      color: Color(0xFF31B946),
                      borderRadius: BorderRadius.all(Radius.circular(4))
                    ),
                    child: Image.asset(
                        'assets/whatsapp.png',
                        fit: BoxFit.scaleDown
                    ),
                    ),
                  )
                ],)
            ],
          ),
        ),
      ),
    );
  }
}
