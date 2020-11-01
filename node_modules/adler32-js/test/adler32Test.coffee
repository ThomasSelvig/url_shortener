assert = require 'assert'
Adler32 = require '../src/adler32'

describe 'adler32', ->
    it 'should correctly compute checksum from a string', ->
        # Example taken from http://en.wikipedia.org/wiki/Adler-32.
        assert.equal Adler32.fromString('Wikipedia'), 300286872
        assert.equal(
            Adler32.fromString('Wikipedia', {encoding: 'hex'}).toLowerCase(),
            '11e60398')

    it 'should correctly compute checksum from a stream', (done) ->
        # Example taken from http://en.wikipedia.org/wiki/Adler-32.
        through = require 'through'
        t = new through()
        Adler32.fromStream t, (err, sum) ->
            return done err if err
            assert.equal sum, 300286872
            done()

        t.write 'Wikipedia'
        t.end()

    it 'should correctly compute a hex checksum from a stream', (done) ->
        # Example taken from http://en.wikipedia.org/wiki/Adler-32.
        through = require 'through'
        t = new through()
        Adler32.fromStream t, {encoding: 'hex'}, (err, result) ->
            return done err if err
            assert.equal result.toLowerCase(), '11e60398'
            done()

        t.write 'Wikipedia'
        t.end()

    it 'should conform to the Hash interface from the crypto package', ->
        hash = new Adler32()
        hash.update('Wikipedia')
        assert.equal hash.digest('hex').toLowerCase(), '11e60398'
