net = require 'net'

parseCommand = (data) ->
	str = data.toString('utf8')
	parts = ///
		^
		(?: : ([^\x20]+?) \x20)?        # prefix
		([^\x20]+?)                     # command
		((?:\x20 [^\x20:] [^\x20]*)+)?  # params
		(?:\x20:(.*))?                  # trail
		$
	///.exec(str)
	throw new Error("invalid IRC message: #{data}") unless parts
	# could do more validation here...
	# prefix = servername | nickname((!user)?@host)?
	# command = letter+ | digit{3}
	# params has weird stuff going on when there are 14 arguments

	# trim whitespace
	if parts[3]?
		parts[3] = parts[3].slice(1).split(/\x20/)
	else
		parts[3] = []
	parts[3].push(parts[4]) if parts[4]?
	{
		prefix: parts[1]
		command: parts[2]
		params: parts[3]
	}

exports.parseCommand = parseCommand

makeCommand = (cmd, params, prefix) ->
	_prefix = if prefix then "!#{prefix} " else ''
	_params = if params and params.length > 0
		if !params[0...params.length-1].every((a) -> !/\x20/.test(a))
			throw new Error("some non-final arguments had spaces in them")
		if /\x20/.test(params[params.length-1])
			params[params.length-1] = ':'+params[params.length-1]
		' ' + params.join(' ')
	else
		''
	_prefix + cmd + _params + "\x0d\x0a"

randomName = (length = 10) ->
	chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	(chars[Math.floor(Math.random() * chars.length)] for x in [0...length]).join('')

class IRC
	constructor: (@server, @port, @opts) ->
		@opts ||= {}
		@opts.nick ||= "irc5-#{randomName()}"
		@socket = net.createConnection(@port, @server)
		@socket.on 'connect', => @onConnect()
		@socket.on 'data', (data) => @onData data
		@data = new Buffer(0)

	onConnect: ->
		@socket.write(makeCommand 'NICK', [@opts.nick])
		@socket.write(makeCommand 'USER', [@opts.nick, '0', '*', 'An irc5 user'])

	onData: (pdata) ->
		newData = new Buffer(@data.length + pdata.length)
		@data.copy(newData)
		pdata.copy(newData, @data.length)
		@data = newData
		while @data.length > 0
			cr = false
			crlf = undefined
			for d,i in @data
				if d == 0x0d
					cr = true
				else if cr and d == 0x0a
					crlf = i
					break
				else
					cr = false
			if crlf?
				line = @data.slice(0, crlf-1)
				@data = @data.slice(crlf+1)
				@onCommand(parseCommand line)
			else
				break

	onCommand: (cmd) ->
		console.log cmd

exports.IRC = IRC
