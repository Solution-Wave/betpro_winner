import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Screens/home_screen.dart';
import '../Screens/under_verification.dart';
import '../Utils/CheckConnection.dart';
import '../Utils/colors.dart';
import '../Utils/constants.dart';
import '../Utils/messages.dart';
import '../Utils/navigator.dart';
import '../Utils/text.dart';
import '../Utils/urls.dart';
import '../components/passwordTextField.dart';
import '../components/textField.dart';
import '../components/textStyle.dart';
import '../controllers/get_time_controller.dart';
import '../controllers/whatsapp.dart';
import 'sign_up.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Text Field Controller
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  Whatsapp whatsappController = Whatsapp();
  bool loader = false;
  bool usernameError = false;
  bool passError = false;
  bool agree = false;

  formValidate() {
    setState(() {
      usernameError = false;
      passError = false;
    });
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      if (passwordController.text.isEmpty) {
        setState(() {
          passError = true;
        });
      }
      if (usernameController.text.isEmpty) {
        setState(() {
          usernameError = true;
        });
      }
    } else {
      loginApi();
      checkConnectivity();
    }
  }

  checkConnectivity() async {
    if (await connection()) {
      loginApi();
    } else {
      showSnackMessage(context, 'You are not connected to internet');
    }
  }

  loginApi() async {
    setState(() {
      loader = true;
    });
    Map body = {
      "username": usernameController.text,
      'password': passwordController.text
    };
    try {
      print("check after login");
      http.Response response = await http.post(Uri.parse(loginURL), body: body);

      Map jsonData = jsonDecode(response.body);
      print("check after login: ${jsonData["status"]}");
      if (jsonData["status"] == 200) {
        setState(() {
          loader = false;
        });
        SharedPreferences prefs = await SharedPreferences.getInstance();
        var id = jsonData['user']['id'];
        var token = jsonData['token'];

        prefs.setString('id', id.toString());
        prefs.setString("token", token.toString());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Login Successfully'),
          duration: Duration(milliseconds: 1500),
        ));
        if (jsonData['user']['status'] == 'Approved') {
          navRemove(context, const HomeScreen());
        } else {
          navRemove(context, UnderVerification());
        }
      } else {
        setState(() {
          loader = false;
        });
        print("error message    ${jsonData['message']}");
        showSnackMessage(context, 'Invalid username/password');
      }
    } catch (e) {
      print(e);
      setState(() {
        loader = false;
      });
      showSnackMessage(context, 'Something went wrong!\nTry again later');
    }
  }
  void GetwhatsappNumber()async{
    GetTimeController _getTimeController = GetTimeController();
    var responseFromApi = await _getTimeController.getTimeAPiData();
    if(responseFromApi is !String ){
      // print(responseFromApi['Data'][0]["whatsapp_no"]);
      var number = responseFromApi['Data'][0]["whatsapp_no"];
      whatsappController.updateContact(number ?? "");
    } else{
      showSnackMessage(context, responseFromApi);
    }

  }

  @override
  void initState() {
    // TODO: implement initState
    GetwhatsappNumber();
    super.initState();
  }
  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    var platform = Theme.of(context).platform;

    return SafeArea(
      child: Scaffold(
        backgroundColor: scaffoldColor,
        //appBar: AppBar(),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.06,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.1,
              ),
              textWidget(lblLoginTitle, TextAlign.center, 2, TextOverflow.clip,
                  20, textHeadingColor, FontWeight.w500, font_family),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.022,
              ),
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: textWidget(
                    lblLoginSubtitle,
                    TextAlign.center,
                    3,
                    TextOverflow.clip,
                    14,
                    textLightColor,
                    FontWeight.w300,
                    font_family),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
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
              // SizedBox(
              //   height: MediaQuery.of(context).size.height*0.025,
              // ),
              // Container(
              //   alignment: Alignment.centerRight,
              //   child: InkWell(
              //     onTap: () {
              //       Navigator.push(context, MaterialPageRoute(builder: (context)=>const ForgotPassword()));
              //       //navPush(context, const ForgotPassword());
              //     },
              //
              //     child: Text(
              //       'Forgot Password',
              //       style: TextStyle(
              //           color: primaryColor,
              //           decoration: TextDecoration.underline,
              //           fontSize: 14,
              //           fontWeight: FontWeight.bold,
              //           fontStyle: FontStyle.italic,
              //           fontFamily: font_family),
              //     ),
              //   ),
              // ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.025,
              ),
              InkWell(
                  onTap: () {
                    if (!loader) {
                      formValidate();
                      // navPush(context, const HomeScreen());
                    }
                  }
                  ,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: primaryColor),
                    alignment: Alignment.center,
                    child: loader
                        ? Center(
                            child: Platform.isAndroid ?
                            CircularProgressIndicator( color: kWhite,):
                            CupertinoActivityIndicator(color: kWhite,),

                    )
                        : textWidget(
                            'Login',
                            TextAlign.center,
                            1,
                            TextOverflow.clip,
                            18,
                            kWhite,
                            FontWeight.bold,
                            font_family),
                  )),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.055,
              ),
              Text.rich(TextSpan(children: [
                TextSpan(
                    text: 'Don\'t Have an Account?',
                    style: TextStyle(fontFamily: font_family)),
                const TextSpan(text: '   '),
                TextSpan(
                    text: 'Sign Up',
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        decoration: TextDecoration.underline,
                        fontSize: 16,
                        fontFamily: font_family,
                        fontWeight: FontWeight.bold,
                        color: primaryColor
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        navPush(context, const SignUpScreen());
                      }),
              ])),
              Text.rich(TextSpan(children: [
                TextSpan(
                    text: 'Facing Problem\'s?',
                    style: TextStyle(fontFamily: font_family)),
                const TextSpan(text: '   '),
                TextSpan(
                    text: 'Click Here',
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        decoration: TextDecoration.underline,
                        fontSize: 16,
                        fontFamily: font_family,
                        fontWeight: FontWeight.bold,
                        color: primaryColor),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        whatsappController.redirect(platform, context);
                      }),
              ])),

            ],
          ),
        ),
      ),
    );
  }
}
