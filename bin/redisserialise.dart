part of redis_parser;


Utf8Encoder RedisSerialiseEncoder = new Utf8Encoder();

class RedisSerialise {
  static String Serialise(object){
     if(object is String){
       int len=object.length;
       return "\$"+ len.toString() + "\r\n" + object + "\r\n";
     }
     if(object is int){
       return ":$object\r\n";
     }
     if(object is List){
         int len=object.length;
         String r ="\*"+len.toString()+"\r\n";
         for(int i=0;i<len;++i){
            r += Serialise(object[i]);
         }
         return r;
     }
     if(object == null){
       return "\$-1"; //null bulk
     }
     throw("cant serialise such type");
  }
}