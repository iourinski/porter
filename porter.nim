import 
  macros,
  mutableseqs,
  porter_dispatch,
  re,
  sequtils,
  strutils,
  tables,
  unicode
type 
  PorterError* = object of Exception
  Stemmer* = ref object of RootObj
    dispatcher: Dispatcher 
    cache*: Table[string,Table[string, string]]

proc newStemmer*(): Stemmer =
  Stemmer(dispatcher: newDispatcher(), cache: initTable[string, Table[string,string]]())

proc substitute(word: var string, pat:  Regex, subst: string = ""): bool =
  ## does regex replacement and returns boolean value of whether the word stayed the same (false) or not (true)
  var tmp = word
  word = word.replace(pat, subst)
  return word != tmp

proc trimEnds* (text: string): string = 
  ## same about this one there are probably more things to trim
  text.replace(re"(^\s+|\s*\n$|\s$)","")

proc splitText* (text: string): seq[string] =
  ## this definitely should be expanded, so far it is a very basic text tokenization
  let 
    lcw1 = unicode.toLower(text).trimEnds
  var lcw = ""
  for x in utf8(lcw1):
    lcw = lcw & x
  var
    wordsF = lcw.split(re"\s+|,|\.|:|;|!|\?|\+|@") 
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

proc verifyGrammar(tokens: seq[string]): bool =
  ## very simple check for passed sequence of tokens
  var brack = 0
  for i in 0 .. tokens.high:
    var token = tokens[i]
    #echo i," ",token
    if i == 0:
      if token.match(re"^[A-Za-z\&\{\!\?\+\%]") == false:
        raise  newException(PorterError,"can't have " & token & " at the beginning")
    if token == ",":
      if tokens[i - 1].match(re"\}|\w+"):
        if (i < tokens.high and tokens[i+1].match(re"\%|\&|\?|\!|\w+")) == false:
          raise  newException(PorterError,"can't have " & tokens[i+1] & token & tokens[i+1])
    if token == "{":
      inc(brack)
    
    if token == "}":
      brack = brack - 1
      if i < tokens.high:       
        if tokens[i+1].match(re"\,|\}") == false:
          raise  newException(PorterError,"can't have " &  token & tokens[i+1])
  if brack != 0:
    raise  newException(PorterError,"check brackets balance")
  return true
      
proc applyRules(this: Stemmer, word: string, lang: string): string =
  ## this is a pretty simple linear parser-- no recursion, it only makes one pass through the tokens 
  ## and applies rules that match the word
  var 
    beginning = ""
    ending = word
    cond = true
    bracks = 0
    j = 0
  #echo word," beg: ", beginning," end: ",ending," no: ", j
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
  var 
    stemList = newSeq[string]()
  if verifyGrammar(this.dispatcher.getGrammarTokens(lang)):
    for word in text:
      if this.dispatcher.getStopwordsMap(lang).contains(word) == false:
        stemList.add(unicode.toLower(this.applyRules(word, lang)))
  else:
    return text
  return stemList  

proc stem* (this: Stemmer, text: string, lang: string = "RU"): seq[string] = 
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

proc runTests(this: Stemmer, lang: string) = 
  echo "Testing ", lang
  echo "Stemming a piece of text"
  this.testText(lang)
  echo ""
  echo "Testing a set of words:"
  this.testWordSet(lang)
  echo "Testing words is finished, see discrepancies above"

proc runTests(this: Stemmer) = 
  for lang in getLanguages():
    this.runTests(lang)
    echo "---------"

when isMainModule:
  var a = newStemmer()
  a.runTests()
  