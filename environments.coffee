module.exports =

  production:
    port: process.env.PORT or 5000

    redis:
      host: 'localhost'
      port: 6379

  development:
    port: process.env.PORT or 5000

    redis:
      host: 'localhost'
      port: 6379
