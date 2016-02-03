part of redis;

class Trie{
  Map _trie;
  
  Trie() {
    _trie = new Map();
  }
  Stream<Object> get(String key){
    return _geth(key,0,_trie);
  }
  
  Stream<Object> _geth(String s,int i,Map map){
    var letter = s[i];
    if(!map.containsKey(letter)){
      map[letter]=[new Map(),null];
    }
    if(i+1==s.length){
      var contoller = new StreamController();
      map[letter][1] = contoller;
      return contoller.stream;
    }
    return _geth(s,i+1,map[letter][0]);
  }
  
  send(String s,Object msg){
    _send(s,0,msg,_trie);
  }
  
  _exec(String s,Object msg,StreamController ctrl){
    if(ctrl == null)
      return;
    ctrl.add(msg);
  }
  
  _send(String s,int depth,Object msg,Map map){
    var letter = s[depth];
    if(map.containsKey('*')){
      _exec(s,msg,map['*'][1]);
    }
    if(map.containsKey(letter)){
      if(depth+1 == s.length) {
        _exec(s,msg,map[letter][1]);
      }
      else{
        _send(s,depth+1,msg,map[letter][0]);
      }
    }
  }
}

test_trie(){
  Trie trie = new Trie();
  int c=0;
  int N = 10000;
  
  trie.get("hi wor*").listen((v){
    ++c;
    if(c ==N+10){
      print("done $c");
    }
  });
  
  for(int i=0;i<N;++i){
    trie.send("hi world", "bannana");
  }
  for(int i=0;i<N;++i){
    trie.send("hi worldest", "bannana");
  }
}

