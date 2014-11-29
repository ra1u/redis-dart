part of redis;


//this trie is used to dispatch
//messages to  subscribers
//it is helper class for pub/sub interface
//all operations can be 
//O(N) where N is length of String.
class Trie{
  Map _trie;
  
  Trie() {
    _trie = new Map();
  }
  add(String key, Function f){
    assert(key.length > 0);
    _addh(key,0,f,_trie);
    return [key,f]; //this is remove object
  }
  
  _addh(String s,int i,Function f,Map map){
    var letter = s[i];
    if(!map.containsKey(letter)){
      map[letter]=[new Map(),new Set()];
    }
    if(i+1==s.length){
      map[letter][1].add(f);
      return;
    }
    _addh(s,i+1,f,map[letter][0]);
  }
  
  send(String s,Object msg){
    _send(s,0,msg,_trie);
  }
  
  static _exec(String s,Object msg,var q){
    if((q != null) && (q.length > 0)){
      List list = q.toList();
      for(Function f in list){
        f(s,msg);
      }
    }
  }
  
  _send(String s,int depth,Object msg,Map map){
    var letter = s[depth];
    if(letter != '*'){
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
    else {
      for(var v in map.values){
        _send(s,depth,msg,v[0]); 
        _exec(s,msg,v[1]);
      }
    }
  }
  remove(var d){
    _remove(d[0],0,d[1],_trie);
  }
  static _remove(String s, int depth,Function f,Map map){
    var letter = s[depth];
    if(map.containsKey(letter)){
      if(depth+1 == s.length){
        map[letter][1].remove(f);
        if((map[letter][0].length == 0) && (map[letter][1].length == 0)){
          map.remove(letter);
        }
      }
      else{
        _remove(s,depth+1,f,map[letter][0]);
      }
    }
  }
}

test_trie(){
  Trie trie = new Trie();
  int c=0;
  var d = trie.add("hi world", (v){
    ++c;
  });
  for(int i=0;i<1000000;++i){
    trie.send("hi world", "bannana");
  }
  trie.remove(d);
  for(int i=0;i<1000000;++i){
    trie.send("hi wor*", "bannana");
  }
  print("done $c");
}

