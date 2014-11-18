//our parser was designed for lazy stream that is consumable
//unfortnatly redis socket streams doest work that way (yet?)
//this class implements minimum requrement for redisparser

//currently parser requrement is take_n and take_while methods

part of redis_parser;


class LazyStream{
  Stream _stream;
  StreamSubscription _sub;
  LazyStream(){}
  LazyStream.fromstream(this._stream){
    _sub = _stream.listen((_){})
    ..pause();
  }
  
  Future<List> take_n(int n){
    assert(n>=0);
    List r=[];
    if(n==0) return new Future.value(r);
    Completer comp = new Completer();
    _sub.onData((e){
      r.add(e);
      if(r.length==n){
        _sub.pause();
        comp.complete(r);
      }
    });
    _sub.resume();
    return comp.future;
  }
  
  Future<List> take_while(pred){
    List r=[];
    Completer comp = new Completer();
    _sub.onData((e){
      if(!pred(e)){
        _sub.pause();
        comp.complete(r);
      }
      else{
        r.add(e);
      }
    });
    _sub.resume();
    return comp.future;
  }
}
