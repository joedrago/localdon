fs = require 'fs'
http = require 'http'
https = require 'https'
moment = require 'moment'
URL = require 'url'

console.log "CWD: #{__dirname}"
process.chdir(__dirname)

POST_COUNT = 60

idCache = {}
if fs.existsSync("idcache.json")
  idCache = JSON.parse(fs.readFileSync("idcache.json", "utf8"))

sleep = (ms) ->
  return new Promise (resolve) ->
    setTimeout(resolve, ms)

syntax = ->
  console.log "Syntax: harvest [-l] [CONFIG]"
  process.exit(0)

# download = (url) ->
#   return new Promise (resolve, reject) ->
#     resolve(JSON.parse(fs.readFileSync("hax.json", "utf8")))

download = (url) ->
  return new Promise (resolve, reject) ->
    if URL.parse(url).protocol == null
      url = 'http://' + url
      req = http
    else if URL.parse(url).protocol == 'https:'
      req = https
    else
      req = http

    request = req.get url, (res) ->
      rawJSON = ""
      res.on 'data', (chunk) ->
        rawJSON += chunk
      res.on 'error', ->
        console.log "Download Error: #{url}"
        resolve(null)
      res.on 'end', ->
        data = null
        try
          data = JSON.parse(rawJSON)
        catch
          console.log "ERROR: Failed to talk to parse JSON: #{rawJSON}"
          return
        resolve(data)

lookupID = (username, server) ->
  return new Promise (resolve, reject) ->
    follow = "#{username}@#{server}"
    if idCache[follow]?
      console.log "ID[#{follow}]: #{idCache[follow]} (Cached)"
      resolve(idCache[follow])
      return

    url = "https://#{server}/api/v1/accounts/lookup?acct=#{username}"
    data = await download(url)
    if data?
      idCache[follow] = data.id
      console.log "ID[#{follow}]: #{idCache[follow]} (Lookup)"
      resolve(idCache[follow])
    else
      resolve(null)

harvest = (config) ->
  now = moment().format()
  console.log "Harvesting: #{now}"

  all = []
  for server in config.servers
    data = []
    maxID = null
    postCount = 0
    loop
      console.log "Harvesting from #{server}... (#{postCount} posts so far)"
      url = "https://#{server}/api/v1/timelines/public?local=true&limit=#{POST_COUNT}"
      if maxID?
        url += "&max_id=#{maxID}"
      page = await download(url)
      if not page?
        console.error "Failed to get data from server: #{server}"
        continue

      page.sort (a, b) ->
        d = moment(b.created_at).diff(a.created_at)
        if d != 0
          return d
        return a.url.localeCompare(b.url)

      data = data.concat(page)

      postCount += page.length
      if page.length > 1
        maxID = page[page.length - 1].id
      else
        break

      if postCount >= POST_COUNT
        console.log "Harvested #{postCount} posts from #{server}."
        break

    for d in data
      d.from = server
    all = all.concat(data)

    console.log "Harvested #{data.length} entries from #{server}"

  for follow in config.follows
    console.log "Harvesting follow: #{follow}"
    pieces = follow.split(/@/)
    if pieces.length != 2
      console.log "Bad follow format: #{follow}"
      continue

    username = pieces[0]
    server = pieces[1]

    id = await lookupID(username, server)
    if not id?
      console.log "Can't find ID from user: #{follow}"
      continue

    data = []
    maxID = null
    postCount = 0
    loop
      console.log "Harvesting user @#{username}@#{server} (ID:#{id})... (#{postCount} posts so far)"
      url = "https://#{server}/api/v1/accounts/#{id}/statuses?limit=#{POST_COUNT}"
      if maxID?
        url += "&max_id=#{maxID}"
      page = await download(url)
      if not page?
        console.error "Failed to get data from server: #{server}"
        continue

      page.sort (a, b) ->
        d = moment(b.created_at).diff(a.created_at)
        if d != 0
          return d
        return a.url.localeCompare(b.url)

      data = data.concat(page)

      postCount += page.length
      if page.length > 1
        maxID = page[page.length - 1].id
      else
        break

      if postCount >= POST_COUNT
        console.log "Harvested #{postCount} posts from @#{username}@#{server}."
        break

    for d in data
      d.from = server
    all = all.concat(data)

  # filter dupes
  seen = {}
  deduped = []
  for p in all
    if seen[p.url]
      # console.log "Deduping: #{p.url}"
    else
      seen[p.url] = true
      deduped.push p
  all = deduped

  all.sort (a, b) ->
    d = moment(b.created_at).diff(a.created_at)
    if d != 0
      return d
    return a.url.localeCompare(b.url)

  console.log "Writing #{all.length} deduplicated posts..."

  localdonData =
    posts: all
    servers: config.servers
    updated: now

  name = config.name
  if not name?
    name = "data"
  outputFilename = "dist/#{name}.json"
  fs.writeFileSync(outputFilename, JSON.stringify(localdonData))
  console.log "Wrote: #{outputFilename}"

main = ->
  argv = process.argv.slice(2)
  if argv.length < 1
    return syntax()

  configFilename = null
  loopForever = false
  for arg in argv
    if arg == "-l"
      loopForever = true
    else
    configFilename = arg

  if not configFilename?
    return syntax()

  config = JSON.parse(fs.readFileSync(configFilename, "utf8"))

  loop
    await harvest(config)
    if loopForever
      console.log "---\nWaiting 5 minutes..."
      await sleep(5 * 60 * 1000)
    else
      break

  fs.writeFileSync("idcache.json", JSON.stringify(idCache))

main()
