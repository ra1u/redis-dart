/*
 * Free software licenced under 
 * GNU AFFERO GENERAL PUBLIC LICENSE
 * 
 * Check for document LICENCE forfull licence text
 * 
 * Luka Rahne
 */

part of redis;

class Cas {
  Command _cmd;
  late Completer<bool> _completer_bool;

  /// Class for  CAS  check-and-set pattern
  /// Construct with Command and call
  /// watch() and multiAndExec()
  Cas(this._cmd) {}

  /// watch takes list of watched keys and
  /// function that is executed
  /// during CAS opertion
  ///
  Future watch(List<String> watching_keys, func()) {
    //return _cmd.send_object(["TRANS"]);
    List<String> watchcmd = ["WATCH"];
    watchcmd.addAll(watching_keys);
    return Future.doWhile(() {
      _completer_bool = Completer();
      _cmd.send_object(watchcmd).then((_) {
        func();
      });
      return _completer_bool.future;
    });
  }

  /// multiAndExec takes function
  /// to complete CAS as Transaction
  /// passed function takes Transaction
  /// as only parameter and should be used to
  /// complete transaction
  ///
  /// !!! DO NOT call exec() on Transaction

  Future multiAndExec(Future func(Transation)) {
    return _cmd.multi().then((Transaction _trans) {
      func(_trans);
      return _trans.exec().then((var resp) {
        if (resp == "OK") {
          _completer_bool.complete(false); //terminate Future.doWhile
        } else {
          // exec completes only with valid response
          _completer_bool.completeError(
              RedisException("exec response is not expected, but is $resp"));
        }
      }).catchError((e) {
        // dont do anything
        _completer_bool.complete(true); // retry
      }, test: (e) => e is TransactionException);
    });
  }
}
