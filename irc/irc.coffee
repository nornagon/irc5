net = require 'net'

parseCommand = (data) ->
	str = data.toString('utf8')
	parts = ///
		^
		(?::([^\x20]+?)\x20)?           # prefix
		([^\x20]+?)                     # command
		((?:\x20[^\x20:][^\x20]*)+)?    # params
		(?:\x20:(.*))?                  # trail
		$
	///.exec(str)
	throw new Error("invalid IRC message: #{data}") unless parts
	# could do more validation here...
	# prefix = servername | nickname((!user)?@host)?
	# command = letter+ | digit{3}
	# params has weird stuff going on when there are 14 arguments
	# shouldn't match \x00

	# trim whitespace
	if parts[3]
		parts[3] = parts[3].slice(1).split(/\x20/)
	else
		parts[3] = []
	{
		prefix: parts[1]
		command: parts[2]
		params: parts[3]
		trail: parts[4]
	}
exports.parseCommand = parseCommand

class IRC
	constructor: (@server, @port) ->
		@socket = net.createConnection(@port, @server)
		@socket.on 'connect', ->
		@socket.on 'data', (data) => @onData data
		@data = new Buffer(0)

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
