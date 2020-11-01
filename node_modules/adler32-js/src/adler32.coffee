fs = require 'fs'

# compute the Adler-32 checksum of a data stream
# Based on adler32.c from zlib, Copyright (C) 1995-2011 Mark Adler
# Ported to coffeescript by Jason Walton, 2014.
#
# The following copyright notice appeared in the zlib library:
#
###

  Copyright (C) 1995-2013 Jean-loup Gailly and Mark Adler

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

  Jean-loup Gailly        Mark Adler
  jloup@gzip.org          madler@alumni.caltech.edu


  The data format used by the zlib library is described by RFCs (Request for
  Comments) 1950 to 1952 in the files http://tools.ietf.org/html/rfc1950
  (zlib format), rfc1951 (deflate format) and rfc1952 (gzip format).

###

BASE = 65521 # largest prime smaller than 65536
# TODO: Can make NMAX bigger on Javascript, since we know we won't overflow this early.
NMAX = 5552  # NMAX is the largest n such that 255n(n+1)/2 + (n+1)(BASE-1) <= 2^32-1

# TODO: Optimize these MODs.

# /* use NO_DIVIDE if your processor does not do division in hardware --
#    try it both ways to see which is faster */
# #ifdef NO_DIVIDE
# /* note that this assumes BASE is 65521, where 65536 % 65521 == 15
#    (thank you to John Reiser for pointing this out) */
# #  define CHOP(a) \
#     do { \
#         unsigned long tmp = a >> 16; \
#         a &= 0xffffUL; \
#         a += (tmp << 4) - tmp; \
#     } while (0)
# #  define MOD28(a) \
#     do { \
#         CHOP(a); \
#         if (a >= BASE) a -= BASE; \
#     } while (0)
# #  define MOD(a) \
#     do { \
#         CHOP(a); \
#         MOD28(a); \
#     } while (0)
# #  define MOD63(a) \
#     do { /* this assumes a is not negative */ \
#         z_off64_t tmp = a >> 32; \
#         a &= 0xffffffffL; \
#         a += (tmp << 8) - (tmp << 5) + tmp; \
#         tmp = a >> 16; \
#         a &= 0xffffL; \
#         a += (tmp << 4) - tmp; \
#         tmp = a >> 16; \
#         a &= 0xffffL; \
#         a += (tmp << 4) - tmp; \
#         if (a >= BASE) a -= BASE; \
#     } while (0)
# #else

MOD = (a) -> a %= BASE
MOD28 = (a) -> a %= BASE
MOD63 = (a) -> a %= BASE

adler32 = (adler, buf) ->
    len = buf.length
    # split Adler-32 into component sums
    sum2 = (adler >>> 16) & 0xffff
    adler &= 0xffff

    # in case user likes doing a byte at a time, keep it fast
    if (len == 1)
        adler += buf[0]
        if (adler >= BASE)
            adler -= BASE
        sum2 += adler
        if (sum2 >= BASE)
            sum2 -= BASE
        return adler + (sum2 * 65536)

    # initial Adler-32 value (deferred check for len == 1 speed)
    if !buf?
        return 1
    pos = 0

    # in case short lengths are provided, keep it somewhat fast
    if (len < 16)
        while (len--)
            adler += buf[pos]
            pos++
            sum2 += adler
        if (adler >= BASE)
            adler -= BASE
        sum2 = MOD28(sum2)            # only added so many BASE's
        return adler + (sum2 * 65536)

    # do length NMAX blocks -- requires just one modulo operation
    while (len >= NMAX)
        len -= NMAX
        n = NMAX / 16                 # NMAX is divisible by 16
        while n--
            # 16 sums unrolled
            adler += buf[pos]; sum2 += adler
            adler += buf[pos+1]; sum2 += adler
            adler += buf[pos+2]; sum2 += adler
            adler += buf[pos+3]; sum2 += adler
            adler += buf[pos+4]; sum2 += adler
            adler += buf[pos+5]; sum2 += adler
            adler += buf[pos+6]; sum2 += adler
            adler += buf[pos+7]; sum2 += adler
            adler += buf[pos+8]; sum2 += adler
            adler += buf[pos+9]; sum2 += adler
            adler += buf[pos+10]; sum2 += adler
            adler += buf[pos+11]; sum2 += adler
            adler += buf[pos+12]; sum2 += adler
            adler += buf[pos+13]; sum2 += adler
            adler += buf[pos+14]; sum2 += adler
            adler += buf[pos+15]; sum2 += adler
            pos += 16
        adler = MOD(adler)
        sum2 = MOD(sum2)

    # do remaining bytes (less than NMAX, still just one modulo)
    if (len)                          # avoid modulos if none remaining
        while (len >= 16)
            len -= 16
            adler += buf[pos]; sum2 += adler
            adler += buf[pos+1]; sum2 += adler
            adler += buf[pos+2]; sum2 += adler
            adler += buf[pos+3]; sum2 += adler
            adler += buf[pos+4]; sum2 += adler
            adler += buf[pos+5]; sum2 += adler
            adler += buf[pos+6]; sum2 += adler
            adler += buf[pos+7]; sum2 += adler
            adler += buf[pos+8]; sum2 += adler
            adler += buf[pos+9]; sum2 += adler
            adler += buf[pos+10]; sum2 += adler
            adler += buf[pos+11]; sum2 += adler
            adler += buf[pos+12]; sum2 += adler
            adler += buf[pos+13]; sum2 += adler
            adler += buf[pos+14]; sum2 += adler
            adler += buf[pos+15]; sum2 += adler
            pos += 16
        while len--
            adler += buf[pos]
            pos++
            sum2 += adler

        adler = MOD(adler)
        sum2 = MOD(sum2)

    # return recombined sums
    return adler + (sum2 * 65536)

# /* ========================================================================= */
# local uLong adler32_combine_(adler1, adler2, len2)
#     uLong adler1;
#     uLong adler2;
#     z_off64_t len2;
# {
#     unsigned long sum1;
#     unsigned long sum2;
#     unsigned rem;

#     /* for negative len, return invalid adler32 as a clue for debugging */
#     if (len2 < 0)
#         return 0xffffffffUL;

#     /* the derivation of this formula is left as an exercise for the reader */
#     MOD63(len2);                /* assumes len2 >= 0 */
#     rem = (unsigned)len2;
#     sum1 = adler1 & 0xffff;
#     sum2 = rem * sum1;
#     MOD(sum2);
#     sum1 += (adler2 & 0xffff) + BASE - 1;
#     sum2 += ((adler1 >> 16) & 0xffff) + ((adler2 >> 16) & 0xffff) + BASE - rem;
#     if (sum1 >= BASE) sum1 -= BASE;
#     if (sum1 >= BASE) sum1 -= BASE;
#     if (sum2 >= (BASE << 1)) sum2 -= (BASE << 1);
#     if (sum2 >= BASE) sum2 -= BASE;
#     return sum1 | (sum2 << 16);
# }

# /* ========================================================================= */
# uLong ZEXPORT adler32_combine(adler1, adler2, len2)
#     uLong adler1;
#     uLong adler2;
#     z_off_t len2;
# {
#     return adler32_combine_(adler1, adler2, len2);
# }

# uLong ZEXPORT adler32_combine64(adler1, adler2, len2)
#     uLong adler1;
#     uLong adler2;
#     z_off64_t len2;
# {
#     return adler32_combine_(adler1, adler2, len2);
# }

total = 0

# Computes an adler32 checksum.
#
# To use, create a new instance, call `data()` once or more to feed bytes into the checksum,
# then call `result()` to get the checksum.
#
class Adler32
    constructor: ->
        @adler = 1

    # Updates the hash content with the given `data`, the encoding of which is given in
    # `encoding` and can be `'utf8'`, `'ascii'`, or `'binary'`. If no encoding is provided and the
    # input is a string an encoding of `'binary'` is enforced. If `data` is a `Buffer` then
    # `encoding` is ignored.
    update: (data, encoding=null) ->
        if !(data instanceof Buffer)
            data = new Buffer data, encoding

        @adler = adler32 @adler, data

    # Calculates the digest of all of the passed data to be hashed. The encoding can be `'hex'`,
    # `'binary'`, or `'base64'`. If no encoding is provided, then a buffer is returned.
    #
    # Note: This object can not be used after `digest()` method has been called.
    digest: (encoding='binary') ->
        answer = new Buffer(4)
        val =
        for i in [0...4]
            answer[3-i] = (@adler >>> (i * 8)) & 0xff
        return answer.toString(encoding)

    # Return the digest of all the passed data to be hashed as an integer.
    result: ->
        return @adler

    reset: ->
        @adler = 1

    # Hash a stream.  Calls `done(err, hash)` when complete, where `hash` is an integer.
    @fromStream: (stream, options, done) ->
        if !done?
            done = options
            options = {}

        adler = new Adler32()
        stream.on 'data', (d) ->
            adler.update d
        stream.on 'error', (err) -> done err
        stream.on 'end', ->
            if !options.encoding?
                done null, adler.result()
            else
                done null, adler.digest(options.encoding)
        return null

    # Hash a file.  Calls `done(err, hash)` when complete, where `hash` is an integer.
    @fromFile: (path, options, done) ->
        if !done?
            done = options
            options = {}

        readStream = fs.createReadStream path
        Adler32.fromStream readStream, options, (err, result) ->
            done err, result
        return null

    # Synchronous version of `fromFile()`.
    @fromFileSync: (path, options={}) ->
        data = fs.readFileSync path
        return Adler32.fromString data, options

    # Hash a string.
    @fromString: (string, options={}) ->
        adler = new Adler32()
        adler.update string
        return if !options.encoding?
            adler.result()
        else
            adler.digest(options.encoding)

exports = module.exports = Adler32
