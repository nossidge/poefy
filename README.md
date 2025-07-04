# Poefy

by [Paul Thompson](https://tilde.town/~nossidge) - nossidge@gmail.com

Create rhyming poems from an input text file, by generating and querying a SQLite or PostgreSQL database that describes each line.

Poems are created using a template to select lines from the database, according to closing rhyme, syllable count, and regex matching.

I wrote this because I was banging my head against a wall trying to use [Tracery](https://github.com/galaxykate/tracery) to generate villanelles. Then I remembered that I know how to program computers. Lucky!


## Table of Contents
* [Installation](#installation)
  * [Install the base gem](#install-the-base-gem)
  * [Install a database gem](#install-a-database-gem)
    * [PostgreSQL](#postgresql)
    * [SQLite](#sqlite)
  * [Set up some example corpora](#set-up-some-example-corpora)
* [Usage](#usage)
  * [From the Command Line](#from-the-command-line)
  * [As a Ruby Gem](#as-a-ruby-gem)
* [Some tips](#some-tips)
* [Sample output](#sample-output)


## Installation

### Install the base gem

    $ gem install poefy


### Install a database gem

You have two options when it comes to databases.


#### PostgreSQL

Install [PostgreSQL 9.0+](https://www.postgresql.org/download/)

Install the gem, and let poefy know that you will be using 'pg'.

    $ gem install poefy-pg
    $ poefy -D pg

In your Postgres instance, create a new user:

    username: 'poefy'
    password: 'poefy'

Then create a new database, with the above user as the owner:

    database: 'poefy'

Everything is called 'poefy'. Nice and easy.


#### SQLite

Install [SQLite 3.0+](https://sqlite.org/download.html)

Install the gem, and let poefy know that you will be using 'sqlite3'.

    $ gem install poefy-sqlite3
    $ poefy -D sqlite3

There is no further setup needed.


### Set up some example corpora

The repo comes with some initial text files included. To generate corpora for these files, execute the special `poefy_make` binary:

    $ poefy_make


## Usage

### From the Command Line

To make a poefy corpus from a text file, run either of the below:

    $ poefy shakespeare -m < shakespeare_sonnets.txt
    $ poefy shakespeare --make < shakespeare_sonnets.txt

This will create a corpus describing each line of Shakespeare's sonnets. The type of corpus depends on whether you are using PosgreSQL (saved as a table in the 'poefy' database) or SQLite (saved to a database file as ROOT/data/CORPUS.db).

Now, whenever you want to make poems using Shakespeare's lines, you can just use `poefy shakespeare` and it will read from the already created corpora:

    $ poefy shakespeare sonnet
    $ poefy shakespeare limerick
    $ poefy shakespeare villanelle

If you later want to remake the corpus, for example to add new lines, you can use the `-m` option again and the existing corpus will be overwritten.

    $ cat shakespeare_sonnets.txt shakespeare_plays.txt | poefy shakespeare -m

You can use the `-L` or `--list` option to view available corpora.

__For SQLite users only:__
This corpus database file is stored in the same directory as the gem, so it can be accessed by all users on your system. To store a corpus in a different directory, you can use the `-l` or `--local` option:

    $ poefy -l path/to/eliot.db < eliot.txt

You then need to use the `-l` option when generating poems:

    $ poefy -l path/to/eliot.db rondeau
    $ poefy path/to/eliot.db ballade -l
    $ cd path/to
    $ poefy -l eliot.db ballata

Note that using this option you must use the whole file name, i.e. "coleridge.db" and not just "coleridge".


#### Option `-f` or `--form`

The `-f` option is used to specify a chosen poetic form, which sets the rhyme, syllable, and/or indent options to a predefined setting.

The option switch is not mandatory; if not specified the second argument will be used. The below examples are identical:

    $ poefy shakespeare sonnet
    $ poefy shakespeare -f sonnet

For forms where the syllables are constant through the poem, the syllable has not been specified. This is so you can use the `-s` option to set this. Syllables are only specified in forms where the syllable is a major factor of the form. At the moment these are: limerick, haiku, common, ballad.

To view and amend these definitions, the code is in `lib/poefy/poetic_forms.rb`. Some examples:

```ruby
{
  sonnet: {
    rhyme:    'ababcdcdefefgg',
    indent:   '',
    syllable: ''
  },
  villanelle: {
    rhyme:    'A1bA2 abA1 abA2 abA1 abA2 abA1A2',
    indent:   '010 001 001 001 001 0011',
    syllable: ''
  },
  haiku: {
    rhyme:    'abc',
    indent:   '',
    syllable: '[5,7,5]'
  },
  limerick: {
    rhyme:    'aabba',
    indent:   '',
    syllable: '{1:[8],2:[8],3:[4,5],4:[4,5],5:[8]}'
  },
  double_dactyl: {
    rhyme:    'abcd efgd',
    indent:   '',
    syllable: '{0:6, 4m0:4}',
    regex:    '{7: ^\S+$}'
  }
}
```

You can use the `-h` or `--help` option to view available forms.


#### Option `-r` or `--rhyme`

Specifies a rhyme structure that the poem must follow. This is the most important argument; the whole poem is based on this.

Each token in the rhyme string represents a line in the poem. Letters indicate rhymes, so all 'a' or 'A' lines have the same rhyme. Example, sonnet:

    $ poefy whitman -r'ababcdcdefefgg'

Uppercase letter lines will be duplicated exactly. This is used to create refrain lines. Example, rondeau:

    $ poefy whitman -r'aabba aabC aabbaC'

Numbers after a capital letter indicate which specific line to repeat. This is so you can have repeated lines that use the same rhyme scheme. Example, villanelle:

    $ poefy whitman -r'A1bA2 abA1 abA2 abA1 abA2 abA1A2'


#### Option `-i` or `--indent`

Indent each line by a certain number of spaces. Examples:

    $ poefy shakespeare sonnet -i'01010101010101'
    $ poefy shakespeare -r'abcba abcdcba' -i'01210 0123210'
    $ poefy shakespeare ballade -i'00000001 00000001 00000001 0001'

Use zero `-i0` to specify no indentation.


#### Option `-s` or `--syllable`

Specify syllable count allowed for each line. There's a few valid forms it can take.

If the string is just one number, all lines will be that number of syllables long.

    $ poefy whitman sonnet -s'10'

If the string is comma delimited, all lines will be any of those numbers of syllables long.

    $ poefy whitman sonnet -s'9,10,11'

The above can also be written to use a range format:

    $ poefy whitman sonnet -s'9-11'

If the string is an array, each element corresponds to a line in the output. This will skip blank lines.

All of the below will generate limericks, with the latter ones more permissive than the first.

    $ poefy whitman -r'aabba' -s'[8,8,5,5,8]'
    $ poefy whitman -r'aabba' -s'[[8,9],[8,9],[4,5,6],[4,5,6],[8,9]]'
    $ poefy whitman -r'aabba' -s'[8-9,8-9,4-6,4-6,8-9]'

If the string is a hash, the key will be used to match the line number. The underlying code that reads this uses YAML, but because the values will only be numbers we can be kinder with regards to key identifiers. So you can use `=>` or `:`, and they will be replaced with YAML's default `: ` (colon + space).

    $ poefy whitman -r'aabba' -s'{1:8,2:8,3:5,4:5,5:8}'
    $ poefy whitman -r'aabba' -s'{1:[8,9],2:[8,9],3:[4,5,6],4:[4,5,6],5:[8,9]}'
    $ poefy whitman -r'aabba' -s'{1:[8,9],2:[8,9],3:4-6,4:4-6,5:[8,9]}'
    $ poefy whitman -r'aabba' -s'{0: [8,9],3: [4,5,6],4: 4-6}'
    $ poefy whitman -r'aabba' -s'{0=>[8,9],3=>[4,5,6],4=>4-6}'

The below example will have 8 syllables for the 1st and 5th lines, but any number for the rest.

    $ poefy whitman -r'aabba' -s'{1:8,5:8}'

Any lines not explicitly specified will use the value of the '0' key (zero). If there is no '0' key, the lines will follow no constraints.

The below example will have 8 syllables for the 1st and 5th lines, and 6 syllables for the rest.

    $ poefy whitman -r'aabba' -s'{0:6,1:8,5:8}'

The key of the hash can take the form of negative numbers. In that case, they will refer to lines from the end of the poem. Any duplicated keys will be overwritten by the latest one.

    $ poefy whitman -r'aabba' -s'{1:8,2:8,3:5,-2:5,-1:8}'

You can use the special keys 'o' and 'e' to specify odd or even lines. This will ignore empty lines between stanzas (spaces in the rhyme string). The below example will have 8 syllables for the 1st and 3rd lines, 6 syllables for the 2nd and 4th, 6 syllables for the 5th, and 4 syllables for the 6th.

    $ poefy whitman -r'ad bd cd' -s'{o:8,e:6,-2:6,-1:4}'

A more advanced version of the above, you can use the letter 'm' to perform a [modulo operation][0] on the line number. This key takes the format `[divider]m[remainder]`. There's a few examples here, but it's not as complicated as it might at first seem.

[0]: https://en.wikipedia.org/wiki/Modulo_operation

If you have stanzas of 6 lines, to match the last line in each you can use the key `6m0`. This is because the line has a number of 6, 12, or 18, and those divide by 6 cleanly, leaving 0 as the remainder:

    $ poefy whitman -r'abcdef abcdef abcdef' -s'{6m0:4}'

To match the first two lines, use `6m1` and `6m2`:

    $ poefy whitman -r'abcdef abcdef abcdef' -s'{6m1:4, 6m2:8}'

This will give you stanzas of three lines, and longer syllable counts for the first line of each stanza:

    $ poefy whitman -r'abb abb cdd cdd' -s'{0:4, 3m1:8}'

This will create a [double dactyl](https://en.wikipedia.org/wiki/Double_dactyl):

    $ poefy whitman -r'abcd efgd' -s'{0:6, 4m0:4}' -x'{7: ^\S+$}'

Use zero `-s0` to specify no syllable matching.


#### Option `-x` or `--regex`

Specify a regular expression for lines to follow.

If the string is just one regex, all lines will be forced to match that regex.

    $ poefy whitman sonnet -x'^[A-Z]'
    $ poefy whitman sonnet -x'^[^e]*$'

If the string is a hash, you can use the same key types as with `syllable` string. Again, it will be parsed as YAML, but here we are more concerned about string substitution messing up the regex. So you have to use `: ` as the key identifier. Also, you must put the regex inside `'single'` or `"double"` quotes.

Example, to ensure the first line always starts with capitalisation:

    $ poefy whitman sonnet -x'{1: "^[A-Z]"}'

Unlike with the syllable option, you cannot use an array. You must use a single value or a hash. This is because the use of `[]` symbols in regular expressions confuses the parser, and I didn't want to forbid these common regex symbols. You can use hashes, but because of this you cannot use `{}` repetition matching in Poefy command line expressions. It's a pretty niche regex use though. You'll be fine without it.

Use a space `-x' '` to specify no regex matching.


#### Option `-a` or `--acrostic`

Since there's a regular expression matcher it's pretty trivial to use it to generate acrostics. This option just creates regexes for the first character of each line, either upper or lowercase. Works best if you remove any indentation of lines.

They need to include spaces where blank lines would normally go, for example a Petrarchan with rhyme 'abba abba cde cde':

    $ poefy therese -r'abba abba cde cde' -i0 -a'stop that fat cat' -s10
    $ poefy whitman -r'abba abba cde cde' -i0 -a'such good bum fun'

You must also beware of repeated lines (uppercase letters in the rhyme string). For example, a rondeau uses the rhyme form 'aabba aabR aabbaR', so the acrostic needs to have the same letter for both 'R' repeated lines.

    $ poefy therese rondeau -a'grown ever softer'


#### Option `-A` or `--acrostic_x`

This does the same as `-a`, but with special workarounds for 'x'. In the case that a line needs to match /^x/, it will instead match /^ex/ and replace with 'eX'. It will also use indentation to line-up the letters vertically:

    $ poefy whitman -s8 -r abcbdd -A taxman

````
  To reason's early paradise,
  And that death and dismay are great.
 eXult O shores, and ring O bells!
  May-be kill'd, unknown to her mate,
  Around the idea of thee.
  now, for all you cannot see me?
````


#### Option `-p` or `--proper`

This is used to ensure that the first word in the first line is not 'and but or nor yet', and the final line ends with closing punctuation (full stop, exclamation, or question mark). The default for this is `true`, but you can set it to `false` if necessary, for example if your input lines do not use punctuation.

To clarify: using the `-p` or `--proper` option will DISABLE this functionality.


#### Special case: `rhyme` command

If the second argument is `rhyme`, then output all lines that rhyme with the word.

This gives a basic look into the contents of the corpus table.

````
$ poefy dickinson rhyme confuse
  {"rhyme"=>"7d", "final_word"=>"choose", "syllables"=>6, "line"=>"As if for you to choose,"}
  {"rhyme"=>"7d", "final_word"=>"dews", "syllables"=>6, "line"=>"The debauchee of dews!"}
  {"rhyme"=>"7d", "final_word"=>"dews", "syllables"=>9, "line"=>"Like flowers that heard the tale of dews,"}
  {"rhyme"=>"7d", "final_word"=>"hues", "syllables"=>6, "line"=>"Of independent hues,"}
  {"rhyme"=>"7d", "final_word"=>"news", "syllables"=>8, "line"=>"The intuition of the news"}
  {"rhyme"=>"7d", "final_word"=>"screws", "syllables"=>6, "line"=>"It is the gift of screws."}
  {"rhyme"=>"7d", "final_word"=>"shoes", "syllables"=>8, "line"=>"Upon my ankle, -- then my shoes"}
````

You can select just the lines by using the hash key `line`:

````
$ poefy dickinson rhyme confuse line
  As if for you to choose,
  The debauchee of dews!
  Like flowers that heard the tale of dews,
  Of independent hues,
  The intuition of the news
  It is the gift of screws.
  Upon my ankle, -- then my shoes
````

You can do the same thing for the other keys: `rhyme`, `final_word`, and `syllables`.


#### Special case: poetic form from text file

If you pipe in text and don't use the `-m` option to create a corpus, then the output will be a poem with the same structure as the file. This can also be accomplished if the second argument is a reference to a text file. So, assuming you have a [`lyrics`][1] script that will return song lines for you:

    $ lyrics 'carly rae jepsen' 'call me maybe' | tee jep.txt | poefy whitman
    $ poefy whitman < jep.txt
    $ poefy whitman jep.txt

The program will scan by line, looking for rhyme, syllables and repeated lines. It will then build up a constraint hash and use that as the poetic form.

Any line that is bracketed in `[square]` or `{curly}` braces will be duplicated exactly in the output. This is for lines such as "chorus" or "1st verse" descriptions. This seems to work nicely with lyrics from genius.com.

Also, any indentation will be preserved, assuming 2 spaces per "indent".

Here's an example of a song that can be sung to the same tune as "[I Want to Hold Your Hand][2]", but using lyrics from all Beatles songs:

````
$ poefy beatles data/beatles/i_want_to_hold_your_hand.txt
[Chorus 1]
Now the sun turns out his light
And, though we may be blind
It's been a hard day's night
What goes on in your mind?
What goes on in your mind?
What goes on in your mind?

[Verse 1]
Feeling two-foot small
As I write this letter
The walrus was Paul
I left you far behind
You're not the hurting kind
What goes on in your mind?

[Bridge]
I'll remember all the little things we've done
Sleep pretty darling, do not cry
In the sun
In the sun
In the sun

[Chorus 2]
You know I feel alright
And, though we may be blind
It's been a hard day's night
What goes on in your mind?
What goes on in your mind?
What goes on in your mind?

[Bridge]
I'll remember all the little things we've done
Sleep pretty darling, do not cry
In the sun
In the sun
In the sun

[Chorus 3]
You know I feel alright
And, though we may be blind
I want a love that's right
What goes on in your mind?
What goes on in your mind?
What goes on in your mind?
What goes on in your mind?
````

You can tell that it's only based on whole line changes. Very similar lines are replaced with rhyming, but dissimilar ones. Something for me to think about.

````
[Original]                       [Generated]
You'll let me hold your hand     I left you far behind
I'll let me hold your hand       You're not the hurting kind
I want to hold your hand         What goes on in your mind?
````

[1]: https://github.com/nossidge/lyrics
[2]: https://genius.com/The-beatles-i-want-to-hold-your-hand-lyrics


### As a Ruby Gem

To make a poefy database and generate poems from it:

```ruby
require 'poefy'

# Choose one of the below require lines.
require 'poefy/pg'
require 'poefy/sqlite3'

# Or you could just run this. It will require the
# database gem that is specified in 'settings.yml'
Poefy.require_db

# Set up a Poem object using the name of the corpus.
poefy = Poefy::Poem.new('shakespeare')

# Filename is the text file containing the lines.
# Description is an explanation of the data.
filename    = 'shakespeare_sonnets.txt'
description = 'The sonnets of Shakespeare'
poefy.make_database(filename, description)

# Close the database link.
poefy.close
```

`filename` will accept a string path to a file, an array of lines, or a long string delimited by newlines. `description` is optional.

You only have to make the database once. And then to generate poems:

```ruby
# Different ways to generate sonnets
poefy = Poefy::Poem.new('shakespeare')
puts poefy.poem ({ rhyme: 'ababcdcdefefgg' })
puts poefy.poem ({ rhyme: 'abab cdcd efef gg', indent: '0101 0101 0011 01' })
puts poefy.poem ({ form: 'sonnet' })
puts poefy.poem ({ form: :sonnet, syllable: 0 })
puts poefy.poem ({ form: :sonnet, syllable: 10 })
puts poefy.poem ({ form: :sonnet, regex: /^[A-Z]/ })
puts poefy.poem ({ form: :sonnet, regex: '^[A-Z]' })
puts poefy.poem ({ form: :sonnet, acrostic: 'pauldpthompson' })
puts poefy.poem ({ form: 'sonnet', indent: '01010101001101' })
puts poefy.poem ({ form: 'sonnet', proper: false })
puts poefy.poem ({ form_from_text: 'how_do_i_love_thee.txt' })
puts poefy.poem ({ form_from_text: 'how_do_i_love_thee.txt', syllable: 0 })
poefy.close
```

The #poem method requires at least one option of `:rhyme`, `:form`, or `:form_from_text`

All options can be specified at object initialisation, and subsequent poems will use those options as default:

```ruby
# Default to use rondeau poetic form, and proper sentence validation
poefy = Poefy::Poem.new('shakespeare', { form: 'rondeau', proper: true })

# Generate a properly sentenced rondeau
puts poefy.poem

# Generate a rondeau without proper validation
puts poefy.poem ({ proper: false })

# Generate a proper rondeau with a certain indentation
puts poefy.poem ({ indent: '01012 0012 010112' })

poefy.close
```


#### Option `transform:`

An option that is not included in the CLI interface is the `transform` poem option. This is a hash of procs that transform a line somehow.

For example, to all-caps the 4th and 12th lines:

```ruby
transform_hash = {
   4 => proc { |line, num, poem| line.upcase },
  12 => proc { |line, num, poem| line.upcase }
}
poefy = Poefy::Poem.new 'shakespeare'
puts poefy.poem({ form: :sonnet, transform: transform_hash })
poefy.close
```

The key for the hash corresponds to the line of the poem, starting from 1 (not 0). You can use negative keys to specify from the end of the poem. Any key that is not an integer or is out of the array bounds will be ignored.

If you don't include a hash, then the proc will be applied to each line. So to add line numbers to the whole poem:

```ruby
transform_proc = proc { |line, num, poem| "#{num.to_s.rjust(2)} #{line}" }
poefy = Poefy::Poem.new 'shakespeare'
puts poefy.poem({ form: :sonnet, transform: transform_proc })
poefy.close
```

The proc arguments `|line, num, poem|` are: the text of the line that is being replaced, the number of the line, and the full poem array as it was before any transformations had occurred.

The transformations are implemented after the poem has been generated, but before the `indent` has occurred.


#### Corpus internals

The `Poefy::Poem.poem` method will do the work of creating a poem for you, but the object also exposes more information about the corpus, if you need it. This is done through the `Poefy::Poem.corpus` object.

```ruby
# If the corpus database already exists:
poefy = Poefy::Poem.new('shakespeare')
puts poefy.corpus.type      # "sqlite3" or "pg"
puts poefy.corpus.name      # "shakespeare"
puts poefy.corpus.count     # 2137
puts poefy.corpus.exist?    # true

# If the corpus has not been generated yet:
poefy = Poefy::Poem.new('plath')
puts poefy.corpus.type      # "sqlite3" or "pg"
puts poefy.corpus.name      # "plath"
puts poefy.corpus.count     # 0
puts poefy.corpus.exist?    # false
```

To view or change the description of the corpus.

```ruby
poefy = Poefy::Poem.new('shakespeare')
puts 'Initial description:  ' + poefy.corpus.desc
# Initial description:  Shakespeare's sonnets

poefy.corpus.desc = 'a brand new string'
puts 'Updated description:  ' + poefy.corpus.desc
# Updated description:  a brand new string
```

There's also a public interface to find rhyming lines within the corpus. Let's say we need to find 6 lines with the same rhyme. First, we will get an array of all rhyme keys that have at least 6 distinct final words. Then select one rhyme at random. Use that rhyme to find all lines that have that rhyme key, and remove lines with duplicate last words (so that we don't rhyme e.g. "tree" with "tree"). Then grab a sample 6 lines from that array.

```ruby
poefy = Poefy::Poem.new('shakespeare')
line_count = 6

rhymes = poefy.corpus.rhymes_by_count(line_count)
rhyme = rhymes.sample['rhyme']
lines = poefy.corpus.lines_by_rhyme(rhyme)
lines = lines.map{ |i| i['line'] }.shuffle
lines.uniq!{ |i| i.to_phrase.last_word.downcase }
puts lines.sample(line_count)

# Mine eye and heart are at a mortal war,
# Like as the waves make towards the pebbled shore,
# Let those whom nature hath not made for store,
# All mine was thine, before thou hadst this more.
# O! though I love what others do abhor,
# To show false Art what beauty was of yore.
```

You can also specify a range for the lines' syllable counts. Just use a hash with keys ':min' and ':max' as the second argument.

```ruby
poefy = Poefy::Poem.new('whitman')
line_count = 6
syllables = {min: 8, max: 8}

rhymes = poefy.corpus.rhymes_by_count(line_count, syllables)
rhyme = rhymes.sample['rhyme']
lines = poefy.corpus.lines_by_rhyme(rhyme, syllables)
lines = lines.map{ |i| i['line'] }.shuffle
lines.uniq!{ |i| i.to_phrase.last_word.downcase }
puts lines.sample(line_count)

# As I wended the shores I know,
# Rhone, and the Guadalquiver flow,
# Scooting obliquely high and low.
# O heart-sick days! O nights of woe!
# Ceaseless she paces to and fro,
# To be lost if it must be so!
```

`#rhymes_by_count` and `#lines_by_rhyme` are the only stored procedures that return corpus lines. All the other filtering and line arrangement is done based on the records returned by these two methods.


## Some tips

### Make a database from a delimited file

Databases are created using data piped into poefy, so you can do any pre-processing before piping.

Use awk to get final field from tab delimited IRC logs.

    $ awk -F$'\t' '{print $NF}' irc_log_20170908.txt | poefy -m irc


### Make a database, ignoring short lines

Use sed to filter out lines that are too short:

    $ sed -r '/^.{,20}$/d' st_therese_of_lisieux.txt | poefy -m therese


### Make a database, ignoring uppercase lines

Use sed to filter out lines that do not contain lowercase letters. For example, the sonnets file contains lines with the number of the sonnet, e.g. "CXLVII."

    $ sed -r 'sed '/[a-z]/!d' shakespeare_sonnets.txt | poefy -m shakespeare


### Problem: it won't output lines that I know are valid

This code uses a gem called `wordfilter` that will automatically filter out lines that contain [grotty words](https://github.com/dariusk/wordfilter/blob/master/lib/badwords.json). If you really definitely truly don't want to exclude a certain word, you can remove that word from the blacklist. For example, if your input lines are from a dissertation on the dance styles of the ska and reggae music scenes, in your Ruby code you can call:

```ruby
Wordfilter.remove_word('skank')
```


### Problem: no seriously, it just won't work.

Remember that the `proper` option is `true` by default. Maybe try setting this to `false` with the `-p` option?


## Sample output

### William Shakespeare, villanelle

    $ poefy shakespeare villanelle

````
How many a holy and obsequious tear
  Whilst many nymphs that vowed chaste life to keep
From thee, the pleasure of the fleeting year!

For truth proves thievish for a prize so dear.
And his love-kindling fire did quickly steep
  How many a holy and obsequious tear

If thy soul check thee that I come so near,
Cupid laid by his brand and fell asleep:
  From thee, the pleasure of the fleeting year!

Not making worse what nature made so clear,
Whilst my poor lips which should that harvest reap,
  How many a holy and obsequious tear

Or, if they sing, 'tis with so dull a cheer,
Do I envy those jacks that nimble leap,
  From thee, the pleasure of the fleeting year!

And even thence thou wilt be stol'n I fear,
The world will be thy widow and still weep
  How many a holy and obsequious tear
  From thee, the pleasure of the fleeting year!
````


### Emily Dickinson, ballads

    $ poefy dickinson ballad

````
Enlarged beyond my utmost scope,
  It waits upon the lawn;
A purple finger on the slope;
  It wrinkled, and was gone.

Wisdom is more becoming viewed
  And yet with amber hands
I taste a liquor never brewed,
  Bound to opposing lands.

Confided are his projects pink
  To say good-by to men.
And blushing birds go down to drink,
  Unto the east again.

You, unsuspecting, wear me too --
  And yet abide the world!
Whose garden wrestles with the dew,
  The flying tidings whirled.

We never know how high we are
  I could not die with you,
Past midnight, past the morning star!
  That maketh all things new.
````


### Walt Whitman, Petrarchan sonnet

    $ poefy whitman petrarchan

````
I see the seal-seeker in his boat poising his lance,
  I am of the same style, for I am their friend,
  We the youthful sinewy races, all the rest on us depend,
Away with old romance!

O something unprov'd! something in a trance!
  Listen, lose not, it is toward thee they tend,
  But I do not talk of the beginning or the end.
And the dead advance as much as the living advance,

I am a dance--play up there! the fit is whirling me fast!
  I am the credulous man of qualities, ages, races,
From the chants of the feudal world, the triumphs of kings, slavery, caste,

Garrulous to the very last.
  An old man bending I come among new faces,
To justify the past.
````


### English As She Is Spoke, haikus

    $ poefy spoke haiku

````
What I may to eat?
Vegetables boiled to a pap
It is excellent.

Go through that meadow.
I am going to Cadiz.
With a inn keeper.

The gossip mistress
You not make who to babble.
You interompt me.

The fat of the Leg
This girl have a beauty edge.
You shall catch cold one's.

How the times are changed!
We have sung, danced, laugh and played.
The curtains let down.
````


### St. Therese of Lisieux, villanelle

    $ poefy therese villanelle

````
I shall behold Thy lovely Face once more,
  And, oh! remember thou thy "little queen," --
Joy seems on us to pour.

Remember Thou that on my native shore,
With Him for Guide, the fight I face serene;
  I shall behold Thy lovely Face once more,

And for His grace alone implore;
And murmuring a prayer for her, "thy queen,"
  Joy seems on us to pour.

I come with comfort for sad hearts and sore.
Remember thou thy faithful child, Celine,
  I shall behold Thy lovely Face once more,

Then angel-hands shall ope the door;
Beside her King shall yet be seen.
  Joy seems on us to pour.

Comes to my ear sin's wild and blasphemous roar;
Remember thou that on the terrace green
  I shall behold Thy lovely Face once more,
  Joy seems on us to pour.
````


### Walt Whitman, lipogram sonnet on 'e'

    $ poefy whitman sonnet -x'^[^e]*$'

````
Land! land! O land!
Boston bay.
bright sword in thy hand,
on our way?
many a star at night,
stand fast;)
plain sight,
In full rapport at last.
I wait for a boat,
musical rain,
ribs and throat,
thousands slain,
walk hand in hand.
Of city for city and land for land.
````


### William Shakespeare, acrostic sonnet

    $ poefy shakespeare sonnet -s10 -a'pauldpthompson'

````
Pitiful thrivers, in their gazing spent?
And such a counterpart shall fame his wit,
Under the blow of thralled discontent,
Let him but copy what in you is writ,
Death's second self, that seals up all in rest.
Past reason hated, as a swallowed bait,
Then, in the blazon of sweet beauty's best,
Haply I think on thee, and then my state,
One blushing shame, another white despair;
My heart doth plead that thou in him dost lie,
Past cure I am, now Reason is past care,
She carved thee for her seal, and meant thereby,
Oh sure I am the wits of former days,
Nor gates of steel so strong but Time decays?
````
