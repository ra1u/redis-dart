import 'dart:async';
import 'dart:convert';
import './redisparser.dart';
import 'dart:collection';


testparser(){
  List data =  new Utf8Encoder().convert("*3\r\n*1\r\n:3\r\n+Foo\r\n+Barzor\r\n ");
  var stream = new LazyStream.fromstream(new Stream.fromIterable(data));  
  
  RedisParser.parseredisresponse(stream).then((v) {
    print("$v");
  });
}

main(){
  const int N = 100000;
  const int K = N ; //concurrent executions
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
    conn.send(["GET","test "+n.toString()]).then((v)  =>
        test_send(conn,n+step,step,max)
     );
  }
  
  RedisConnection conn = new RedisConnection();
  conn.connect('localhost',6379).then((_){
    print("test started, please wait ...");
    start =  new DateTime.now().millisecondsSinceEpoch;
    conn.pipe_start();
    for(int i=0;i<K;i++){
      test_send(conn,i,K,N);
    }
    conn.pipe_end();
   });
}