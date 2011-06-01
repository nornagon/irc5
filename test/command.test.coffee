irc = require '../irc'
assert = require 'assert'

module.exports =
	'trailing stuff': (test) ->
		assert.deepEqual {
			prefix: '!foo'
			command: 'NOTICE'
			params: ['a','b','c', 'blah blah']
		}, irc.parseCommand ':!foo NOTICE a b c :blah blah'
		test.finish()

	'no prefix': (test) ->
		assert.deepEqual {
			prefix: undefined
			command: 'PING'
			params: ['foo']
		}, irc.parseCommand('PING :foo')
		test.finish()

	'freenode notice': (test) ->
		assert.deepEqual {
			prefix: 'wolfe.freenode.net'
			command: 'NOTICE'
			params: ['*', '*** Looking up your hostname...']
		}, irc.parseCommand ':wolfe.freenode.net NOTICE * :*** Looking up your hostname...'
		test.finish()

	'long params': (test) ->
		assert.deepEqual {
			prefix: undefined
			command: 'NOTICE'
			params: ['foobar']
		}, irc.parseCommand 'NOTICE foobar'
		test.finish()

	'empty trail': (test) ->
		assert.deepEqual {
			prefix: undefined
			command: 'NOTICE'
			params: ['*', '']
		}, irc.parseCommand 'NOTICE * :'
		test.finish()
