import 'dart:io';

abstract class BaseApiServices {
  Future<dynamic> getApi(String url);
  Future<dynamic> postApi(dynamic data, String url);
    Future<dynamic> putApi(dynamic data, String url);
        Future<dynamic> delete(dynamic data, String url);



    
}
