import os, strutils
type   GeneratorError* = object of Exception
include includes/langlist, templates/comments
var lang = ""

 ## this is a comment
proc generateText(lines: seq[string], glue:  string = "\n"): string =
  result = ""
  for line in lines:
    result &= line & glue

proc makeRulesTempl(langPrefix, langSuffix: string) =
  var source  = ""
  let
    opers = @[
      rules_comment,
      "let",
      "  rules" & langSuffix & " = { \"NAME\" : re\"regex\" }.toTable",
      "  replacements" & langSuffix & " =  { \"NAME\" : \"repl\"}.toTable",
      "  grammar" & langSuffix & " = \"{}\""
    ] 
  writeFile("rules/" & langPrefix & "porter.nim",generateText(opers,"\n")) 

proc makeWordLists(langPrefix, langSuffix: string) = 
  var source = ""
  let 
    stopwords = @[
      stopwords_comment,
      "let regularStopwords" & langSuffix & " = @[\"word1\", \"word2\"]"
    ]
    tests = @[
      tests_comment,
      "let",
      "  testSet" & langSuffix & " = @[(key: \"word1\", value: \"stem1\")]",
      "  testText" & langSuffix & " = \"\" "
    ]
  writeFile("wordlists/" & langPrefix & "stopwords.nim", generateText(stopwords))
  writeFile("tests/" & langPrefix & "test.nim", generateText(tests))

proc updateLangList(lang: string) =
  var 
    newList = newSeq[string]()
    source = "const languages = @[\n"
    wordlists = ""
    rules = ""
    tests = "" 
  for idx in 0 .. languages.high:
    var 
      language = languages[idx]
      langPrefix = language.toLower
    source &= "  \"" & language & "\",\n"
    wordlists &= "include ../wordlists/" & langPrefix & "_stopwords.nim\n"
    rules &= "include ../rules/" & langPrefix & "_porter.nim\n"
    tests &= "include ../tests/" & langPrefix & "_test.nim\n"
  
  wordlists &= "include ../wordlists/" & lang.toLower & "_stopwords.nim\n"
  rules &= "include ../rules/" & lang.toLower & "_porter.nim\n"
  tests &= "include ../tests/" & lang.toLower & "_test.nim\n"    
  source &= "  \"" & lang & "\"\n]\n"

  writeFile("includes/langlist.nim", source)
  writeFile("includes/tests.nim", tests)
  writeFile("includes/wordlists.nim", wordlists)
  writeFile("includes/rules.nim", rules)


when isMainModule:
  try:
    lang = paramStr(1)
  except:
    raise  newException(GeneratorError,"you need to pass language code!")
for language in languages:
  if  language == lang.toUpper:
    raise newException(GeneratorError, "the language with this code is alreday implemented")
let
    langPrefix = lang.toLower & "_"
    langSuffix = lang.toUpper

makeRulesTempl(langPrefix, langSuffix)
makeWordLists(langPrefix, langSuffix)
updateLangList(lang)

