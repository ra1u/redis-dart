
[README.md](README.md)

### 1.4.0
- Tls and custom Socket support. Thanks to [@Derrick56007](https://github.com/Derrick56007)

### 1.3.0
- Improved error handling [Issue #15](https://github.com/ra1u/redis-dart/issues/15)
- Experimental transaction discard [Issue #11](https://github.com/ra1u/redis-dart/issues/11)
- Minor fixes

### 1.2.0
- Received redis errors throws exception. Thanks to [@eknoes](https://github.com/eknoes) for pull request.
- Integers in array get auto converted to strings. Author [@eknoes](https://github.com/eknoes).
- Improve transaction handling errors. Patch from [@eknoes](https://github.com/eknoes)
- Testing migrated on dart.test. Patch from [@eknoes](https://github.com/eknoes)

### 1.1.0
- Performance tweaks and simplified code

### 1.0.0
- Dart 2.0 support

### 0.4.5
- Unicode bugfix -> https://github.com/ra1u/redis-dart/issues/4
- Update PubSub doc
- Improve tests

### 0.4.4
- bugfix for subscribe -> https://github.com/ra1u/redis-dart/issues/3
- performance improvement
- add PubSub class (simpler/shorter/faster?  PubSubCommand)
- doc update and example of EVAL

### 0.4.3
- Cas helper
- Improved unit tests

### 0.4.2
- Improved performance by 10%
- Pubsub interface uses Stream
- Better test coverage
- Improved documentation

### 0.4.1
- Command  raise error if used during transaction.

### 0.4.0
- PubSub interface is made simpler but backward incompatible :(
- README is updated

[README.md](README.md)
