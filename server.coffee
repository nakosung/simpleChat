# REQUIRE
express = require 'express'
http = require 'http'
fs = require 'fs'

#
app = express()
server = http.createServer(app)
io = (require 'socket.io').listen(server)

app.set 'views', "#{__dirname}/views"
app.engine 'html', require('ejs').renderFile

app.get '/', (req,res) ->
  res.render "index.html"

server.listen 8082, ->

usernames = {}
logs = []

setNickname = (socket,nickname,done) ->
  if socket.nickname isnt nickname
    if usernames[nickname] != undefined
      setNickname socket, nickname + '!'
    else
      usernames[nickname] = socket
      socket.nickname = nickname

io.sockets
  .on 'connection', (socket) ->
    console.log 'someone connected'

    chat = (entry) ->
      entry.time = Date.now()
      logs.shift() if logs.length > 10
      logs.push entry
      io.sockets.emit 'chat', entry

    socket.on 'newuser', (nickname) ->
      setNickname socket,nickname
      socket.emit 'chat', msg for msg in logs
      socket.emit 'addUser', nickname for nickname in Object.keys(usernames)
      io.sockets.emit 'addUser', socket.nickname
      chat text:"#{socket.nickname} has connected"

    socket.on 'nickname', (nickname,cb) ->
      console.log(nickname);
      console.log nickname?.length
      if nickname?.length > 0 and nickname?.length < 20
        old = socket.nickname
        setNickname socket, nickname
        chat text:"#{old} changed name '#{socket.nickname}'"
        io.sockets.emit 'renameUser', {old:old,new:socket.nickname}
        cb? undefined, socket.nickname
      else
        cb? 'tooshort_or_toolong', socket.nickname

    socket.on 'chat', (text,cb) ->
      chat
        sender:socket.nickname
        text:text
      cb? 'ok'

    socket.on 'typing', () ->
      socket.id

    socket.on 'disconnect', ->
      chat text:"#{socket.nickname} has disconnected"
      socket.broadcast.emit 'removeUser', socket.nickname
      delete usernames[socket.nickname]




