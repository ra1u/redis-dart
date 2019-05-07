/*
 * Free software licenced under 
 * GNU AFFERO GENERAL PUBLIC LICENSE
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */

//our parser was designed for lazy stream that is consumable
//unfortnatly redis socket streams doest work that way
//this class implements minimum requrement for redisparser

//currently parser requrement is take_n and take_while methods

part of redis;


class StreamNext<T>  {
  StreamSubscription<T> _ss;
  Queue<Completer<T>> _queue;
  int _nfut;
  int _npack;
  bool done;
  StreamNext.fromstream(Stream<T> stream){
    _queue = new Queue<Completer<T>>();
    _nfut = 0;
    _npack = 0;
    done = false;
    _ss = stream.listen(onData /* ,onError : this.onError  , onDone : this.onDone */);
  }

  void onData(T event){
    if(_nfut >= 1){
      Completer  c = _queue.removeFirst();
      c.complete(event);
      _nfut -= 1; 
    }
    else{
      Completer<T> c = new Completer<T>();
      c.complete(event);
      _queue.addLast(c);
      _npack += 1;
      if(!_ss.isPaused && (_npack > 0)) {
        print("pause");
        _ss.pause();
      }
    }
  }

  void onError(error){
    done = true;
    if(_nfut >= 1){
      for(Completer<T> e in  _queue){
        e.completeError(error);
      }
    }
  }

  void onDone(){
    onError("stream is done");
  }

  Future<T> next(){
    if(_npack == 0){
      if(done) {
        throw("stream is done");
      }
      _nfut += 1;
      _queue.addLast(new Completer<T>());
      return _queue.last.future;
    }
    else {
      print("next $_npack $_nfut");
      Completer<T> c = _queue.removeFirst();
      _npack -= 1;
      if(_ss.isPaused && (_npack < 5)){
        _ss.resume();
      }
      return c.future;
    }
  }
  
}

// it 
class LazyStream {
  
  StreamNext<List<int>> _stream;
  List<int> _remainder;
  List<int> _return;
  int _start_index;
  Iterator<int> _iter;
  LazyStream.fromstream(Stream<List<int>> stream){
    _stream = new StreamNext<List<int>>.fromstream(stream);
    _start_index = 0;
    _return = new List<int>();
    _remainder = new List<int>();
    _iter = _remainder.iterator;
  }
  
  Future<List<int>> take_n2(int n) async {
    _return = new List<int>();
    if(n == 0){
      return _return;
    }
    int x = n;
    while(true){
      x = _take_n_helper(x);
      if(x == 0){
         return  _return;
      }
      _remainder = await _stream.next();
      _iter = _remainder.iterator;
    }
    throw("end of stream");
  }

  Future<List<int>> take_n(int n) {
    _return = new List<int>();
    return __take_n(n);
  }
  
  Future<List<int>> __take_n(int n) {
    int rest = _take_n_helper(n);
    if (rest == 0){
        return new Future<List<int>>.value(_return);
    }
    else {
      return _stream.next().then<List<int>>((List<int> pack){
        _remainder = pack;
        _iter = _remainder.iterator;
        return __take_n(rest);
      });
    }
  }

  // return remining n
  int _take_n_helperX(int n){
    int rl = _remainder.length;
    if(rl > 0){
      int t = min(n, _remainder.length - _start_index);
      int start = _return.length;
      _return.addAll(_remainder.skip(_start_index).take(t));
      int end = _return.length;
      _start_index += t;
      if(_start_index == rl){
        _remainder = new List<int>();
        _start_index = 0;
      }
      return n - t ;
    }
    else {
      return n;
    }
  }

  // return remining n
  int _take_n_helperY(int n){
    int rl = _remainder.length;
    int end = min(_start_index + n,_remainder.length);
    int r = n - (end - _start_index); 
    for(;_start_index<end;++_start_index){
      _return.add(_remainder[_start_index]);
    }
    if(_start_index == rl){
        _remainder = new List<int>();
        _start_index = 0;
    }
    return r;
  }

  // return remining n
  int _take_n_helper(int n){
    while(n > 0 && _iter.moveNext()){
      _return.add(_iter.current);
      n--;
    }
    return n;
  }

  Future<List<int>> take_while2(bool Function(int) pred) async {
    _return = new List<int>();
    while(!_take_while_helper(pred)){
      _remainder = await _stream.next();
      _iter = _remainder.iterator;
    }
    return _return;
  }

  Future<List<int>> take_while(bool Function(int) pred) {
    _return = new List<int>();
    return __take_while(pred);
  }
  
  Future<List<int>> __take_while(bool Function(int) pred) {
    if (_take_while_helper(pred)){
        return Future<List<int>>.value(_return);
    }
    else {
      return _stream.next().then<List<int>>((List<int> rem){
        _remainder = rem;
        _iter = _remainder.iterator;
        return __take_while(pred);
      });
    }
  }

  // return true when exaused (when predicate returns false)
  bool _take_while_helper(bool Function(int) pred){
    while(_iter.moveNext()){
      if(pred(_iter.current)){
        _return.add(_iter.current);
      }
      else {
        return true;
      }
    }
    return false;
  }

  // return true when exaused (when predicate returns false)
  bool _take_while_helperY(bool Function(int) pred){
    int start = _return.length;
    _return.addAll(_remainder.skip(_start_index).takeWhile(pred));
    int end = _return.length;
    _start_index += end - start;
    if(_start_index == _remainder.length){
      _remainder = new List<int>();
      _start_index = 0;
      return false;
    }
    else{
      return true;
    }
  }
  // return true when exaused (when predicate returns false)
  bool _take_while_helperX(bool Function(int) pred){
    int end = _return.length;
    for(; _start_index < end ; ++_start_index){
       int v = _remainder[_start_index];
       if(!pred(v)){
         return true;
       }
       _return.add(v);
    }
    _start_index = 0;
    _remainder = new List<int>();
    return false;
  }

}


//LazyStreamFast is speed optimised implementation of LazyStream
//take note that StreamSocket is Stream<List<byte>> 
//received buffers are pushed on queue and
//iterator is used for storing current position
/*
class LazyStream  {
  Stream<List<int>> _stream;
  Queue<List<int>> _queue;
  var _ondata;
  Iterator _iter;
  List<int> _return;
  StreamSubscription _sub;
  
  LazyStream(){}
  LazyStream.fromstream(this._stream){
    _return = new List<int>();
    _queue = new Queue<List<int>>();
    _sub = _stream.listen((data){
      assert(data is List<int>);
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
  
  Future<List<int>> take_n_helper(int n){
    int remains =  take_n_now(n);
    if(remains==0){
      var ret = new Future<List<int>>.value(_return);
      _return = new List<int>();  
      _ondata = null;
      return ret;
    }
    else{
      Completer<List<int>> comp = new Completer<List<int>>.sync();
      _ondata = (_){
        take_n_helper(remains).then((v)=>comp.complete(v));
      };
      return comp.future;
    }
  }
  
  Future<List<int>> take_n(int n){
     return take_n_helper(n);
  }
  
  //return true if done
  bool take_while_now(bool f(int)){
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
        return true;
    }
  }
  
  Future<List<int>> take_while_helper(Function f){
    bool r =  take_while_now(f);
    if(r){
      var ret = new Future.value(_return);
      _return = new List();  
      _ondata = null;
      return ret;
    }
    else{
      Completer comp = new Completer();
      _ondata = (_){
        take_while_helper(f).then((v)=>comp.complete(v));
      };
      return comp.future;
    }
  }
  
  Future<List> take_while( bool Function(dynamic) f){
     return take_while_helper(f);
  }
}
*/
