part of testredis;



Future testincrcas(){
  RedisConnection conn = new RedisConnection();
  return conn.connect('localhost',6379).then((Command command){ 
    Cas cas = new Cas(command);
    return cas.watch(["key"], (){
      command.send_object(["GET","key"]).then((val){
        int i = int.parse(val);
        i++;
        cas.multiAndExec(( trans){
          return trans.send_object(["SET","key",i.toString()]);
        });
      });
    });
  });
}

Future testincrcasmultiple(){
  RedisConnection conn = new RedisConnection();
  return conn.connect('localhost',6379).then((Command command){ 
    command.send_object(["SET","key","0"]);
    Queue<Future> q =new Queue();
    int N=300;
    for(int i=0;i<N;i++){
      q.add(testincrcas());
    }
    return Future.wait(q).then((_){
      return command.send_object(["GET","key"]).then((v){
        assert(v == N.toString());
      });
    });
  });
}
