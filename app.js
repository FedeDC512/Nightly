const createError = require('http-errors')
const express = require('express')
const session = require('express-session')
const path = require('path')
const logger = require('morgan')
const crypto = require('crypto')
const compression = require('compression')
const cors = require("cors")

const loginRouter = require('./routes/login')
const homeRouter = require('./routes/home')

const app = express()

app.set('views', path.join(__dirname, 'views'))
app.set('view engine', 'ejs')

var genSecret = crypto.createHash("sha256").update(Date.now().toString()).digest("hex")

// https://expressjs.com/en/advanced/healthcheck-graceful-shutdown.html
// https://expressjs.com/en/advanced/best-practice-performance.html
// https://expressjs.com/en/advanced/best-practice-security.html
// https://medium.com/@nodepractices/were-under-attack-23-node-js-security-best-practices-e33c146cb87d

app.use(logger('dev'))
app.use(cors())
app.use(session({
  genid: req => genSecret,
  name: 'Nightly',
	secret: genSecret, // assicurarsi che si generi periodicamente
	resave: false,
	saveUninitialized: false,
  cookie: { secure: 'auto' }
}))
app.use(express.json())
app.use(express.urlencoded({ extended: false }))
app.use(compression())
app.use(express.static(path.join(__dirname, 'public')))

app.use('/', loginRouter)
app.use('/login', loginRouter)
app.use('/home', homeRouter)

app.use((req, res, next) => next(createError(404)))

app.use((err, req, res, next) => {
  res.locals.message = err.message
  res.locals.error = req.app.get('env') === 'development' ? err : {}
  console.log(err)
  res.status(err.status || 500)
  if (req.session.theme == null) req.session.theme = 'lightTheme'
  res.render('error', { 
    theme: req.session.theme,
    error: err.status
  })
})

module.exports = app
