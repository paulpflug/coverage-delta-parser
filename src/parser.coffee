postcss = require "postcss"

module.exports = ({coverage, styleSheetIds, CSS, minify}) =>
  sheetsWithUsedRules = coverage
    .filter (rule) => 
      rule.used and (not styleSheetIds? or ~styleSheetIds.indexOf(rule.styleSheetId))
    .reduce ((sheets, rule) => 
      (sheets[rule.styleSheetId] ?= []).push rule
      return sheets
      ),{}
  rawText = []
  for sheet, rules of sheetsWithUsedRules
    {text} = await CSS.getStyleSheetText styleSheetId: sheet
    lastOffset = 0
    for rule in rules.sort((a,b) => a.startOffset - b.startOffset)
      rawText.push text.slice lastOffset, s if (s = rule.startOffset) > lastOffset
      rawText.push text.slice(s, lastOffset = rule.endOffset).replace(/;*}/,";used:true;}")
    rawText.push text.slice lastOffset, text.length if lastOffset < text.length
  unless minify? and minify == false
    unless typeof minify == "function"
      minify = (str) => str.replace(/\s*([,:;{}])\s*/g, "$1").replace(/(^\s+)|(\s+$)/g,"")
    rawText = await Promise.all rawText.map minify
  criticalRoot = postcss.parse(rawText.join(""))
  uncriticalRoot = criticalRoot.clone()
  criticalRoot.walkRules (rule) =>
    rule.remove() if rule.every (decl) => not (decl.prop == "used" and decl.remove())
  criticalRoot.walkAtRules (node) => 
    node.remove() if node.name == "media" and not node.nodes.length
  uncriticalRoot.walkRules (rule) => 
    rule.remove() unless rule.every (decl) =>  decl.prop != "used"
  uncriticalRoot.walkAtRules (node) => 
    node.remove() if node.name == "media" and not node.nodes.length
  return critical: criticalRoot, uncritical: uncriticalRoot


