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

class IRC5
	constructor: ->
		@status '(connecting...)'

		@socket = new io.Socket

		@socket.on 'connect', @onConnected
		@socket.on 'message', @onMessage
		@socket.on 'disconnect', @onDisconnected

		@socket.connect()

		@$main = $('#main')
		@nick = undefined

		@systemWindow = new Window('system')
		@switchToWindow @systemWindow
		@windows = {}
		@winList = [@systemWindow]

	onConnected: =>
		@status 'connected.'
	onDisconnected: => @status "disconnected"

	onMessage: (msg) =>
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

		JOIN: (from, chan) ->
			if from.nick == @nick
				win = new Window(chan)
				win.target = chan
				@windows[win.target] = win
				@winList.push(win)
				@switchToWindow win

		PRIVMSG: (from, target, msg) ->
			win = @windows[target] || @systemWindow
			win.message(from.nick, msg)
	}

	send: (args...) ->
		@socket.send('~j~' + JSON.stringify args)

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
			@send 'JOIN', chan
		win: (num) ->
			num = parseInt(num)
			@switchToWindow @winList[num] if num < @winList.length
		say: (text...) ->
			if target = @currentWindow.target
				msg = text.join(' ')
				@onMessage prefix: @nick, command: 'PRIVMSG', params: [target, msg]
				@send 'PRIVMSG', target, msg
		nick: (newNick) ->
			@send 'NICK', newNick
	}

	command: (text) ->
		if text[0] == '/'
			cmd = text[1..].split(/\s+/)
			if func = commands[cmd[0].toLowerCase()]
				func.apply(this, cmd[1..])
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
$cmd.keydown (e) ->
	if e.which == 13
		cmd = $cmd.val()
		if cmd.length > 0
			$cmd.val('')
			irc.command cmd
