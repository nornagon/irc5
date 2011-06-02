doctype 5
html ->
	head ->
		meta charset: 'utf-8'
		title 'foo'
		script src: '/socket.io/socket.io.js'
		script src: 'https://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.js'
		link rel: 'stylesheet', href: '/static/style.css'
	body ->
		div id: 'main'
		###
		ul id: 'channels', ->
			li id: 'system', class: 'selected', 'System'
			li id: '#foobar', '#foobar'
		###
		div id: 'entry', ->
			div id: 'status'
			input id: 'cmd'
		script src: '/static/chat.js'
