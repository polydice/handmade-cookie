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
HandmadeCookie = (options, isInit) ->
  _toString = Object::toString
  opts = options || {}
  theCookie = this
  # extend opts
  for key, value of HandmadeCookie.defaults
    ((key, val, newVal) ->
      cond = _toString.call(val) is _toString.call(newVal)
      opts[key] = if cond then newVal else val
    )(key, value, opts[key])

  onUpdate = opts.onUpdate
  opts.onUpdate = (isUpdate, newData, oldData) ->
    ( newData.times is 1 ) and newData.lastDate = oldData.today
    newData.times = if isUpdate then ++newData.times else newData.times
    onUpdate(isUpdate, newData, oldData)

  if storage[opts.name]
    return storage[opts.name]
  data = storageControl.getItem opts.name
  storage[opts.name] = @
  @options = opts
  isInit and @update(opts.data)
  @

HandmadeCookie.prototype =
  constructor: HandmadeCookie
  toJson: ->
    JSON.parse storageControl.getItem @options.name
  get: (attr='') ->
    data = JSON.parse storageControl.getItem @options.name
    if typeof data[attr] isnt "undefined" then data[attr] else undefined
  update: (vals = {}, date = new Date()) ->
    options = @options
    oldData = JSON.parse storageControl.getItem options.name
    beUpdate = false
    newData = {}
    _toString = Object::toString
    hasOwnProperty = Object::hasOwnProperty

    isEmpty = (obj) ->
      return true  unless obj?
      return false  if obj.length and obj.length > 0
      return true  if obj.length is 0
      for key of obj
        return false  if hasOwnProperty.call(obj, key)
      true

    if oldData
      newData = @parse(date)
      beUpdate = @cond(oldData, newData, options.precision) or !isEmpty(vals)
    else
      oldData = @parse(date)
      data = oldData
      data.times = 1

    if beUpdate
      data = {}
      for key, value of oldData
        ((key, val, newVal) ->
          cond = _toString.call(val) is _toString.call(newVal)
          data[key] = if cond then newVal else val
        )(key, value, newData[key])
      data.lastDate = oldData.today
      for key, value of vals
        ((key, val) ->
          data[key] = val
        )(key, value)
    else
      data = oldData
      if !isEmpty vals
        for key, value of vals
          ((key, val) ->
            data[key] = val
          )(key, value)
    data = options.onUpdate beUpdate, data, oldData
    storageControl.setItem options.name, JSON.stringify( data )
    beUpdate
  parse: (date = new Date()) ->
    today: Math.floor( date.getTime() / 1000 )
  cond: (oldData, newData, precision) ->
    oldToday = Math.floor( oldData.today / precision )
    newToday = Math.floor( newData.today / precision )
    oldToday isnt newToday
  die: () ->
    name = @options.name
    storageControl.removeItem name
    storage[name] and (delete storage[name])
    true

HandmadeCookie.defaults =
  name: "visitInfo"
  precision: 24 * 60 * 60 # sec
  data: {}
  onUpdate: (isUpdate, newData, oldData) ->
    newData
HandmadeCookie.get = (name) ->
  if storage[name] then storage[name] else null
HandmadeCookie.pluck = ->
  result = []
  for key, value of storage
    result.push key
  result
HandmadeCookie.register = (name, data) ->
  if !name or !data
    return false
  result = HandmadeCookie.get(name)
  if !result and storageControl.getItem(name)
    _toString = Object::toString
    unixToday = Math.floor( new Date().getTime() / 1000 )
    if !data.today
      data =
        val: data
        today: unixToday
        lastDate: unixToday
        times: 1
      storageControl.setItem(name, JSON.stringify(data))
    options =
      name: name
    result = new HandmadeCookie(options)
  result
HandmadeCookie.check2clean = (precision = 24 * 60 * 60, cond = 0) ->
  for key, value of storage
    ((perStorge, key)->
      lastDate = perStorge.get("lastDate")
      lastDate = Math.floor( lastDate / precision )
      realToday = Math.floor( new Date().getTime() / precision / 1000 )
      ( realToday - lastDate >= cond ) and perStorge.die()
    )(value, key)
   @

###################################
#     Exposing HandmadeCookie
###################################

# CommonJS module is defined
module.exports = HandmadeCookie if @hasModule

#global ender:false 
# here, `this` means `window` in the browser, or `global` on the server
# add `HandmadeCookie` as a global object via a string identifier,
# for Closure Compiler "advanced" mode
@HandmadeCookie = HandmadeCookie  if typeof ender is "undefined"

#global define:false 
if typeof define is "function" and define.amd
  define "HandmadeCookie", [], ->
    HandmadeCookie