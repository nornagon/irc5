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
			padding-bottom: 2em;
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
			border-right: 1px solid #222;
		}
		.message .text {
			display: table-cell;
			padding: 0 10px;
		}

		#entry {
			position: fixed;
			bottom: 0;
			height: 2em;
			width: 100%;
		}
		#entry input {
			width: 100%;
			height: 100%;
			border: 0;
			outline-width: 0;
			font-family: inherit;
			font-size: inherit;
		}
		.longword { word-break: break-all; }
		'''
		coffeescript ->
			$ ->
				$chat = $('#chat')
				socket = new io.Socket
				socket.connect()
				socket.on 'connect', ->
					console.log 'connected'
				socket.on 'message', (msg) ->
					console.log(msg)
					cont = $('#chat-container')
					scroll = false
					if (cont.scrollTop() + cont.height() == cont[0].scrollHeight)
						scroll = true
					msg.params = msg.params.map (m) ->
						m.replace(/\S{30,}/,'<span class="longword">$&</span>')
					$chat.append $("<div class='message'><div class='source'>#{msg.prefix}</div><div class='text'>#{msg.command} #{msg.params.join(' ')}</div></div>")
					if scroll
						cont.scrollTop(1000000000)
				socket.on 'disconnect', ->
	body ->
		div id: 'main', ->
			div id: 'chat-container', ->
				div id: 'chat'
		div id: 'entry', ->
			input id: 'cmd'