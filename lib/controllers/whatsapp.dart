
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Utils/messages.dart';

class Whatsapp{
  String? contact;
  void updateContact(String number){
    contact =number;
  }
  redirect(var platform, BuildContext context) async {
    print(contact);
    var androidUrl = "whatsapp://send?phone=$contact&text=Hi, I need some help";
    var iosUrl ="https://wa.me/$contact?text=${Uri.parse('Hi, I need some help')}";
    try
    {
      if (TargetPlatform.iOS == platform) {

        await launchUrl(
          Uri.parse(iosUrl),
          mode: LaunchMode.externalApplication,
        );
      } else if (TargetPlatform.android == platform) {

        await launchUrl(
          Uri.parse(androidUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    }on Exception{
      showSnackMessage(context, 'Whatsapp Not Installed');
    }

  }

}