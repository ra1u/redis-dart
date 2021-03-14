part of redis;

class Prophecy<T> {
  late Future<T> Function() _f;

  Prophecy._func(Future<T> Function() v) {
    _f = v;
  }

  Prophecy._future(Future<T> f) {
    this._f = () => f;
  }

  Prophecy(Future<T> f) {
    this._f = () => f;
  }

  Prophecy.value(T v) {
    _f = () => Future.value(v);
  }

  Prophecy<E> map<E>(E f(T)) {
    return Prophecy._func(() => this._eval().then((x) => f(x)));
  }

  Future<T> _eval() {
    return _f();
  }

  Future<T> get future => this._eval();
}

Prophecy<R> zipWith2<R, A1, A2>(
    R fun(A1, A2), Prophecy<A1> a1, Prophecy<A2> a2) {
  // this version seems to be both simple, correct and most performant
  return Prophecy<R>._future(a1._eval().then((a) {
    return a2._eval().then((b) {
      return fun(a, b);
    });
  }));
}

Prophecy<R> zipWith3<R, A1, A2, A3>(
    R fun(A1, A2, A3), Prophecy<A1> a1, Prophecy<A2> a2, Prophecy<A3> a3) {
  return Prophecy<R>._future(a1._eval().then((r1) {
    return a2._eval().then((r2) {
      return a3._eval().then((r3) {
        return fun(r1, r2, r3);
      });
    });
  }));
}

Prophecy<R> zipWith4<R, A1, A2, A3, A4>(R fun(A1, A2, A3, A4), Prophecy<A1> a1,
    Prophecy<A2> a2, Prophecy<A3> a3, Prophecy<A4> a4) {
  return Prophecy<R>._future(a1._eval().then((r1) {
    return a2._eval().then((r2) {
      return a3._eval().then((r3) {
        return a4._eval().then((r4) {
          return fun(r1, r2, r3, r4);
        });
      });
    });
  }));
}

Prophecy<R> zipWith5<R, A1, A2, A3, A4, A5>(
    R fun(A1, A2, A3, A4, A5),
    Prophecy<A1> a1,
    Prophecy<A2> a2,
    Prophecy<A3> a3,
    Prophecy<A4> a4,
    Prophecy<A5> a5) {
  return Prophecy<R>._future(a1._eval().then((r1) {
    return a2._eval().then((r2) {
      return a3._eval().then((r3) {
        return a4._eval().then((r4) {
          return a5._eval().then((r5) {
            return fun(r1, r2, r3, r4, r5);
          });
        });
      });
    });
  }));
}

Prophecy<R> zipWith6<R, A1, A2, A3, A4, A5, A6>(
    R fun(A1, A2, A3, A4, A5, A6),
    Prophecy<A1> a1,
    Prophecy<A2> a2,
    Prophecy<A3> a3,
    Prophecy<A4> a4,
    Prophecy<A5> a5,
    Prophecy<A6> a6) {
  return Prophecy<R>._future(a1._eval().then((r1) {
    return a2._eval().then((r2) {
      return a3._eval().then((r3) {
        return a4._eval().then((r4) {
          return a5._eval().then((r5) {
            return a6._eval().then((r6) {
              return fun(r1, r2, r3, r4, r5, r6);
            });
          });
        });
      });
    });
  }));
}

Prophecy<R> zipWith7<R, A1, A2, A3, A4, A5, A6, A7>(
    R fun(A1, A2, A3, A4, A5, A6, A7),
    Prophecy<A1> a1,
    Prophecy<A2> a2,
    Prophecy<A3> a3,
    Prophecy<A4> a4,
    Prophecy<A5> a5,
    Prophecy<A6> a6,
    Prophecy<A7> a7) {
  return Prophecy<R>._future(a1._eval().then((r1) {
    return a2._eval().then((r2) {
      return a3._eval().then((r3) {
        return a4._eval().then((r4) {
          return a5._eval().then((r5) {
            return a6._eval().then((r6) {
              return a7._eval().then((r7) {
                return fun(r1, r2, r3, r4, r5, r6, r7);
              });
            });
          });
        });
      });
    });
  }));
}

Prophecy<R> zipWith8<R, A1, A2, A3, A4, A5, A6, A7, A8>(
    R fun(A1, A2, A3, A4, A5, A6, A7, A8),
    Prophecy<A1> a1,
    Prophecy<A2> a2,
    Prophecy<A3> a3,
    Prophecy<A4> a4,
    Prophecy<A5> a5,
    Prophecy<A6> a6,
    Prophecy<A7> a7,
    Prophecy<A8> a8) {
  return Prophecy<R>._future(a1._eval().then((r1) {
    return a2._eval().then((r2) {
      return a3._eval().then((r3) {
        return a4._eval().then((r4) {
          return a5._eval().then((r5) {
            return a6._eval().then((r6) {
              return a7._eval().then((r7) {
                return a8._eval().then((r8) {
                  return fun(r1, r2, r3, r4, r5, r6, r7, r8);
                });
              });
            });
          });
        });
      });
    });
  }));
}
