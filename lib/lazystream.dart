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

// like Stream but has method next for simple reading
class StreamNext<T> {
  late Queue<Completer<T>> _queue;
  late int _nfut;
  late int _npack;
  late bool done;
  StreamNext.fromstream(Stream<T> stream) {
    _queue = new Queue<Completer<T>>();
    _nfut = 0;
    _npack = 0;
    done = false;
    stream.listen(onData, onError: this.onError, onDone: this.onDone);
  }

  void onData(T event) {
    if (_nfut >= 1) {
      Completer c = _queue.removeFirst();
      c.complete(event);
      _nfut -= 1;
    } else {
      Completer<T> c = new Completer<T>();
      c.complete(event);
      _queue.addLast(c);
      _npack += 1;
    }
  }

  void onError(error) {
    done = true;
    if (_nfut >= 1) {
      _nfut = 0;
      for (Completer<T> e in _queue) {
        e.completeError(error);
      }
    }
  }

  void onDone() {
    onError("stream is closed");
  }

  Future<T> next() {
    if (_npack == 0) {
      if (done) {
        return Future<T>.error("stream closed");
      }
      _nfut += 1;
      _queue.addLast(new Completer<T>());
      return _queue.last.future;
    } else {
      Completer<T> c = _queue.removeFirst();
      _npack -= 1;
      return c.future;
    }
  }
}

// it
class LazyStream {
  late StreamNext<List<int>> _stream;
  late List<int> _remainder;
  late List<int> _return;
  late Iterator<int> _iter;
  LazyStream.fromstream(Stream<List<int>> stream) {
    _stream = new StreamNext<List<int>>.fromstream(stream);
    _return = <int>[];
    _remainder = <int>[];
    _iter = _remainder.iterator;
  }

  void close() {
    _stream.onDone();
  }

  Future<List<int>> take_n(int n) {
    _return = <int>[];
    return __take_n(n);
  }

  Future<List<int>> __take_n(int n) {
    int rest = _take_n_helper(n);
    if (rest == 0) {
      return new Future<List<int>>.value(_return);
    } else {
      return _stream.next().then<List<int>>((List<int> pack) {
        _remainder = pack;
        _iter = _remainder.iterator;
        return __take_n(rest);
      });
    }
  }

  // return remining n
  int _take_n_helper(int n) {
    while (n > 0 && _iter.moveNext()) {
      _return.add(_iter.current);
      n--;
    }
    return n;
  }

  Future<List<int>> take_while(bool Function(int) pred) {
    _return = <int>[];
    return __take_while(pred);
  }

  Future<List<int>> __take_while(bool Function(int) pred) {
    if (_take_while_helper(pred)) {
      return Future<List<int>>.value(_return);
    } else {
      return _stream.next().then<List<int>>((List<int> rem) {
        _remainder = rem;
        _iter = _remainder.iterator;
        return __take_while(pred);
      });
    }
  }

  // return true when exaused (when predicate returns false)
  bool _take_while_helper(bool Function(int) pred) {
    while (_iter.moveNext()) {
      if (pred(_iter.current)) {
        _return.add(_iter.current);
      } else {
        return true;
      }
    }
    return false;
  }
}
