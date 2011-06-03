io = require 'socket.io'
irc = require '../irc'
express = require 'express'

app = express.createServer(
	express.logger()
)

app.register '.coffee', require('coffeekup')
app.set 'view engine', 'coffee'

socket = io.listen(app)

class RPC
	constructor: (@socket, @methods) ->
		@next_rpc_id = 0
		@waiting_calls = {}

		@socket.on 'message', @onMessage

	respond: (id) ->
		return unless id?
		(err, res) =>
			msg = { id: id }
			if err then msg.error = err else msg.result = res
			@socket.send msg

	onMessage: (data) =>
		unless data?
			console.log "bad json-rpc call: #{JSON.stringify data}"
			return

		if data.method?
			# method call
			if func = @methods[data.method]
				func.apply(@, [@respond(data.id)].concat(data.params))
			else
				respond?('no such method')

		else if typeof data.result != 'undefined' or typeof data.error != 'undefined'
			# response
			if data.id? and @waiting_calls[data.id]
				@waiting_calls[data.id].call(@, data.error, data.result)
				delete @waiting_calls[data.id]
			else
				console.log "unknown response id: #{JSON.stringify data}"

		else
			console.log "bad message: #{JSON.stringify data}"

	call: (cb, method, params...) ->
		rpc_id = @next_rpc_id++
		@waiting_calls[rpc_id] = cb
		@socket.send id: rpc_id, method: method, params: params

	notify: (method, params...) ->
		@socket.send method: method, params: params

rpc = (socket, methods) -> new RPC(socket, methods)

socket.on 'connection', (client) ->
	conns = {}
	next_conn_id = 0

	rpc client,
		connect: (cb, server, port) ->
			conn_id = next_conn_id++
			conns[conn_id] = conn = new irc.IRC(server, port)
			conn.on 'message', (msg) =>
				@notify 'message', conn_id, msg
			conn.connect()
			cb(undefined, conn_id)

		disconnect: (cb, conn_id, message) ->
			if conn = conns[conn_id]
				conn.quit(message)
				conn.removeAllListeners 'message'
				delete conns[conn_id]
				cb(undefined, null)
			else
				cb('invalid connection id')

		send: (cb, conn_id, msg) ->
			if conn = conns[conn_id]
				conn.send(msg...)
				cb(undefined, null)
			else
				cb('invalid connection id')

	client.on 'disconnect', ->
		for id, conn in conns
			conn.quit('client disconnected')
			conn.removeAllListeners 'message'
			delete conns[id]


app.get '/', (req, res) ->
	res.render 'chat'

staticProvider = express.static('./static')
app.get '/static/*', (req, res) ->
	req.url = req.url.substr(7) # strip off ^/static
	staticProvider.apply(this, arguments)

app.listen(3000)
