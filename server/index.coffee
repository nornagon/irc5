io = require 'socket.io'
irc = require '../irc'
express = require 'express'

app = express.createServer(
	express.logger()
)

app.register '.coffee', require('coffeekup')
app.set 'view engine', 'coffee'

socket = io.listen(app)

socket.on 'connection', (client) ->
	irc_conn = new irc.IRC('irc.freenode.net', 6667)
	irc_conn.on 'message', (msg) ->
		client.send(msg)
	irc_conn.connect()
	client.on 'message', (data) ->
		irc_conn.send(data...)
	client.on 'disconnect', ->
		irc_conn.close()


app.get '/', (req, res) ->
	res.render 'chat'

app.listen(3000)
