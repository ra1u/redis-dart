part of redis_parser;


Utf8Encoder RedisSerialiseEncoder = new Utf8Encoder();

class RedisSerialise {
  static List<int> Serialise(object){
     if(object is String){
       int len=object.length;
       return RedisSerialiseEncoder.convert("\$$len\r\n$object\r\n");
     }
     if(object is int){
       return RedisSerialiseEncoder.convert(":$object\r\n");
     }
     if(object is List){
         int len=object.length;
         List<int> r =[]; //growable list
         r.addAll(RedisSerialiseEncoder.convert("\*$len\r\n"));
         for(int i=0;i<len;++i){
            r.addAll(Serialise(object[i]));
         }
         return r;
     }
     if(object == null){
       return RedisSerialiseEncoder.convert("\$-1"); //null bulk
     }
     throw("cant serialise such type");
  }
  
  static List<int> RedisSerialiseListInt(object){
    int len=object.length;
    List<int> r =[]; //growable list
    r.addAll(RedisSerialiseEncoder.convert("\$$len\r\n"));
    r.addAll(object);
    r.addAll(RedisSerialiseEncoder.convert("\r\n"));
    return r;
  }
}