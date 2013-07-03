describe "Testing HandmadeCookie", ->
  HandmadeCookie = window.HandmadeCookie

  beforeEach(->
    new HandmadeCookie(
      name: "demo",
      precision: 5
    , "init")
  )

  afterEach(->
    HandmadeCookie.check2clean(1, 1)
  )

  it "should be registered", ->
    expect( HandmadeCookie ).not.toEqual(null)

  it "should get empty array without registered", ->
    check2clean = ->
      HandmadeCookie.check2clean(1, 1)
      HandmadeCookie.pluck().length
    waitsFor(->
      !check2clean()
    , "Get empty array", 2000)

  it "should get correct array with registered demo", ->
    pluck = HandmadeCookie.pluck()
    expect(pluck.length).toBe(1)
    expect(/demo/.test( pluck.join() )).toBe(true)

  it "should get null if data not found", ->
    data = HandmadeCookie.get("tmp")
    expect(data).toBe(null)

  it "should get registered instance", ->
    demo = HandmadeCookie.get("demo")
    expect(demo.constructor is HandmadeCookie).toBe(true)

  it "shouldn't register without paramters", ->
    expect(HandmadeCookie.register()).toEqual(false)
    expect(HandmadeCookie.register("name")).toEqual(false)
    expect(HandmadeCookie.register(undefined, {})).toEqual(false)

  it "shouldn't register if exist, but get the instance", ->
    registeredDemo = HandmadeCookie.register("demo",
      test: "test"
    )
    expect(registeredDemo.constructor is HandmadeCookie).toBe(true)
    expect(registeredDemo.get('test')).toBe(undefined)

  it "shouldn't registered if not in localStorage", ->
    registered = HandmadeCookie.register("unRegiester",
      string: "string"
      number: 123
      array: [1..5]
    )
    expect(registered).toBe(null)

  it "should registered if exist and in localStorage", ->
    storageControl = if localStorage then localStorage else docCookies
    data = JSON.stringify(
      "string": "string"
      "number": 123
      "array": [1..5]
    )
    storageControl.setItem "register", data
    registered = HandmadeCookie.register("register", JSON.parse(data))
    expect(registered.constructor is HandmadeCookie).toBe(true)
    val = registered.get("val")
    expect(val["string"]).toEqual("string")
    expect(val["number"]).toEqual(123)
    expect(val["array"]).toEqual([1, 2, 3, 4, 5])
    expect(registered.get("times")).toEqual(1)
    expect(registered.get("today")).toEqual(registered.get("lastDate"))

  it "shouldn't clear if condition is false", ->
    HandmadeCookie.check2clean()
    pluck = HandmadeCookie.pluck()
    expect(/demo/.test( pluck.join() )).toBe(true)

  it "should clear if condition is true", ->
    check2clean = ->
      HandmadeCookie.check2clean(1, 1)
      pluck = HandmadeCookie.pluck()
      /demo/.test( pluck.join() )
    waitsFor(->
      !check2clean()
    , "The demo is removed", 2000)

describe "Testing HandmadeCookie instance", ->
  HandmadeCookie = window.HandmadeCookie
  storageControl = null
  beforeEach(->
    storageControl = if localStorage then localStorage else docCookies
  )
  afterEach(->
    HandmadeCookie.check2clean(1, 1)
  )

  it "should have correct constructor", ->
    new HandmadeCookie(
      name: "demo",
      precision: 5
    , "init")
    demo = HandmadeCookie.get("demo")
    expect(demo.constructor is HandmadeCookie).toBe(true)

  it "should have correct init values", ->
    new HandmadeCookie(
      name: "demo",
      precision: 5
    , "init")
    demo = storageControl.getItem("demo")
    expect(demo).not.toEqual(null)
    demo = JSON.parse(demo)
    expect(demo.times).toEqual(1)
    expect(typeof demo.today).toEqual("number")
    expect(demo.today).toEqual(demo.lastDate)

  it "doesn't init again if initialized", ->
    new HandmadeCookie(
      name: "demo",
      precision: 5
    , "init")
    firstDemo = JSON.parse( storageControl.getItem("demo") )
    new HandmadeCookie(
      name: "demo",
      precision: 5
    , "init")
    secondDemo = JSON.parse( storageControl.getItem("demo") )
    expect(firstDemo.times).toEqual(1)
    expect(secondDemo.times).toEqual(firstDemo.times)
    expect(secondDemo.today).toEqual(firstDemo.today)
    expect(secondDemo.lastDate).toEqual(firstDemo.lastDate)

  it "should parse to JSON format", ->
    demo = new HandmadeCookie(
      name: "demo",
      precision: 5
    , "init")
    data = demo.toJson()
    isEmpty = (obj) ->
      return true  unless obj?
      return false  if obj.length and obj.length > 0
      return true  if obj.length is 0
      for key of obj
        return false  if hasOwnProperty.call(obj, key)
      true
    expect(isEmpty(data)).toEqual(false)
    expect(data.times).toEqual(1)
    expect(typeof data.today).toEqual("number")
    expect(data.today).toEqual(data.lastDate)

  it "should get attribute", ->
    demo = new HandmadeCookie(
      name: "demo",
      precision: 5
    , "init")
    expect(demo.get("test")).toEqual(undefined)
    expect(demo.get("times")).toEqual(1)
    today = demo.get("today")
    expect(typeof today).toEqual("number")
    expect(demo.get("lastDate")).toEqual(today)

  it "should update unless over the time", ->
    demo = new HandmadeCookie(
      name: "demo",
      precision: 5
    , "init")
    waitsFor(->
      !demo.update()
    , "isnt updated", 2000)
    waitsFor(->
      demo.update()
    , "is updated", 5000)

  it "should update with new values", ->
    demo = new HandmadeCookie(
      name: "demo",
      precision: 600
    , "init")
    expect(demo.get("times")).toEqual(1)
    expect(demo.get("newVal")).toEqual(undefined)
    isUpdated = demo.update(
      "newVal": "This is a new value"
    )
    expect(isUpdated).toEqual(true)
    expect(demo.get("times")).toEqual(2)
    expect(demo.get("newVal")).toEqual("This is a new value")
    isUpdated = demo.update(
      "newVal": "Update the value"
    )
    expect(isUpdated).toEqual(true)
    expect(demo.get("times")).toEqual(3)
    expect(demo.get("newVal")).not.toEqual("This is a new value")
    expect(demo.get("newVal")).toEqual("Update the value")

  it "should be removed after clear", ->
    demo = new HandmadeCookie(
      name: "demo",
      precision: 5
    , "init")
    isEmpty = (obj) ->
      return true  unless obj?
      return false  if obj.length and obj.length > 0
      return true  if obj.length is 0
      for key of obj
        return false  if hasOwnProperty.call(obj, key)
      true
    expect(isEmpty(demo.toJson())).toEqual(false)
    expect(storageControl.getItem("demo")).not.toEqual(null)
    pluck = HandmadeCookie.pluck()
    expect(/demo/.test( pluck.join() )).toBe(true)
    demo.clear()
    pluck = HandmadeCookie.pluck()
    expect(storageControl.getItem("demo")).toEqual(null)
    expect(/demo/.test( pluck.join() )).toBe(false)
