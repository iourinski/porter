import 
  mutableseqs,
  porter_dispatch,
  re,
  sequtils,
  strutils,
  tables,
  unicode
type 
 
  Stemmer* = ref object of RootObj
    dispatcher: Dispatcher 
    cache*: Table[string,Table[string, string]]

proc newStemmer*(): Stemmer =
  ## Constructor, does not require any parameters.
  return Stemmer(dispatcher: newDispatcher(), cache: initTable[string, Table[string, string]]())
  
proc newStemmer*(lang: string): Stemmer = 
  ## Only constructs stemmer working with specified language 
  return Stemmer(dispatcher: newDispatcher(lang), cache: initTable[string, Table[string, string]]())

proc substitute(word: var string, pat:  Regex, subst: string = ""): bool =
  ## does regex replacement and returns boolean value of whether the word stayed the same (false) or not (true)
  var tmp = word
  word = word.replace(pat, subst)
  return word != tmp

proc trimEnds* (text: string): string = 
  ## There are probably more things to trim, roughy similar to perl's chomp: removes trailing newlines and spaces
  text.replace(re"(\)|\(^\s+|\s*\n$|\s$)","")
  #text.replace(re"[^-а-яa-z0-9]","")
proc splitText* (text: string): seq[string] =
  ## This definitely should be expanded, so far it is a very basic text tokenization
  var 
    lcw1 = unicode.toLower(text).trimEnds

  var lcw = ""
  for x in utf8(lcw1):
    if x != "\"" and x != "\'":
      lcw = lcw & x
  #lcw = lcw.replace(re"[^а-яa-z0-9]","")
  
  var
    wordsF = lcw.split(re"\-|\s+|,|\.|:|;|!|\?|\+|@") 
    words = wordsF
    .filter(proc(x: string): bool = x.match(re"^[-0-9]+$") == false)
  var 
    unSplitWords = words
      .transform(
        proc(word: string): seq[string] =
          if word.findAll(re"-").len > 2:
            word.split(re"-")
          else: 
            @[word]
      )
  return unSplitWords.flatMap(proc(x: seq[string]): seq[string] = x)


      
proc applyRules(this: Stemmer, word: string, lang: string): string =
  ## This is a pretty simple linear parser-- no recursion, it only makes one pass through the tokens 
  ## and applies rules that match the word
  var 
    beginning = ""
    ending = word
    cond = true
    bracks = 0
    j = 0
  #echo word, " beg: ", beginning, " end: ", ending, " no: ", j
  var tokens = this.dispatcher.getGrammarTokens(lang)
  while  j <= tokens.high:
    #echo j, " ",cond," ",tokens[j]," ",beginning, " ", ending
    if tokens[j].match(re"^\w+"):
      var 
        regex = this.dispatcher.getRe(tokens[j], lang)
        subst = this.dispatcher.getReReplacement(tokens[j], lang)
      if j == 0:
        discard ending.substitute(regex, subst)
      else:
        var prev = tokens[j-1]
        case prev:
          of "&":
            # this is getting RV groups, after this is done conditions are applied to RV1 unless stated otherwise explicitly
            var tmp = ending
            if ending.substitute(regex, subst):
              beginning = tmp.substr(0,tmp.len - ending.len - 1)
              #echo ending,"\t",beginning, "\t",tokens[j]
              
          of "!":
            # negation
            cond  = ending.substitute(regex, subst) == false
          of ">":
            # basically nothing-- just telling us to go to next operator unless the condition is false
            if cond:
              #echo tokens[j], "\t",ending, "\t", cond
              discard ending.substitute(regex, subst)
            else:
              cond = true
          of "+":
            # add something at the end of the word 
            if cond:
              ending  = ending & subst
          of ",":
            # this is parsed only for sake of readability and ease of verification
            discard ending.substitute(regex, subst)
          of "?":
            # this is a conditional if it is true the thing it points to is executed
            cond = (ending.find(regex) >= 0)
          of "%":
            # this is checking condition on whole word: %A => B if A true on whole word then B
            #echo beginning & ending
            cond = ((beginning & ending).find(regex) > 0)
          of "^":
            # same as above but for negative i.e. equvalent to !%A => B if A does not work on full word, do B
            cond = ((beginning & ending).find(regex) == -1)
          else:
            discard ending.substitute(regex, subst)
    elif tokens[j] == "{":
      if cond == false:
        inc(bracks)
        while bracks > 0:
          inc(j)
          if tokens[j] == "{":
            inc(bracks)
          elif tokens[j] == "}":
            bracks = bracks - 1
    inc(j)
  return beginning & ending

proc stem* (this: Stemmer, text: seq[string], lang: string = "RU"): seq[string] = 
  ## Replaces every element of sequence with corresponding stem, the words from 
  ## stoplists are excluded.
  var 
    stemList = newSeq[string]()
  for word in text:
    let lcw = unicode.toLower(word)
    if this.dispatcher.getStopwordsMap(lang).contains(lcw) == false:
      if this.cache.contains(lang):
        if this.cache[lang].contains(lcw):
          stemList.add(this.cache[lang][lcw])
        else:
          var stem = this.applyRules(lcw, lang)
          stemList.add(stem)
          this.cache[lang].add(lcw, stem)
      else:
        let stem = this.applyRules(lcw,lang)
        var dummyTable = initTable[string, string]()
        dummyTable.add(lcw, stem)
        this.cache.add(lang, dummyTable)
        stemList.add(stem)
  return stemList  

proc stem* (this: Stemmer, text: string, lang: string = "RU"): seq[string] = 
  ## Same as above, but the text is tokenized first
  var
    splitWords = splitText(text)  
    stemList = this.stem(splitWords, lang)
  return stemList.filter(proc(x: string): bool = x.len > 1)

## some very simple testing procedures
proc testWordSet(this: Stemmer, lang: string) = 
 for pair in this.dispatcher.getTestSet(lang):
    var stemmmedWord = this.stem(pair.key, lang)
    if stemmmedWord.len > 0:
      try:
        assert pair.value == stemmmedWord[0]
      except:
        echo pair.key,": ",pair.value, " vs ", stemmmedWord[0]

proc testText(this: Stemmer, lang: string) = 
  var longString = this.dispatcher.getTestText(lang)
  echo "original:\n",longString,"\nstemmed:\n",this.stem(longString,lang)

proc getLanguages* (this: Stemmer): seq[string] = 
  ## Returns the list of languages available for stemming
  return this.dispatcher.languages
  
proc runTests(this: Stemmer, lang: string) = 
  echo "Testing ", lang
  echo "Stemming a piece of text"
  this.testText(lang)
  echo ""
  echo "Testing a set of words:"
  this.testWordSet(lang)
  echo "Testing words is finished, see discrepancies above (our stems are on the right)"

proc runTests(this: Stemmer) = 
  for lang in getLanguages():
    this.runTests(lang)
    echo "---------"

when isMainModule:
  var a = newStemmer()
  a.runTests()
  echo a.getLanguages()
  var b = newStemmer("EN")
  echo b.dispatcher.getGrammarTokens("EN")