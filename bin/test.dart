import 'dart:async';
import 'dart:convert';
import './redisparser.dart';

testparser(){
  List data =  new Utf8Encoder().convert("*3\r\n*1\r\n:3\r\n+Foo\r\n+Barzor\r\n ");
  var stream = new LazyStream(new Stream.fromIterable(data));  
  
  RedisParser.parseredisresponse(stream).then((v) {
    print("$v");
    print(UTF8.decode(RedisSerialise.Serialise(v)));
  });
}

main(){
  const int N = 100000;
  const int K = N ~/ 100 ; //integer divison
  int count=0;
  int start;
  void test_send(RedisConnection conn,int n,int step,int max){
    if(n>max){
      count++;
      if(count>=K){
        double diff = (new DateTime.now().millisecondsSinceEpoch - start)/1000.0;
        double perf = N/diff;
        print("done in $diff s\nperformance $perf/s");
      }
      return;
    }
    conn.send(["SET","test $n","$n"]).then((v)  =>
      conn.send(["GET","test $n"]).then((v){
        assert(v == "$n");
        test_send(conn,n+step,step,max);
      })
     );
  }
  
  RedisConnection conn = new RedisConnection();
  conn.connect('localhost',6379).then((_){
    print("test started, please wait ...");
    start =  new DateTime.now().millisecondsSinceEpoch;
    for(int i=0;i<K;i++)
      test_send(conn,i,K,N);
   });
}