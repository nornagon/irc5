escapeHTML = (html) ->
	escaped = {
		'&': '&amp;',
		'<': '&lt;',
		'>': '&gt;',
		'"': '&quot;',
	}
	String(html).replace(/[&<>"]/g, (chr) -> escaped[chr])

parsePrefix = (prefix) ->
	p = /^([^!]+?)(?:!(.+?)(?:@(.+?))?)?$/.exec(prefix)
	{ nick: p[1], user: p[2], host: p[3] }

class RPC
	constructor: (@socket, @methods) ->
		@next_rpc_id = 0
		@waiting_calls = {}

		@socket.on 'message', @onMessage

	respond = (id) ->
		return unless id?
		(err, res) =>
			msg = { id: data.id }
			if err then msg.error = err else msg.result = res
			@socket.send msg

	onMessage: (data) =>
		unless data?
			console.log "bad json-rpc call: #{JSON.stringify data}"
			return

		if data.method?
			# method call
			if func = @methods[data.method]
				func.apply(@, [respond(data.id)].concat(data.params))
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

class IRC5
	constructor: ->
		@status '(connecting...)'

		@socket = new io.Socket

		@socket.on 'connect', @onConnected
		@socket.on 'disconnect', @onDisconnected
		@rpc = rpc @socket,
			message: (cb, args...) => @onMessage args... # notification

		@socket.connect()

		@$main = $('#main')
		@nick = undefined

		@systemWindow = new Window('system')
		@switchToWindow @systemWindow
		@windows = {}
		@winList = [@systemWindow]

	onConnected: => @status 'connected'
	onDisconnected: => @status 'disconnected'

	onMessage: (conn_id, msg) =>
		prefix = parsePrefix msg.prefix
		cmd = if /^\d{3}$/.test(msg.command)
			parseInt(msg.command)
		else
			msg.command
		if handlers[cmd]
			handlers[cmd].apply(this, [prefix].concat(msg.params))
		else
			@systemWindow.message prefix.nick, msg.command + ' ' + msg.params.join(' ')

	handlers = {
		# RPL_WELCOME
		001: (from, target, msg) ->
			# once we get a welcome message, we know who we are
			@nick = target
			@status()
			@systemWindow.message from.nick, msg

		# RPL_NAMREPLY
		353: (from, target, privacy, channel, nicks...) ->

		NICK: (from, newNick, msg) ->
			if from.nick == @nick
				@nick = newNick
				@status()

		JOIN: (from, chan) ->
			if from.nick == @nick
				win = new Window(chan)
				win.target = chan
				@windows[win.target] = win
				@winList.push(win)
				@switchToWindow win
			if win = @windows[chan]
				win.message('', "#{from.nick} joined the channel.")

		PART: (from, chan) ->
			if win = @windows[chan]
				win.message('', "#{from.nick} left the channel.")

		QUIT: (from, reason) ->
			# TODO message in any window that this user is in

		PRIVMSG: (from, target, msg) ->
			win = @windows[target] || @systemWindow
			win.message(from.nick, msg)
	}

	send: (conn_id, msg...) ->
		@rpc.call((->), 'send', conn_id, msg)

	status: (status) ->
		if !status
			status = "[#{@nick}] #{@currentWindow.target}"
		$('#status').text(status)

	switchToWindow: (win) ->
		if @currentWindow
			@currentWindow.scroll = @currentWindow.$container.scrollTop()
			@currentWindow.wasScrolledDown = @currentWindow.isScrolledDown()
			@currentWindow.$container.detach()
		@$main.append win.$container
		if win.wasScrolledDown
			win.scroll = win.$container[0].scrollHeight
		win.$container.scrollTop(win.scroll)
		@currentWindow = win
		@status()

	commands = {
		join: (chan) ->
			@send 0, 'JOIN', chan
		win: (num) ->
			num = parseInt(num)
			@switchToWindow @winList[num] if num < @winList.length
		say: (text...) ->
			if target = @currentWindow.target
				msg = text.join(' ')
				@onMessage 0, prefix: @nick, command: 'PRIVMSG', params: [target, msg]
				@send 0, 'PRIVMSG', target, msg
		me: (text...) ->
			commands.say('\u0001ACTION '+text.join(' ')+'\u0001')
		nick: (newNick) ->
			@send 0, 'NICK', newNick
		connect: (server, port) ->
			@rpc.call (->), 'connect', server, parseInt(port)
	}

	command: (text) ->
		if text[0] == '/'
			cmd = text[1..].split(/\s+/)
			if func = commands[cmd[0].toLowerCase()]
				func.apply(this, cmd[1..])
			else
				console.log "no such command"
		else
			commands.say.call(this, text)


class Window
	constructor: (@name) ->
		@$container = $ "<div id='chat-container'>"
		@$messages = $ "<div id='chat'>"
		@$container.append @$messages

	isScrolledDown: ->
		scrollBottom = @$container.scrollTop() + @$container.height()
		scrollBottom == @$container[0].scrollHeight

	message: (from, msg) ->
		scroll = @isScrolledDown
		e = escapeHTML
		msg = (e msg).replace(/\S{40,}/,'<span class="longword">$&</span>')
		@$messages.append $("""
		<div class='message'>
			<div class='source'>#{e from}</div>
			<div class='text'>#{msg}</div>
		</div>
		""")
		if scroll
			@$container.scrollTop(@$container[0].scrollHeight)

irc = new IRC5

$cmd = $('#cmd')
$cmd.focus()
$(window).keydown (e) ->
	unless e.metaKey or e.ctrlKey
		e.currentTarget = $('#cmd')[0]
		$cmd.focus()
	if e.altKey and 48 <= e.which <= 57
		irc.command("/win " + (e.which - 48))
		e.preventDefault()
$cmd.keydown (e) ->
	if e.which == 13
		cmd = $cmd.val()
		if cmd.length > 0
			$cmd.val('')
			irc.command cmd
