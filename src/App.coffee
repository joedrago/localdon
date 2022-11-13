import moment from 'moment'

import React, { Component } from 'react'

import Box from '@mui/material/Box'
import Drawer from '@mui/material/Drawer'
import Divider from '@mui/material/Divider'

import Button from '@mui/material/Button'
import IconButton from '@mui/material/IconButton'

import List from '@mui/material/List'
import ListItem from '@mui/material/ListItem'
import ListItemButton from '@mui/material/ListItemButton'
import ListItemIcon from '@mui/material/ListItemIcon'
import ListItemText from '@mui/material/ListItemText'
import Switch from '@mui/material/Switch'

import AllInclusiveIcon from '@mui/icons-material/AllInclusive'
import LinkIcon from '@mui/icons-material/Link'
import MenuIcon from '@mui/icons-material/Menu'
import PersonIcon from '@mui/icons-material/Person'
import StorageIcon from '@mui/icons-material/Storage'

import { el } from './reactutils'

class App extends Component
  constructor: (props) ->
    super(props)

    @state =
      width: window.innerWidth
      height: window.innerHeight
      hash: location.hash
      drawerOpen: false

    console.log @state

  componentDidMount: ->
    window.addEventListener("resize", @onResize.bind(this))
    window.addEventListener("orientationchange", @onResize.bind(this))
    window.addEventListener("hashchange", @onHash.bind(this))

  onResize: ->
    @setState {
      width: window.innerWidth
      height: window.innerHeight
    }

  onHash: ->
    @setState {
      hash: location.hash
    }

  createDrawerButton: (keyBase, iconClass, text, onClick) ->
    buttonPieces = [
      el ListItemIcon, {
        key: "#{keyBase}ItemIcon"
      }, [
        el iconClass, {
          key: "#{keyBase}Icon"
        }
      ]
      el ListItemText, {
        key: "#{keyBase}Text"
        primary: text
        }, []
    ]

    return el ListItem, {
      key: "#{keyBase}Item"
      disablePadding: true
    }, [
      el ListItemButton, {
        key: "#{keyBase}Button"
        onClick: onClick
        disabled: false
      }, buttonPieces
    ]

  render: ->
    header = el 'div', {
      key: 'header'
      className: 'header'
    }, "Last Updated: #{moment(localdonData.updated).fromNow()}"

    postdivs = []

    filters = null
    filter = @state.hash
    if filter? and filter.charAt(0) == "#"
      filter = filter.substr(1)
      if filter.length > 0
        filters = filter.split(/\|/)

    for post in window.localdonData.posts
      if filters?
        found = false
        for filter in filters
          if post.url.indexOf(filter) != -1
            found = true
            break
          if post.from.indexOf(filter) != -1
            found = true
            break
        if not found
          continue

      matches = post.url.match(/\/([^\/]+\/[^\/]+)$/)
      postSuffix = matches[1]

      attachments = []
      if post.media_attachments?
        for attachment in post.media_attachments
          if attachment.type == 'image'
            previewUrl = attachment.preview_url
            if not previewUrl?
              previewUrl = attachment.url
            attachments.push el 'a', {
              key: "attachlink#{attachment.id}"
              href: attachment.url
              className: "attachimage"
            }, [
              el 'img', {
                key: "attachpreview#{attachment.id}"
                src: previewUrl
              }
            ]

      postdivs.push el 'div', {
        key: "p#{post.id}con"
        className: "postcon"
      }, [
        el 'div', {
          key: "p#{post.id}status"
          className: "poststatus"
        }, [
          el 'a', {
            key: "p#{post.id}right"
            className: "postright"
            href: post.url
          }, moment(post.created_at).fromNow()

          el 'div', {
            key: "p#{post.id}left"
            className: "postleft"
          }, [
            el 'img', {
              key: "p#{post.id}avatar"
              className: "postavatar"
              src: post.account.avatar
            }

            el 'div', {
              key: "p#{post.id}stack"
              className: "poststack"
            }, [
              el 'div', {
                key: "p#{post.id}display"
                className: "postdisplay"
              }, post.account.display_name

              el 'a', {
                key: "p#{post.id}acct"
                className: "postacct"
                href: post.account.url
              }, "#{post.account.acct}@#{post.from}"
            ]
          ]
        ]

        el 'div', {
          key: "p#{post.id}content"
          className: "postcontent"
          dangerouslySetInnerHTML: { __html: post.content }
        }
        ...attachments

        el 'div', {
          key: "p#{post.id}footer"
          className: "postfooter"
        }, [
          el 'a', {
            key: "onlypost"
            title: 'Localdon link to this Post'
            href: "##{postSuffix}"
          }, el LinkIcon

          el 'a', {
            key: "onlyperson"
            title: 'Show all from this Person'
            href: "##{post.account.username}"
          }, el PersonIcon

          el 'a', {
            key: "onlyfeed"
            title: 'Show all from this Feed'
            href: "##{post.from}"
          }, el StorageIcon
        ]
      ]

    postscontainer = el 'div', {
      key: 'postscontainer'
      className: 'postscontainer'
    }, postdivs

    drawerItems = []

    drawerItems.push @createDrawerButton "all", AllInclusiveIcon, "All Posts", =>
      location.hash = "#"
      @setState {
        drawerOpen: false
      }

    drawerItems.push el Divider, { key: "allDivider" }

    for server in window.localdonData.servers
      do (server) =>
        drawerItems.push @createDrawerButton "server_#{server}", StorageIcon, "#{server}", =>
          location.hash = "##{server}"
          @setState {
            drawerOpen: false
          }

    drawer = el Drawer, {
      key: 'drawer'
      anchor: 'right'
      open: @state.drawerOpen
      onClose: =>
        @setState {
          drawerOpen: false
        }
    }, [
      el Box, {
        key: 'drawerBox'
        role: 'presentation'
      }, [
        el List, {
          key: 'drawerList'
        }, drawerItems
      ]
    ]

    menuButton = el IconButton, {
      key: 'menuButton'
      size: 'large'
      style:
        position: 'fixed'
        top: '10px'
        right: '10px'
        color: '#fff'
      onClick: =>
        @setState {
          drawerOpen: true
        }
    }, [
      el MenuIcon, { key: 'menuButtonIcon' }
    ]

    return el 'div', {
        key: 'appcontainer'
      }, [
        header
        postscontainer
      drawer
      menuButton
    ]

export default App
