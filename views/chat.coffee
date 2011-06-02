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
			border-right: 1px solid #222;
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
			background-color: black;
			position: fixed;
			bottom: 30px;
		}
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
			$ ->
				$chat = $('#chat')
				$('#cmd').focus()
				$(window).keydown (e) ->
					unless e.metaKey or e.ctrlKey
						e.currentTarget = $('#cmd')[0]
						$('#cmd').focus()
				socket = new io.Socket
				socket.connect()
				socket.on 'connect', ->
					console.log 'connected'
				socket.on 'message', (msg) ->
					cont = $('#chat-container')
					scroll = false
					if (cont.scrollTop() + cont.height() == cont[0].scrollHeight)
						scroll = true
					msg.params = msg.params.map (m) ->
						m.replace(/\S{30,}/,'<span class="longword">$&</span>')
					e = escapeHTML
					$chat.append $("""
					<div class='message'>
						<div class='source'>#{e msg.prefix}</div>
						<div class='text'>#{e msg.command} #{e msg.params.join(' ')}</div>
					</div>
					""")
					if scroll
						cont.scrollTop(1000000000)
				socket.on 'disconnect', ->
	body ->
		div id: 'main', ->
			div id: 'chat-container', ->
				div id: 'chat'
		div id: 'entry', ->
			div id: 'status'
			input id: 'cmd'
