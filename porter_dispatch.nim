import macros, os, re, tables
# This is a helper package that builds stemming rules, reads wordlists etc.
# Every instance of stemmer is capable of stemming in all languages defined in the package.

include includes/langlist
type 
  Dispatcher* = ref object of RootObj
    languages*:  seq[string]
    stopwords: Table[string, seq[string]]
    stopMaps: Table[string, Table[string,bool]]
    grammars: Table[string,  string]
    grammarTokens: Table[string, seq[string]]
    rules: Table[string,Table[string, Regex]]
    replacements: Table[string, Table[string, string]]
    testSets: Table[string, seq[tuple[key: string, value: string]]]
    testTexts: Table[string, string]

proc tokenize(grammar: string): seq[string] =
  result = newSeq[string]()
  var ph = ""
  for letter in grammar:
    if ($letter).match(re"^[\%\,\&\>\{\}\!\?\+]$"):
      if ph.match(re"^\w+$"):
        ph = ph.replace(re"\s+")
        result.add(ph)
        ph = ""    
      result.add($letter)
    if ($letter).match(re"^[a-zA-z0-9]$"):
      ph = ph & letter
  if ph.match(re"^\w+$"):
    if ph != "":
      result.add(ph)
  return result

proc getTableMatch[T](reps: Table[string, T], x: string, dummy: T): T =
  result = dummy
  if reps.contains(x):
    result =  reps[x]
  
proc makeMap(words: seq[string]): Table[string, bool] = 
  result  = initTable[string,bool]()
  for word in words:
    result.add(word,true)

macro generateTable(
  tableName: static[string], varName: static[string], init: static[string], tempn: static[string]
  ): stmt =
  var source = "var "& tempn & " = " & init & "\n"  
  for lang in languages:
    source &= "if declared " & varname & lang & ": " & tempn & ".add(\"" & lang & "\"," & varName & lang & ")\n"
  source &= "this." & tableName & "= " & tempn & "\n"
  parseStmt(source)

macro readIncls(dir: static[string]): stmt =
  result = newNimNode(nnkStmtList)
  for kind, path in walkDir(dir):
    result.add(newNimNode(nnkIncludeStmt).add(newIdentNode(path)))
    
proc newDispatcher*(): Dispatcher = 
  #readIncls("rules")
  #readIncls("wordlists")
  include includes/rules, includes/wordlists

  var this = Dispatcher(
    languages: languages
  )
  generateTable("stopwords", "regularStopwords",  "initTable[string, seq[string]]()","tmp1")
  generateTable("replacements", "replacements", "initTable[string, Table[string,string]]()", "tmp2")
  generateTable("rules","rules","initTable[string,Table[string, Regex]]()","tmp3")
  generateTable("grammars", "grammar", "initTable[string, string]()","tmp4")

  var 
    tmp5 = initTable[string, seq[string]]()
    tmp6 = initTable[string,Table[string,bool]]()

  for lang in languages:
    if this.grammars.contains(lang):
      tmp5.add(lang, tokenize(this.grammars[lang]))
    if this.stopwords.contains(lang):
      tmp6.add(lang, makeMap(this.stopwords[lang]))

  this.grammarTokens = tmp5
  this.stopMaps = tmp6
  return this

proc getReReplacement*(this: Dispatcher, x: string, lang: string): string =
  result = ""
  if this.replacements.contains(lang):
    result = getTableMatch(this.replacements[lang], x, "")  

proc getRe*(this: Dispatcher, x: string, lang: string): Regex =
  ## if we can not find something, we just return regex that is VERY likely to do nothing
  let dummy = re".{100,}"
  result = dummy
  if this.rules.contains(lang):
    result =  getTableMatch(this.rules[lang], x, dummy)
  
proc getStopwordsMap*(this: Dispatcher, lang: string = "RU"): Table[string, bool] = 
  ## returns a table that allows to check whether a word is in the list of stopwords for passed language.
  result = initTable[string, bool]()
  if this.stopMaps.contains(lang):
    result = this.stopMaps[lang]

proc getGrammarTokens*(this: Dispatcher, lang: string = "RU"): seq[string] =  
  result = newSeq[string]()
  if this.grammarTokens.contains(lang):
    result =  this.grammarTokens[lang]

proc getLanguages*(): seq[string] = languages

# the two below are lazy variables, we only need them if we run tests, otherwise we just keep them undefined
proc getTestSet*(this: Dispatcher, lang: string): seq[tuple[key: string, value: string]] = 
  # this is just to return a list of examples from Porter's webpage-- only useful to see how well your grammar 
  # reproduces the original algorithm
  #readIncls("tests")
  include includes/tests
  result =  newSeq[tuple[key: string, value: string]]()
  if declared (this.testSets) == false:
    generateTable("testSets", "testSet", "initTable[string, seq[tuple[key: string, value: string]]]()","tmp7")
  if this.testSets.contains(lang):
    result = this.testSets[lang]

proc getTestText*(this: Dispatcher, lang: string): string = 
  result = ""
  #readIncls("tests")
  include includes/tests
  if declared (this.testTexts) == false:
    generateTable("testTexts", "testText", "initTable[string, string]()","tmp8")
  if this.testTexts.contains(lang):
    result = this.testTexts[lang]

    