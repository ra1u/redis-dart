part of redis;
/*
 * Free software licenced under 
 * GNU AFFERO GENERAL PUBLIC LICENSE
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */


Utf8Encoder RedisSerialiseEncoder = new Utf8Encoder();

class RedisSerialise {
  static List<int> Serialise(object){
     List s = new List();
     SerialiseConsumable(object,(v){
       s.addAll(v);
     });
     return s;
  }
  
  static void SerialiseConsumable(object,Function consumer(Iterable s)){
     if(object is String){
       var str = object;
       consumer(ASCII.encode("\$"));
       consumer(ASCII.encode(str.length.toString()));
       consumer(ASCII.encode("\r\n")); 
       consumer(UTF8.encode(str));
       consumer(ASCII.encode("\r\n"));
     }
     else if(object is Iterable){
       int len=object.length;
       consumer(ASCII.encode("*"));
       consumer(ASCII.encode(len.toString()));
       consumer(ASCII.encode("\r\n"));
       for(int i=0;i<len;++i){
         SerialiseConsumable(object[i],consumer);
       }
     }
     else if(object is int){
       consumer(ASCII.encode(":"));
       consumer(ASCII.encode(object.toString()));
       consumer(ASCII.encode("\r\n"));
     }
     else if(object == null){
       consumer(ASCII.encode("\$-1")); //null bulk
     }
     else{
       throw("cant serialise such type");
     }
  }
}