chai = require "chai"
should = chai.should()

{launch} = require "chrome-launcher"
remoteInterface = require "chrome-remote-interface"

parser = require "../src/parser.coffee"

html = """
<!DOCTYPE html>
<html>
<head>
  <style type="text/css">
    body {
      height: 20px
    }
    .not-used {
      height: 20px
    }
    @media only screen and (max-width :600px) {
      body {
        width: 20px
      }
      .not-used {
        width: 20px
      }
    }
  </style>
</head>
<body>
</body>
</html>
"""
chromeInstance = null
describe "coverage-delta-parser", =>
  before => chromeInstance = await launch chromeFlags: ["--disable-gpu","--headless"]
  after => chromeInstance?.kill?()
  it "should work", =>
    {DOM, CSS, Page} = await remoteInterface port: chromeInstance.port
    await Promise.all [DOM.enable(), CSS.enable(), Page.enable()]
    {frameId} = await Page.navigate url: "about:blank"
    await CSS.startRuleUsageTracking()
    onceParsed = new Promise (resolve) =>
      CSS.styleSheetAdded resolve
    await Page.setDocumentContent frameId: frameId, html: html
    await onceParsed
    {coverage} = await CSS.takeCoverageDelta()
    {critical, uncritical} = await parser coverage: coverage, CSS:CSS
    critical.toString().should.equal "body{height:20px;}"
    uncritical.toString().should.equal ".not-used{height:20px}@media only screen and (max-width:600px){body{width:20px}.not-used{width:20px}}"