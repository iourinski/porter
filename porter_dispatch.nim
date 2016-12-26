import 
  re, 
  rules/ru_porter,
  rules/en_porter, 
  tables, 
  unicode
  
# this is a helper package that only returns things related to each language, it needs to be changed whenever a new language is added
# perhaps there is a nicer way to rewrite the whole thing using some metaprogramming rather than sequnces of cases

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

proc getReReplacement*(x: string, lang: string): string =
  ## if new patterns in a grammar are introduced, they should be added here
  case lang:
    of "RU":
      if ru_replacements.contains(x):
        return ru_replacements[x]
      else:
        return ""
    of "EN":
      if en_replacements.contains(x):
        return en_replacements[x]
      else:
        return ""
    else:
      return ""
  
proc getRe*(x: string, lang: string): Regex =
  ## if we can not find something, we just return regex that is VERY likely to do nothing
  case lang:
    of "RU":
      if ru_rules.contains(x):
        return ru_rules[x]
      else:
        return re".{100,}"
    of "EN":
      if en_rules.contains(x):
        return en_rules[x]
      else:
        return re".{100,}"
    else:
      return re".{100,}"
  
proc getWordsMap*(lang: string = "RU"): Table[string, bool] = 
  # this is a procedure that has to be changed when new languages are added (you also need to import your stemmer above)
  case lang:
    of "RU": 
      return stopWordsRU()
    of "EN":
      return stopWordsEN()
    else:
      return initTable[string, bool]()

proc getGrammarTokens*(lang: string = "RU"): seq[string] =  
  # this is a procedure that has to be changed when new languages are added (you also need to import your stemmer above)
  case lang:
    of "RU":
      return tokenize(getGrammarRU())
    of "EN": 
      return tokenize(getGrammarEN())
    else:
      return newSeq[string]()
  
proc getTestSet*(lang: string): seq[tuple[key: string, value: string]] = 
  # this is just to return a list of examples from Porter's webpage-- only useful to see how well your grammar 
  # reproduces the original algorithm

  case lang:
    of "EN":
      return getTestSetEN()
    of "RU":
      return getTestSetRU()
    else: 
      return newSeq[tuple[key: string, value: string]]()

proc getTestText*(lang: string): string = 
  case lang:
    of "RU":
      return getTestTextRU()
    of "EN":
      return getTestTextEN()
    else:
      return ""

proc getLanguages*(): seq[string] = @["RU","EN"]



