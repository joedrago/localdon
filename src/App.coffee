import moment from 'moment'

import React, { Component } from 'react'

import { ThemeProvider, createTheme } from '@mui/material/styles'

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

import Stack from '@mui/material/Stack'
import Pagination from '@mui/material/Pagination'

import { el } from './reactutils'

qs = (name) ->
  url = window.location.href
  name = name.replace(/[\[\]]/g, '\\$&')
  regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)')
  results = regex.exec(url);
  if not results or not results[2]
    return null
  return decodeURIComponent(results[2].replace(/\+/g, ' '))

POSTS_PER_PAGE = qs("c")
if not POSTS_PER_PAGE?
  POSTS_PER_PAGE = 20

darkTheme = createTheme {
  palette:
    mode: 'dark'
}

class App extends Component
  constructor: (props) ->
    super(props)

    @state =
      width: window.innerWidth
      height: window.innerHeight
      hash: location.hash
      page: 1
      drawerOpen: false

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
      page: 1
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

  onPage: (event, page) ->
    @setState {
      page: page
    }
    window.scrollTo(0, 0)

  render: ->
    if not window.localdonData?
      return []

    postdivs = []

    filters = null
    filter = @state.hash
    if filter? and filter.charAt(0) == "#"
      filter = filter.substr(1)
      if filter.length > 0
        filters = filter.split(/\|/)

    filtered = []
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
      filtered.push post

    totalPages = Math.ceil(filtered.length / POSTS_PER_PAGE)
    postsToSkip = (@state.page - 1) * POSTS_PER_PAGE
    console.log "@state.page #{@state.page}, postsToSkip: #{postsToSkip}"

    page = []

    firstIndex = postsToSkip
    lastIndex = postsToSkip + POSTS_PER_PAGE - 1
    if lastIndex >= filtered.length
      lastIndex = filtered.length - 1
    for postIndex in [firstIndex..lastIndex]
      page.push filtered[postIndex]

    for post in page
      origPost = post
      if post.reblog?
        post = post.reblog

      matches = post.url.match(/\/([^\/]+\/[^\/]+)$/)
      postSuffix = matches[1]

      origPostFrom = ""
      if origPost.from?
        origPostFrom = "@#{origPost.from}"

      postFrom = ""
      if post.from?
        postFrom = "@#{post.from}"

      if origPost.reblog?
        postReblogClass = "postreblog"
        postReblogContent = [
          el 'a', {
                  key: "reblog#{origPost.id}"
                  href: origPost.account.url
                  className: "postrebloglink"
                }, "Reblog: #{origPost.account.acct}#{origPostFrom}"
        ]
      else
        postReblogClass = ""
        postReblogContent = []

      postDisplayName = post.account.display_name
      if postDisplayName.length < 1
        postDisplayName = post.account.username

      attachments = []
      if post.media_attachments?
        for attachment, attachmentIndex in post.media_attachments
          switch attachment.type
            when 'video'
              if attachment.html
                attachments.push el 'div', {
                  key: "p#{post.id}embed#{attachmentIndex}"
                  className: "postembed"
                  dangerouslySetInnerHTML: { __html: attachment.html }
                }
              else
                attachments.push el Stack, {
                  key: "videoembedstack#{post.id}#{attachmentIndex}"
                  alignItems: "center"
                }, el 'video', {
                  key: "attachembed#{attachment.id}#{attachmentIndex}"
                  className: "attachvideo"
                  controls: true
                }, [
                  el 'source', {
                    src: attachment.url
                    type: "video/mp4"
                  }
                ]
            when 'image'
              if attachment.html
                attachments.push el Stack, {
                  key: "imageembedstack#{post.id}#{attachmentIndex}"
                  alignItems: "center"
                }, el 'div', {
                  key: "p#{post.id}embed"
                  className: "postembed"
                  dangerouslySetInnerHTML: { __html: attachment.html }
                }
              else
                previewUrl = attachment.preview_url
                if not previewUrl?
                  previewUrl = attachment.url
                attachments.push el Stack, {
                  key: "previewembedstack#{post.id}#{attachmentIndex}"
                  alignItems: "center"
                }, el 'a', {
                  key: "attachlink#{attachment.id}#{attachmentIndex}"
                  href: attachment.url
                  className: "attachimagelink"
                }, [
                  el 'img', {
                    key: "attachpreview#{attachment.id}#{attachmentIndex}"
                    src: previewUrl
                    className: "attachimage"
                  }
                ]

      if post.card?
        if post.card.html? and (post.card.html.length > 0)
          preview = el 'div', {
            className: "cardembed"
            dangerouslySetInnerHTML: { __html: post.card.html }
          }
        else if post.card.image?
          preview = el 'img', {
            className: "cardimage"
            src: post.card.image
          }

        attachments.push el 'div', {
          className: "card"
        }, [
          el 'a', {
            className: "cardtitle"
            href: post.card.url
          }, post.card.title
          el 'div', {
            className: "carddesc"
          }, post.card.description
          preview
        ]

      postdivs.push el 'div', {
        key: "p#{post.id}con"
        className: "postcon"
      }, [
        el 'div', {
          key: "p#{post.id}status"
          className: "poststatus"
        }, [
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
              }, postDisplayName

              el 'a', {
                key: "p#{post.id}acct"
                className: "postacct"
                href: post.account.url
              }, "#{post.account.acct}#{postFrom}"
            ]
          ]
        ]

        el 'div', {
          key: "p#{post.id}content"
          className: "postcontent"
          dangerouslySetInnerHTML: { __html: post.content }
        }
        ...attachments

        el 'a', {
          key: "p#{post.id}right"
          className: "postright"
          href: post.url
        }, moment(post.created_at).fromNow()

        el 'div', {
          key: "p#{post.id}reblog"
          className: postReblogClass
        }, postReblogContent

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
            href: "##{origPost.account.username}"
          }, el PersonIcon

          el 'a', {
            key: "onlyfeed"
            title: 'Show all from this Feed'
            href: "##{post.from}"
          }, el StorageIcon
        ]
      ]

    if totalPages > 1
      paginationTop = [
        el Stack, {
          key: "pagstacktop"
          alignItems: "center"
        }, el Pagination, {
          key: "pagtop"
          color: "primary"
          page: @state.page
          count: totalPages
          onChange: @onPage.bind(this)
        }
      ]
      paginationBot = [
        el Stack, {
          key: "pagstackbot"
          alignItems: "center"
        }, el Pagination, {
          key: "pagbot"
          color: "primary"
          page: @state.page
          count: totalPages
          onChange: @onPage.bind(this)
        }
      ]
    else
      paginationTop = []
      paginationBot = []

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

    return el ThemeProvider, {
      theme: darkTheme
    }, el 'div', {
        key: 'appcontainer'
    }, [
      ...paginationTop
      postscontainer
      ...paginationBot
      drawer
      menuButton
    ]

export default App
