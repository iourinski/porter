# porter
Porter stemmer for nim language (with a hopefully easy option to add new languages).

This is a simple implementation of Porter stemmer algorithm for nim  language, using nim's regex implementation.

The algorithm and corresponding terminology can be found at http://snowballstem.org/. There are minor changes made for Russian 
language implementation (our algorithm is more "greedy" and chops off more suffixes than the original).

The package is meant to be more or less universal, so there is a small parser for a pseudo-grammar (see docs for description),
adding a new language to the stemmer amout to adding corresponding wordlists (if any), list of regexes that are used for
stemming and modifying file nim_dispatch.nim (where new dependencies and accessors need to be added). This is a still a work in
progress so the architecture is likely to change, however the top-level interface is likely to stay the same:

```nim
import porter
...
var stems = stem(text, lang)
```

where 'text' is a string and lang is a language code ("RU", "EN" etc). If an unknown language code is passed empty sequence 
of strings is returned, otherwise a sequence of strings corresponding to stemmed words is returned. Tere is a possibility 
to add stoplists so 
the words like auxillary verbs, pronouns, and articles are not included into the returned sequence of stems. This is a difference
between this stemmer and the classical implementation which returns everything from a stoplist without doing anything to it.

Nim's standard implementation of regular expressions (package re) has certain specifics, which were taken into consideration:
  * there is no match captioning into a named variable, so posix expressions like `s/(something)(something else)/$1/` should be
  done in two steps match: `$1` and `$2` and then (if condition holds) replace `$2` etc.
  * ranges for non-ansi characters may not work as expected, so an easy workaround is to use `|`  grouping instead.
  
## Adding new languages
So far we suggest naming files `xx_porter.nim, wordlists/xx_stopwords.nim` etc., where xx is a lowercase language code, in the 
code language codes are capitalized (as well as names of regexes). Every file `xx_porter.nim` should have a procedure 
`proc getGrammarXX` that returns a string  describing stemming rules according to rules explained docs for `porter_ru`.

Accessors are added in file `porter_dispatch.nim` by adding a new import and modifying whatever accessor procedures were affected.

