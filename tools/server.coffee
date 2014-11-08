connect = require 'connect'
serveStatic = require 'serve-static'
connect()
  .use serveStatic process.argv[2]
  .listen 8080
