import 'dart:convert';

import 'package:http/http.dart'as http;

import '../Utils/urls.dart';

class GetTimeController{

  Future getTimeAPiData()async{
    try{
      var response = await  http.post(Uri.parse(withdrawTimeUrl),);
      Map json = jsonDecode(response.body);
      if(response.statusCode==200){
        return json;
      }else{
        return "Something went wrong";
      }
    }catch(error){
       return error.toString();
    }
  }


}