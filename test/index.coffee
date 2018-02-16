{test, after} = require "snapy"

{launch} = require "chrome-launcher"
remoteInterface = require "chrome-remote-interface"

fs = require "fs"

html = fs.readFileSync("./test/_test.html","utf8")

parser = require "../src/parser.coffee"

launched = launch chromeFlags: ["--disable-gpu","--headless"]

after =>
  launched.then (instance) => instance.kill()

test (snap) ->
  @timeout(5000)
  launched.then (instance) =>
    {DOM, CSS, Page} = await remoteInterface port: instance.port
    await Promise.all [DOM.enable(), CSS.enable(), Page.enable()]
    {frameId} = await Page.navigate url: "about:blank"
    await CSS.startRuleUsageTracking()
    onceParsed = new Promise (resolve) =>
      CSS.styleSheetAdded resolve
    await Page.setDocumentContent frameId: frameId, html: html
    await onceParsed
    {coverage} = await CSS.takeCoverageDelta()
    snap promise: parser coverage: coverage, CSS:CSS