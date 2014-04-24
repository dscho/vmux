http      = require('http')
https     = require('https')
fs        = require('fs')
ss        = require('socketstream')
everyauth = require('everyauth')
UUID      = require('uuid')
Redis     = require('redis')
crypto    = require('crypto')

env       = require('./environments')[ss.env]
redis = Redis.createClient(env.redis.port, env.redis.host)
ss.session.store.use 'redis', host: env.redis.host, port: env.redis.port

# Define a single-page client
ss.client.define "vmux",
  view: "app.jade"
  css:  ["libs", "app.styl"]
  code: ["libs", "app"]
  tmpl: "*"

# Code Formatters
ss.client.formatters.add require("ss-coffee")
ss.client.formatters.add require("ss-jade")
ss.client.formatters.add require("ss-stylus")

# Use server-side compiled Hogan (Mustache) templates. Others engines available
ss.client.templateEngine.use require("ss-hogan")

# Minimize and pack assets if you type: SS_ENV=production node app.js
ss.client.packAssets() if ss.env is "production"

ss.http.middleware.prepend ss.http.connect.bodyParser()
ss.http.middleware.append everyauth.middleware()

ss.http.middleware.append (req, res, next) ->
  return next() if req.url != '/login/success'

  res.writeHead(302, 'Location': req.session.redirectTo || '/home')
  res.end()

# Serve this client on the root URL
ss.http.route "/", (req, res) ->
  res.serveClient 'vmux'

# Guest login
ss.http.route "/auth/guest", (req, res) ->
  uuid = crypto.randomBytes(3).toString('hex')

  query = req.url.match(/screen_name=(\w+)/)
  screen_name = if query then query[1] else 'Guest'

  req.session.userId = uuid
  req.session.subscribed = false
  req.session.save()

  user = {id: uuid, uuid: uuid, screen_name: screen_name, guest: true}

  expiry = 60 * 60 * 24
  redis.setex "user:#{uuid}",   expiry, JSON.stringify(user)
  redis.setex "lookup:#{uuid}", expiry, uuid

  res.writeHead(302, 'Location': '/login/success')
  res.end()

# Start SocketStream
server = http.Server(ss.http.middleware)
server.listen env.port
ss.start server
