const express = require('express')
const router = express.Router()
const { doQuery } = require('../functions')

router.get('/', async (req, res, next) => {
  if (req.session.logged) {
    res.render('home', {
      theme: req.session.theme
    })
  } else res.redirect('/login')
})

router.get('/logout', (req, res, next) => {
  //req.session.destroy()
  req.session.logged = false
  req.session.id = null
  req.session.user = null
  res.redirect('/login')
})

module.exports = router
