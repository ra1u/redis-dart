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




//LazyStreamFast is speed optimised implementation of LazyStream
//take note that StreamSocket is Stream<List<byte>> 
//received buffers are pushed on queue and
//iterator is used for storing current position

class LazyStreamFast implements LazyStream {
  Stream _stream;
  Queue<List> _queue;
  var _ondata;
  Iterator _iter;
  List _return;
  StreamSubscription _sub;
  
  LazyStreamFast(){}
  LazyStreamFast.fromstream(this._stream){
    _return = new List();
    _queue = new Queue();
    _sub = _stream.listen((List data){
      if(data.length == 0)
        return;
      if(_queue.isEmpty){
        _iter = data.iterator;
      }
      _queue.add(data);
      if(_ondata != null) {
        _ondata(data);
      }
    });
  }
  
  LazyStreamFast.fromqueuelist(this._queue){
    _return = new List();
    if(!_queue.isEmpty){
      _iter = _queue.first.iterator;
    }
  }
  
  //tryto take n from current buffer
  //returns how much was not taken and still waits to be taken
  int take_n_now(int n){
    assert(n>=0);
    if(_queue.isEmpty){
      return n;
    }
    while(n>0){
      if(!_iter.moveNext()){
        _queue.removeFirst();
        if(_queue.isEmpty){
          return n;
        }
        else {
          _iter = _queue.first.iterator;
          continue;
        }
      }
      _return.add(_iter.current);
      --n;
    }
    return n;
  }
  
  void take_n_helper(int n,Completer comp){
    int remains =  take_n_now(n);
    if(remains==0){
      comp.complete(_return);
      _return = new List();  
      _ondata = null;
    }
    else{
      _ondata = (_){
        take_n_helper(remains,comp);
      };
    }
  }
  
  Future<List> take_n(int n){
     Completer comp = new Completer();
     take_n_helper(n,comp);
     return comp.future;
  }
  
  bool take_while_now(f){
    if(_queue.isEmpty){
      return false;
    }
    while(true){
      if(!_iter.moveNext()){
        _queue.removeFirst();
        if(_queue.isEmpty){
          return false;
        }
        else {
          _iter = _queue.first.iterator;
          continue;
        }
      }
      var cur = _iter.current;
      bool pred = f(cur);
      if(pred)
         _return.add(cur);
      else
        return false;
    }
  }
  
  void take_while_helper(f,Completer comp){
    bool r =  take_while_now(f);
    if(!r){
      comp.complete(_return);
      _return = new List();  
      _ondata = null;
    }
    else{
      _ondata = (_){
        take_while_helper(f,comp);
      };
    }
  }
  
  Future<List> take_while(f){
     Completer comp = new Completer();
     take_while_helper(f,comp);
     return comp.future;
  }
}
