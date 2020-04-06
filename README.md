# NHKore

[![Gem Version](https://badge.fury.io/rb/nhkore.svg)](https://badge.fury.io/rb/nhkore)

[![Source Code](https://img.shields.io/badge/source-github-%23211F1F.svg)](https://github.com/esotericpig/nhkore)
[![Changelog](https://img.shields.io/badge/changelog-md-%23A0522D.svg)](CHANGELOG.md)
[![License](https://img.shields.io/github/license/esotericpig/nhkore.svg)](LICENSE.txt)

A CLI app that scrapes [NHK News Web Easy](https://www3.nhk.or.jp/news/easy/) to create a list of each word and its frequency (how many times it was used) for Japanese language learners.

This is similar to a [core word/vocabulary list](https://www.fluentin3months.com/core-japanese-words/), hence the name NHKore.

In the future, I would like to add the regular NHK News, using the links from the easy versions.

[![asciinema Demo - Help](https://asciinema.org/a/MQTJ9vxcpB7VYAKzke7m4QM7P.png)](https://asciinema.org/a/MQTJ9vxcpB7VYAKzke7m4QM7P?speed=2)

## Contents

- [For Non-Power Users](#for-non-power-users-)
- [Installing](#installing-)
- [Using](#using-)
    - [The Basics](#the-basics-)
- [Hacking](#hacking-)
- [License](#license-)

## For Non-Power Users [^](#contents)

For non-Power Users, you're probably just interested in the data.

[Click here](https://esotericpig.github.io/showcase/nhkore-ez.html) for a big HTML file with the final result from all of the current articles scraped.

Also, [click here](https://github.com/esotericpig/nhkore/releases/latest) to go to the latest release and download `nhkore-core.zip` from the `Assets`. It contains all of the links scraped, all of the data scraped per article, and a final CSV file.

If you'd like to try using the app, please download and install [Ruby](https://www.ruby-lang.org/en/downloads/) and then follow the instructions below. You'll need to be able to use the command line.

## Installing [^](#contents)

Pick your poison...

With the RubyGems package manager:

`$ gem install nhkore`

Manually:

```
$ git clone 'https://github.com/esotericpig/nhkore.git'
$ cd nhkore
$ rake install
```

## Using [^](#contents)

### The Basics [^](#contents)

The most useful thing to do is to simply scrape one article and then study the most frequent words before reading that article.

First, scrape the article:

`$ nhkore news easy -u 'https://www3.nhk.or.jp/news/easy/k10011862381000/k10011862381000.html'`

If your internet is slow, there are several global options to help alleviate your internet woes, which can be used with any sub command:

```
-m --max-retry=<value>         maximum number of times to retry URLs (-1
                               or integer >= 0) (default: 3)
-o --open-timeout=<value>      seconds for URL open timeouts (-1 or
                               decimal >= 0)
-r --read-timeout=<value>      seconds for URL read timeouts (-1 or
                               decimal >= 0)
-t --timeout=<value>           seconds for all URL timeouts: [open, read]
                               (-1 or decimal >= 0)
```

Example usage:

`$ nhkore -t 300 -m 10 news easy -u 'https://www3.nhk.or.jp/news/easy/k10011862381000/k10011862381000.html'`

Some older articles will fail to scrape and need additional options (this is very rare):

```
-D --no-dict                   do not try to parse the dictionary files
                               for the articles; useful in case of errors
                               trying to load the dictionaries (or for
                               offline testing)
-L --lenient                   leniently (not strict) scrape articles:
                               body & title content without the proper
                               HTML/CSS classes/IDs and no futsuurl;
                               example URLs that need this flag:
                               -https://www3.nhk.or.jp/news/easy/article/disaster_earthquake_02.html
                               -https://www3.nhk.or.jp/news/easy/tsunamikeihou/index.html
-M --missingno                 very rarely an article will not have kana
                               or kanji for a Ruby tag; to not raise an
                               error, this will use previously scraped
                               data to fill it in; example URL:
                               -https://www3.nhk.or.jp/news/easy/k10012331311000/k10012331311000.html
-d --datetime=<value>          date time to use as a fallback in cases
                               when an article doesn't have one; format:
                               YYYY-mm-dd H:M; example: 2020-03-30 15:30
```

Example usage:

`$ nhkore -t 300 -m 10 news -D -L -M -d '2011-03-07 06:30' easy -u 'https://www3.nhk.or.jp/news/easy/tsunamikeihou/index.html'`

Now that the data from the article has been scraped, you can generate a CSV/HTML/YAML file of the words ordered by frequency:

```
$ nhkore sift easy -e csv
$ nhkore sift easy -e html
$ nhkore sift easy -e yml
```

Complete example:

[![asciinema Demo - The Basics](https://asciinema.org/a/316571.png)](https://asciinema.org/a/316571)

## Hacking [^](#contents)

```
$ git clone 'https://github.com/esotericpig/nhkore.git'
$ cd nhkore
$ bundle install
$ bundle exec rake -T
```

### Testing

```
$ bundle exec rake test
```

### Generating Doc

```
$ bundle exec rake doc
```

## License [^](#contents)

[GNU LGPL v3+](LICENSE.txt)

> NHKore (<https://github.com/esotericpig/nhkore>)  
> Copyright (c) 2020 Jonathan Bradley Whited (@esotericpig)  
> 
> NHKore is free software: you can redistribute it and/or modify  
> it under the terms of the GNU Lesser General Public License as published by  
> the Free Software Foundation, either version 3 of the License, or  
> (at your option) any later version.  
> 
> NHKore is distributed in the hope that it will be useful,  
> but WITHOUT ANY WARRANTY; without even the implied warranty of  
> MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
> GNU Lesser General Public License for more details.  
> 
> You should have received a copy of the GNU Lesser General Public License  
> along with NHKore.  If not, see <https://www.gnu.org/licenses/>.  
