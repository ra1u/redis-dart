part of redis_parser;


Utf8Encoder RedisSerialiseEncoder = new Utf8Encoder();

class RedisSerialise {
  static String Serialise(object){
     String s="";
     SerialiseConsumable(object,(v){
       s=s+v;
     });
     return s;
  }
  
  static void SerialiseConsumable(object,Function consumer(String s)){
     if(object is String){
       int len=object.length;
       consumer("\$");
       consumer(len.toString());
       consumer("\r\n");
       consumer(object);
       consumer("\r\n");
     }
     else if(object is int){
       consumer(":");
       consumer(object.toString());
       consumer("\r\n");
     }
     else if(object is List){
       int len=object.length;
       consumer("\*");
       consumer(len.toString());
       consumer("\r\n");
       for(int i=0;i<len;++i){
         SerialiseConsumable(object[i],consumer);
       }
     }
     else if(object == null){
       consumer("\$-1"); //null bulk
     }
     else{
       throw("cant serialise such type");
     }
  }
}