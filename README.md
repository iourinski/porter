# porter
Porter stemmer for nim language (with a hopefully easy option to add new languages).

This is a simple implementation of the Porter stemmer algorithm for nim  language, using nim's regex implementation.

The algorithm and corresponding terminology can be found at http://snowballstem.org/. There are minor changes made for Russian 
language implementation (our algorithm is more "greedy" and chops off more suffixes than the original).

Usage:

```nim
import porter
...
let stemmer = newStemmer()
# to demonctrate available languages
for language in stemmer.getLanguages():
  echo language
# to stem some english text
let text: string = "Some string in English"
var stems: seq[string] = stemmer.stem(text, "EN")
```

where 'text' is a string and lang is a language code ("RU", "EN" etc). If an unknown language code is passed tokenized
original text is returned, otherwise a sequence of strings corresponding to stemmed words is returned. There is a possibility 
to add stoplists so words like auxillary verbs, pronouns, and articles are not included into the returned sequence of stems. 
This is a difference between this stemmer and the classical implementation which returns everything from a stoplist 
without doing anything to it.

Nim's standard implementation of regular expressions (package re) has certain specifics, which were taken into consideration:
  * there is no match captioning into a named variable, so posix expressions like `s/(something)(something else)/$1/` should be
  done in two steps: match `$1` and `$2` and then (if condition holds) replace `$2` etc.
  * ranges for non-ansi characters may not work as expected, so an easy workaround is to use `|`  grouping instead.
  
## Adding new languages
The package is meant to be more or less universal, so there is a small parser for a pseudo-grammar.
Adding a new language to the stemmer amounts to running a script `template_gen.nim` with new language code as the only parameter.
The script will generate several template files:
  * `rules/xx_rules.nim`
  * `wordlists/xx_stopwords.nim`
  * `wordlists/xx_test.nim`

where `xx` is a language code, for instance to add templates for Klingon language run `nim c -r template_gen.nim KL`.

After the templates are generated edit them according to the comments in code and compile `porter.nim`. Generated templates 
are not added to git, so if you want to add them to the repository you need to add them to git manually.

In order for the language stemmer to work properly all the variables added in templates must be declared (they can be left
with default values though).

Running `nim c -r porter.nim` runs tests on all available languages.