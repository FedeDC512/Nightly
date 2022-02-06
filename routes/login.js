const express = require('express')
const crypto = require('crypto')
const router = express.Router()
const { doQuery } = require('../functions')

router.get('/', (req, res, next) => {
  if (req.session.theme == null) req.session.theme = 'lightTheme'
  res.render('login', { theme: req.session.theme })
})

router.post('/switchTheme', (req, res, next) => {
  req.session.theme = req.body.theme
  req.session.save()
})

router.post('/', async (req, res) => {
  let nick = req.body.nickname
  let psw = req.body.password
  if (nick && psw) {
    if (nick == "sabrim" && psw == "sabrify") res.redirect("https://zalweny26.github.io")
    if (nick == "alwe" && psw == "dany") res.redirect("https://zalweny26.github.io")
    if (nick == "gioza" && psw == "zang") res.redirect("https://zalweny26.github.io")
    if (nick == "fededc" && psw == "fededc") res.redirect("https://zalweny26.github.io")
    /*psw = crypto.createHash("sha256").update(psw).digest("hex")
    await doQuery('SELECT * FROM Utente WHERE Nickname = ? AND Password = ?', [nick, psw]).then(rs => {
      req.session.logged = true
      req.session.id = rs.UtenteID
      req.session.user = rs.Nickname
      res.redirect('/home')
    }).catch(() => res.send('Password sbagliata !'))*/
	} else res.send('Nome utente o password errati !')
  res.end()
})

module.exports = router
