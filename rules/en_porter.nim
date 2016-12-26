import 
  re, 
  tables, 
  ../wordlists/en_stopwords,
  ../wordlists/en_test

## this stemmer is mostly done to see whether the proposed "grammar" can be used to implement stemmers different from Russian,
## as a result this grammar almost passes the test from http://snowballstem.org/ although it certainly can be imporved and
## made more parsimonious 
let 
  en_rules* = {
    "Y": re"^(y)",
    "YY" : re"y",
    "VY" : re"(a|e|i|o|u)y",
    "RVRE": re"^.+?[aeiouy]",
    "VOWEL" : re"[aeiouy]",
    "DOUBLE" : re"(bb|dd|ff|gg|mm|nn|pp|rr|tt)$",
    "INIT_APOSTROPHE" : re"^\'",
    "POSS" : re"(\'s|\'|\'s\')$",
    "SSES" : re"sses$",
    "IED1"  : re"^[a-zAz]{2,}(ied|ies)$",
    "IEDR1" : re"(ied|ies)$",
    "IEDR2" : re"(ied|ies)$",
    "IED2" : re"^[a-zA-Z]{1}(ied|ies)$",
    "SEND" : re"[aeiouy][^aeiouy]*?s$",
    "S" : re"s$",
    "EED" : re"(eed|eedly)$",
    "EDCHECK" : re"(ed|edly|ing|ingly)$",
    "AT" : re"(at|bl|iz)$",
    "RM1" : re"(\w)$",
    "SHRTW" : re"$[^aeiouy]+[aeiouy][^aeiouywx]$",
    "SHRTS" : re"$[^aeiouy]+[aeiouy][^aeiouywx]$",
    "TIONAL" : re"tional$",
    "ENCI" : re"enci$",
    "ANCI" : re"anci$",
    "ABLI" : re"abli$",
    "ENTLI" : re"entli$",
    "IZ" : re"(izer|ization)$",
    "ATION" : re"(ational|ation|ator)$",
    "ALISM" : re"(alism|all)$",
    "FULNESS" : re"(fulness|fulli)$",
    "OUSLI" : re"(ousli|ousness)$",
    "IVITY" : re"(iveness|ivity)$",
    "BLI" : re"(bility|bli)$",
    "OGI" : re"logi$",
    "LESSLI" : re"less$",
    "LICH" : re"[cdeghkmnrt]li$",
    "LI" : re"li$",
    "ALIZE" : re"alize$",
    "IC" : re"(icate|iciti|ical)$",
    "FUL" : re"(ful|ness)$",
    "ATIVECH" : re".+?[aeiouy].*?ative",
    "ATIVE" : re"ative$",
    "R2SUFF" : re(".+?[aeiouy].*?(al|ance|ence|er|ic|able|ible|ant|ement|ment|ent|" &
      "ism|ate|iti|ous|ive|ize)$"),
    "R2END" :  re("(al|ance|ence|er|ic|able|ible|ant|ement|ment|ent|" &
      "ism|ate|iti|ous|ive|ize)$"),
    "IONCH" : re"[st]ion$",
    "ION" : re"ion$",
    "L1CH" : re".+?[aeiouy]ll$",
    "L1" : re"l$",
    "E1CH" :  re".[aeiouy].*?e$",
    "E1" : re"e$",
    "BB": re"bb$",
    "DD": re"dd$",
    "FF": re"ff$",
    "GG": re"gg$",
    "MM": re"mm$",
    "NN": re"nn$",
    "PP": re"pp$",
    "RR": re"rr$",
    "TT": re"tt$",
    #"EEND": re".+?[aeiouy]e$",
    "EDEL": re"e$",
    "YEND": re".+[^aeiou](y|Y)",
    "YI": re"(y|Y)$"
   }.toTable

  en_replacements* = {
    "YI": "i",
    "SSES" : "ss",
    "IEDR1" : "i",
    "IEDR2" : "ie",
    "E" : "e",
    "EED" : "ee",
    "AT" : "e",
    "TIONAL" : "tion",
    "ENCI" : "ence",
    "ANCI" : "ance",
    "ABLI" : "able",
    "ENTLI" : "entli",
    "IZ" : "ize",
    "ATION" : "ate",
    "ALISM" : "al",
    "FULNESS" : "ful",
    "OUSLI" : "ous",
    "IVITY" : "ive",
    "BLI" : "ble",
    "OGI" : "log",
    "LESSLI" : "less",
    "ALIZE" : "al",
    "IC" : "ic",
    "Y" : "Y",
    "YY" : "Y",
    "BB": "b",
    "DD": "d",
    "FF": "f",
    "GG": "g",
    "MM": "m",
    "NN": "n",
    "PP": "p",
    "RR": "r",
    "TT": "t"
  }.toTable

proc getGrammarEN*(): string =
  "INIT_APOSTROPHE,Y,?VY => YY,  POSS,  SSES, EED, ?IED1 => IEDR1, ?IED2 => IEDR2, " &
    "?SEND => S, &RVRE, EED, EDCHECK => {?AT => +E,?DOUBLE => { !SHRTW => {BB,DD,FF,GG,MM,NN,PP,RR,TT}}, " &
    " %SHRTW => +E}, ?YEND => YI, TIONAL,ENCI,ANCI,ABLI,ENTLI,IZ,ATION,ALISM,FULNESS,OUSLI, " &
    " IVITY, BLI, OGI, LESSLI, ?L1CH => L1, ALIZE,IC, FUL,LESSLI,?LICH=>LI, "&
    " FUL,?ATIVECH=>ATIVE,?R2SUFF=>R2END, ?IONCH => ION, ?L1CH => L1 , ?E1CH => EDEL"

proc getTestSetEN*(): seq[tuple[key: string, value: string]] = test_set

proc getTestTextEN*(): string = "caps cries  luxurious apples lied posesses bums luxuriating hopped" &
    " delete if preceding longest finangles"

proc stopWordsEN*(): Table[string, bool] = getStopWords()
