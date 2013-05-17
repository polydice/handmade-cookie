if window.HandmadeCookie
  return
unless window.JSON
  window.JSON =
    parse: (sJSON) ->
      eval("(" + sJSON + ")")
    stringify: (vContent) ->
      if (vContent instanceof Object)
        sOutput = ""
        if (vContent.constructor is Array)
          for value in vContent
            sOutput += this.stringify(vContent[nId]) + ","
          "[" + sOutput.substr(0, sOutput.length - 1) + "]"
        if (vContent.toString isnt Object.prototype.toString)
          return "\"" + vContent.toString().replace(/"/g, "\\$&") + "\""
        for sProp, value of vContent
          sOutput += "\"" + sProp.replace(/"/g, "\\$&") + "\":" + this.stringify(value) + ","
        return "{" + sOutput.substr(0, sOutput.length - 1) + "}"
      return if typeof vContent is "string" then "\"" + vContent.replace(/"/g, "\\$&") + "\"" else  String(vContent)
docCookies =
  getItem: (sKey) ->
    unescape(document.cookie.replace(new RegExp("(?:(?:^|.*;\\s*)" + escape(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=\\s*((?:[^;](?!;))*[^;]?).*)|.*"), "$1")) || null
  setItem: (sKey, sValue, vEnd, sPath, sDomain, bSecure) ->
    if (!sKey || /^(?:expires|max\-age|path|domain|secure)$/i.test(sKey))
      return false
    sExpires = ""
    if (vEnd)
      switch vEnd.constructor
        when Number
          sExpires = if vEnd is Infinity then "; expires=Fri, 31 Dec 9999 23:59:59 GMT" else "; max-age=" + vEnd
        when String
          sExpires = "; expires=" + vEnd
        when Date
          sExpires = "; expires=" + vEnd.toUTCString()
          document.cookie = escape(sKey) + "=" + escape(sValue) + sExpires + (if sDomain then "; domain=" + sDomain else "") + (if sPath then "; path=" + sPath else "") + (if bSecure then "; secure" else "")
    true
  removeItem: (sKey, sPath) ->
    if (!sKey || !this.hasItem(sKey))
      return false
    document.cookie = escape(sKey) + "=; expires=Thu, 01 Jan 1970 00:00:00 GMT" + (if sPath then "; path=" + sPath else "")
    true
  hasItem: (sKey) ->
    (new RegExp("(?:^|;\\s*)" + escape(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=")).test(document.cookie)

storageControl = if localStorage then localStorage else docCookies
storage = {}
HandmadeCookie = (options) ->
  _toString = Object.prototype.toString
  opts = options || {}
  theCookie = this
  # extend opts
  for key, value of HandmadeCookie.defaults
    ((key, val, newVal) ->
      cond = _toString.call(val) is _toString.call(newVal)
      opts[key] = if cond then newVal else val
    )(key, value, opts[key])
  if storage[opts.name]
    return storage[opts.name]
  data = storageControl.getItem opts.name
  storage[opts.name] = @
  @options = opts
  @update()

HandmadeCookie.prototype =
  constructor: HandmadeCookie
  get: (attr='') ->
    data = JSON.parse storageControl.getItem @options.name
    if typeof data[attr] isnt "undefined" then data[attr] else undefined
  update: (date = new Date()) ->
    options = @options
    oldData = JSON.parse storageControl.getItem options.name
    beUpdate = true
    newData = {}
    _toString = Object.prototype.toString
    if oldData
      newData = options.parse(date)
      beUpdate = options.cond(oldData, newData, options.precision)
      data = newData
    else
      oldData = options.parse(date)
      data = oldData
    if beUpdate
      data = {}
      for key, value of oldData
        ((key, val, newVal) ->
          cond = _toString.call(val) is _toString.call(newVal)
          data[key] = if cond then newVal else val
        )(key, value, newData[key])
    data = options.onUpdate beUpdate, data, oldData
    storageControl.setItem options.name, JSON.stringify( data )
    beUpdate
  clear: () ->
    name = @options.name
    storageControl.removeItem name
    storage[name] and (delete storage[name])
    true

HandmadeCookie.defaults =
  name: "visitInfo"
  precision: 24 * 60 * 60
  parse: (date = new Date()) ->
    today: Math.floor( date.getTime() / 1000 )
  cond: (oldData, newData, precision) ->
    oldToday = Math.floor( oldData.today / precision )
    newToday = Math.floor( newData.today / precision )
    oldToday isnt newToday
  onUpdate: (isUpdate, newData, oldData) ->
    newData.times and newData.lastDate = oldData.today
    newData.times = if isUpdate then ++newData.times else 1
    newData
HandmadeCookie.get = (name) ->
  if storage[name] then storage[name] else null

window.HandmadeCookie = HandmadeCookie