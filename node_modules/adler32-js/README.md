adler32-js
----------

This is a coffee-script port of adler32.c from zlib, written by Mark Adler.  Port by Jason Walton.

Installation
------------

`npm install --save adler32-js`

Usage
-----

adler32-js complies to the [Hash interface](http://nodejs.org/api/crypto.html#crypto_class_hash)
from the node.js crypto package:

```
Adler32 = require('adler32-js');
hash = new Adler32();
hash.update('Hello world!');
console.log("Digest: ", hash.digest('hex'));
```

Unlike crypto Hash objects, Adler32 object can be recycled using the `reset()` method.

If you are after the raw integer value, you can also use:

```
hash = new Adler32();
hash.update('Hello world!');
console.log("Digest as int: ", hash.result());
```

Helper functions are also available for hashing strings, files, and streams:

```
Adler32.fromStream(stream, {encoding: 'hex'}, function(err, result) {
    console.log("Digest", result);
});

Adler32.fromFile('./foo.txt', {encoding: 'hex'}, function(err, result) {
    console.log("Digest", result);
});

result = Adler32.fromFileSync('./foo.txt', {encoding: 'hex'});

result = Adler32.fromString('Hello world!');
```

