doctype 5
html ->
	head ->
		meta charset: 'utf-8'
		title 'foo'
		script src: '/socket.io/socket.io.js'
		script src: 'https://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.js'
		style '''
		html, body {
			height: 100%;
			font-family: monospace;
		}
		#main {
			width: 100%;
			height: 100%;
			padding-bottom: 50px;
			box-sizing: border-box;
		}
		#chat-container {
			overflow-y: scroll;
			width: 100%;
			height: 100%;
		}
		#chat {
			display: table;
		}
		body {
			margin: 0; padding: 0;
		}
		.message {
			display: table-row;
		}
		.message .source {
			display: table-cell;
			text-align: right;
			padding: 0 10px;
			border-right: 1px solid lightgray;
		}
		.message .text {
			display: table-cell;
			padding: 0 10px;
		}

		#entry {
			position: fixed;
			bottom: 0;
			height: 30px;
			width: 100%;
		}
		#entry input {
			width: 100%;
			height: 100%;
			border: 0;
			outline-width: 0;
			font-family: inherit;
			font-size: inherit;
			padding-left: 4px;
		}
		#status {
			width: 100%;
			height: 20px;
			background-color: lightgray;
			position: fixed;
			bottom: 30px;
		}

		/*
		#main {
			padding-left: 150px;
		}
		#channels {
			position: fixed;
			top: 0; left: 0;
			height: 100%;
			overflow-y: auto;
			overflow-x: hidden;
			width: 150px;
			box-sizing: border-box;
			border-right: 2px solid lightgray;
			list-style: none;
			margin: 0;
			padding: 0;
			font-family: Helvetica, arial, sans-serif;
			font-size: 12px;
			padding: 10px;
			padding-right: 0;
		}
		#channels li {
			padding: 2px 10px;
			border-radius: 2px 0 0 2px;
		}
		#channels li.selected {
			background-color: lightgray;
			font-weight: bold;
			color: white;
		}
		*/

		.longword { word-break: break-all; }
		'''
		coffeescript ->
			escapeHTML = (html) ->
				escaped = {
					'&': '&amp;',
					'<': '&lt;',
					'>': '&gt;',
					'"': '&quot;',
				}
				String(html).replace(/[&<>"]/g, (chr) -> escaped[chr])
			status = (status) ->
				$('#status').text(status)

			commands =
				join: (chan) ->
					send 'JOIN', chan

			command = (text) ->
				if text[0] == '/'
					cmd = text[1..].split(/\s+/)
					if func = commands[cmd[0].toLowerCase()]
						func(cmd[1..]...)
				else
					commands.say(text)

			socket = null
			send = () ->
				socket.send(JSON.stringify Array.prototype.slice.call(arguments))

			$ ->
				$chat = $('#chat')
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
							command cmd
				socket = new io.Socket
				socket.connect()
				status '(connecting...)'
				socket.on 'connect', ->
					console.log 'connected'
					status ''
				socket.on 'message', (msg) ->
					cont = $('#chat-container')
					scroll = false
					if (cont.scrollTop() + cont.height() == cont[0].scrollHeight)
						scroll = true
					e = escapeHTML
					msg.params = msg.params.map (m) ->
						(e m).replace(/\S{30,}/,'<span class="longword">$&</span>')
					$chat.append $("""
					<div class='message'>
						<div class='source'>#{e msg.prefix}</div>
						<div class='text'>#{e msg.command} #{msg.params.join(' ')}</div>
					</div>
					""")
					if scroll
						cont.scrollTop(1000000000)
				socket.on 'disconnect', ->
	body ->
		div id: 'main', ->
			div id: 'chat-container', ->
				div id: 'chat'
		###
		ul id: 'channels', ->
			li id: 'system', class: 'selected', 'System'
			li id: '#foobar', '#foobar'
		###
		div id: 'entry', ->
			div id: 'status'
			input id: 'cmd'
