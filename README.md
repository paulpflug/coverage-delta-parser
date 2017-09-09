# coverage-delta-parser

parses chromes `CSS.takeCoverageDelta()` into critical and uncritical css.

uses [postcss](http://postcss.org/)

### Install

```sh
npm install --save coverage-delta-parser
```

### Usage

```js
parser = require("coverage-delta-parser")
{critical, uncritical} = await parser({
  coverage: coverage,          // result of CSS.takeCoverageDelta()
  CSS: CSS,                    // CSS of chrome-remote-interface
  styleSheetIds: styleSheetIds // (optional) array of styleSheetIds to filter
  minify: false                // (optional) to strip no significant whitespace
})
// critical and uncritical are two postcss root objects
// http://api.postcss.org/Root.html
// get css like this:
critical.toString() 
```

### Example
```js
{launch} = require("chrome-launcher")
remoteInterface = require("chrome-remote-interface")
parser = require("coverage-delta-parser")

chromeInstance = await launch({chromeFlags: ["--disable-gpu","--headless"]})
{DOM, CSS, Page} = await remoteInterface({port: chromeInstance.port})

await Promise.all([DOM.enable(), CSS.enable(), Page.enable()])
{frameId} = await Page.navigate({url: "about:blank"})
await CSS.startRuleUsageTracking()
onceParsed = new Promise( resolve => CSS.styleSheetAdded(resolve))
await Page.setDocumentContent({
  frameId: frameId, 
  html: "<head><style type='text/css'>body{height: 20px}></style></head><body></body>"
})
await onceParsed
{coverage} = await CSS.takeCoverageDelta()

{critical, uncritical} = await parser({coverage: coverage, CSS:CSS})

await chromeInstance.kill()
```

## License
Copyright (c) 2017 Paul Pflugradt
Licensed under the MIT license.
