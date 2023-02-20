import moment from 'moment'
import webManifest from './manifest.webmanifest'
import logoPNG from './logo.png'

import React, { Component } from 'react'
import ReactDOM from 'react-dom/client'

import App from './App'

qs = (name) ->
  url = window.location.href
  name = name.replace(/[\[\]]/g, '\\$&')
  regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)')
  results = regex.exec(url);
  if not results or not results[2]
    return null
  return decodeURIComponent(results[2].replace(/\+/g, ' '))

window.localdonData = null

updateLastUpdated = ->
  # console.log "update setInterval"
  if window.localdonData?
    document.getElementById("header").innerHTML = "Last Updated: #{moment(window.localdonData.updated).fromNow()}"

window.onload = ->
  ua = navigator.userAgent
  console.log "UA: #{ua}"
  if ua.indexOf("Chrome") == -1
    console.log "Safari'ifying body"
    bodyElement = document.getElementsByTagName('body')[0]
    bodyElement.style.position = 'fixed'
    bodyElement.style.left = 0
    bodyElement.style.top = 0
    bodyElement.style.right = 0
    bodyElement.style.bottom = 0

  source = qs("src")
  if not source?
    source = "data"

  sourceJSON = "#{source}.json"

  try
    window.localdonData = await (await fetch(sourceJSON)).json()
    updateLastUpdated()
    setInterval ->
      updateLastUpdated()
    , 60000
    app = new App
    root = ReactDOM.createRoot(document.getElementById('root'))
    root.render(React.createElement(App))
  catch err
    document.getElementById("header").innerHTML = "ERROR: #{err}"
