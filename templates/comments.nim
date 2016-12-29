const 
  rules_comment =
    "## this stemmer does not pass tests when compared to the stemming from http://snowballstem.org/ this is a deliberate decision\n" &
    "## we chose to remove some of word-forming suffixes, that we consider \"grammatical\" rather \"semantical\"\n" &
    "## suggestions about how the stemmer can be improved are, of course, welcome\n" &
    "## Rules are simple: names of regexps, sigils and condiionals. \n" &
    "## '&' a sigil for splitting a word into RV groups (look up what it means in Porter's description), so \n"&
    "## whatever is matched by this sigil will be in the \"head\", the stemming is performed on \"tail\".\n " &
    "## for example \"RVRE\": re\"^.+?(а|е|и|о|у|ы|э|ю|я)\" means that splits the word into two pairs, such that \"tail\",\n" &
    "## starts after the first vowel which is not the first letter of the word." &
    "## '!'  sigil for condition \"empty replacement\", i.e. if a word stays the same after match with replacement.\n " &
    "## '?' sigil for match without replacement\n " &
    "## 'NAME' match and delete/replace the match.\n " &
    "## A => B, A > B if A then B, !A => B if not A then B (!A means that after we tried to replace regex A with something\n " &
    "## but the word stayed unaffected).\n" &
    "## ?A => B, check is A matches, then replace B.\n " &
    "## Things separated by a comma are applied consequtively, all substitutions: NN = re\"нн$\" means \"нн\" at the end is removed etc.\n " &
    "## If a key is present in both rules and replacements lists this means that expression from rules list is replaced by \n" &
    "## string from replacements, if there is no key in replacemens, then the regex is replaced by empty string." &
    "## There is very basic grammar checking, so balance your brackets etc!\n" &
    "## Grammar can be left empty, but this barely makes sense.\n" 

  stopwords_comment = 
    "## Edit the below to include the words, that WILL BE IGNORED during stemming and not included in the answer.\n" &
    "## Words must be double quoted and separated with commas (see example).\n" &
    "## List can be left empty."
  
  tests_comment = 
    "## Test text is a text you may want to tokenize and stem.\n" &
    "## Test set is a sequence of key-value tuples, from some 'benchmark' stemmer against which\n" &
    "## you'd like to test yours, both word and its stem must be doublequoted.\n" &
    "## sample dictionaries for a few european languages, can be found at http://snowballstem.org/\n" &
    "## both set and text may be empty"