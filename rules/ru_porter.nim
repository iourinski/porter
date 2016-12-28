include
  ../wordlists/ru_stopwords,
  ../wordlists/ru_test
## this stemmer does not pass tests when compared to the stemming from http://snowballstem.org/ this is a deliberate decision
## we chose to remove some of word-forming suffixes, that we consider "grammatical" rather "semantical"
## suggestions about how the stemmer can be improved are, of course, welcome
## Rules are simple: names of regexps, sigils and condiionals.
  ## '&' a sigil for splitting word into RV groups (look up what it means in Porter's description), so
  ## whatever is matched by this sigil will be in the "head", the stemming is performed on "tail".
  ## '!'  sigil for condition "empty replacement", i.e. if a word stays the same after match with replacement.
  ## '?' sigil for match without replacement
  ## 'NAME' match and delete/replace the match.
  ## A => B, A > B if A then B, !A => B if not A then B.
  ## ?A => B, check is A matches, then replace B.
  ## Things separated by a comma are applied consequtively, all substitutions: NN = re"нн$" means "нн" at the end is removed etc.
  ## There is no grammar checking, yet-- balance your brackets etc!
  
let
  rulesRU = {
    "CL": re"(\')",
    "YO": re"ё",
    "PERFECTIVEGERUND": re"((ив|ивши|ившись|ыв|ывши|ывшись)|((а|я)(в|вши|вшись)))$",
    "REFLEXIVE": re"(ся|сь)$",
    "ADJECTIVE": re"(ее|ие|ые|ое|ими|ыми|ей|ий|ый|ой|ем|им|ым|ом|его|ого|ему|ому|их|ых|ую|юю|ая|яя|ою|ею)$",
    "PARTICIPLE": re"((ивш|ывш|ующ)|((а|я)(ем|нн|вш|ющ|щ)))$",
    "VERB":  re("((ул(а|о)?|ила|ыла|ена|ейте|уйте|ите|или|ыли" &
      "|ей|уй|ил|ыл|им|ым|ен|ило|ыло|ено|ят|ует|уют|ит|ыт|ены|ить|ыть|ишь|ую|ю)|" &
      "((а|я)(ла|на|ете|йте|ли|й|л|ем|н|ло|но|ет|ют|ны|ть|ешь|нно)))$"),
    "NOUN": re("(а|ев|ов|ие|ье|е|иями|ями|ами|еи|ии|и|ией|ей|ой|ий|й|иям|ям|ием|ем|ам|ом|о|у|ах|иях" &
      "|ях|ы|ию|ью|ю|ия|ья|я)$"),
    "RVRE": re"^.+?(а|е|и|о|у|ы|э|ю|я)",
    "DERIVATIONAL": re"(^.+?(а|е|и|о|у|ы|э|ю|я)+.*?ость)$",
    "DER": re"ость?$",
    "SUPERLATIVE": re"(ейше|ейш)$",
    "I": re"и$",
    "P": re"ь$",
    "NN": re"нн$",
    "EMPTY": re"^(\\s|[^a-zа-я0-9])+$"
  }.toTable
    # sometimes we do not simply chop things off, we replace them, these are replacement strings
  replacementsRU = {
    "NN": "н",
    "YO": "е"
  }.toTable

  grammarRU: string = 
    "{CL, YO, &RVRE, !REFLECTIVEGERUND => {REFLEXIVE, ADJECTIVE => {PARTICIPLE}, !VERB => NOUN}, I, ?DERIVATIONAL => DER, !P => {SUPERLATIVE, NN }}"

  testTextRU: string = "трансцедентность Упячки бросилась в сильные фуфыри, петр крикнул  с крыши 'гласность'! " &
    " Покачивая головой еле успевшая катя уснула невзирая на неприспособленность. " &
    "Падающий на вальдшнепа пакет с операми вагнера заснял глянувший сверху делавший глупости стерх из cccp." &
    "Туповатый ёжик так ничего и не понял"

# these two functions are a bit of "legacy": direct application of Porter algorithm for Russian language
proc substitute(word: var string, pat:  Regex, subst: string = ""): bool =
  ## only kept here (and thus duplicated from porter) since it is used in procedure above
  var tmp = word
  word = word.replace(pat, subst)
  return word != tmp

proc applyRulesRU(word: string): string = 
  ## applying Porter's algo to Russian directly
  if word.match(re"^[-0-9]+$"):
    return word
  else:
    var 
      ending = word
    if ending.substitute(rulesRU["RVRE"]):
      echo ending,"\t",word
      let beginning = word.substr(0,word.len - ending.len - 1)
      if ending.substitute(rulesRU["PERFECTIVEGERUND"]) == false:
        ending  = ending.replace(rulesRU["REFLEXIVE"],"")
        if ending.substitute(rulesRU["ADJECTIVE"]):
          discard ending.substitute(rulesRU["PARTICIPLE"])
        else:
          if ending.substitute(rulesRU["VERB"]) == false:
            discard ending.substitute(rulesRU["NOUN"])
      ending = ending.replace(rulesRU["I"],"")
      if ending.match(rulesRU["DERIVATIONAL"]):
        discard  ending.substitute(rulesRU["DER"])
        
      if ending.substitute(rulesRU["P"]) == false:
        ending = ending.replace(rulesRU["SUPERLATIVE"],"")
        ending = ending.replace(rulesRU["NN"],"н")
      return beginning & ending
    echo "nothing found ", word
    return word



