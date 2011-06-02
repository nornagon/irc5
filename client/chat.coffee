escapeHTML = (html) ->
	escaped = {
		'&': '&amp;',
		'<': '&lt;',
		'>': '&gt;',
		'"': '&quot;',
	}
	String(html).replace(/[&<>"]/g, (chr) -> escaped[chr])

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
		@windows = [@systemWindow]

	onConnected: => @status ''
	onDisconnected: => @status "disconnected"

	onMessage: (msg) =>
		from = msg.prefix and /^(.+?)!/.exec(msg.prefix)
		fromMe = from and from[1]
		if msg.command == '001' || (msg.command == 'NICK' and fromMe)
			@nick = msg.params[0]
		if fromMe
			if msg.command == 'JOIN'
				win = new Window(msg.params[0])
				win.target = msg.params[0]
				@windows.push win
		target = @systemWindow
		for w in @windows
			if w.target == msg.params[0]
				target = w
				break
		target.message msg

	send: (args...) ->
		@socket.send('~j~' + JSON.stringify args)

	status: (status) ->
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

	commands =
		join: (chan) ->
			@send 'JOIN', chan
		win: (num) ->
			num = parseInt(num)
			@switchToWindow @windows[num] if num < @windows.length
		say: (text...) ->
			if @currentWindow.target
				@send 'PRIVMSG', @currentWindow.target, text.join(' ')

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

	message: (msg) ->
		scroll = @isScrolledDown
		e = escapeHTML
		msg.params = msg.params.map (m) ->
			(e m).replace(/\S{30,}/,'<span class="longword">$&</span>')
		@$messages.append $("""
		<div class='message'>
			<div class='source'>#{e msg.prefix}</div>
			<div class='text'>#{e msg.command} #{msg.params.join(' ')}</div>
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
