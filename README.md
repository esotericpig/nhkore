# NHKore

[![Gem Version](https://badge.fury.io/rb/nhkore.svg)](https://badge.fury.io/rb/nhkore)

[![Source Code](https://img.shields.io/badge/source-github-%23211F1F.svg)](https://github.com/esotericpig/nhkore)
[![Changelog](https://img.shields.io/badge/changelog-md-%23A0522D.svg)](CHANGELOG.md)
[![License](https://img.shields.io/github/license/esotericpig/nhkore.svg)](LICENSE.txt)

A CLI app that scrapes [NHK News Web Easy](https://www3.nhk.or.jp/news/easy/) to create a list of each word and its frequency (how many times it was used) for Japanese language learners.

This is similar to a [core word/vocabulary list](https://www.fluentin3months.com/core-japanese-words/), hence the name NHKore.

[![asciinema Demo](https://asciinema.org/a/318958.png)](https://asciinema.org/a/318958)

## Contents

- [For Non-Power Users](#for-non-power-users-)
- [Installing](#installing-)
- [Using](#using-)
    - [The Basics](#the-basics-)
    - [Unlimited Powah!](#unlimited-powah-)
        - [Get Command](#get-command-)
        - [Sift Command](#sift-command-)
    - [Sakura Fields Forever](#sakura-fields-forever-)
        - [Search Command](#search-command-)
        - [News Command](#news-command-)
- [Using the Library](#using-the-library-)
- [Hacking](#hacking-)
- [License](#license-)

## For Non-Power Users [^](#contents)

For non-Power Users, you are probably just interested in the data.

[Click here](https://esotericpig.github.io/showcase/nhkore-ez.html) for a big HTML file of the final result from all of the current articles scraped.

[Click here](https://github.com/esotericpig/nhkore/releases/latest) to go to the latest release and download `nhkore-core.zip` from the `Assets`. It contains all of the links scraped, all of the data scraped per article, and a final CSV file.

If you'd like to try using the app, please download and install [Ruby](https://www.ruby-lang.org/en/downloads/) and then follow the instructions below. You'll need to be able to use the command line.

## Installing [^](#contents)

Pick your poison...

With the RubyGems package manager:

`$ gem install nhkore`

Manually:

```
$ git clone 'https://github.com/esotericpig/nhkore.git'
$ cd nhkore
$ bundle install
$ bundle exec rake install:local
```

If there are errors running `nhkore`, you may need to also [install Nokogiri](https://nokogiri.org/tutorials/installing_nokogiri.html) manually, which is used for scraping HTML.

## Using [^](#contents)

### The Basics [^](#contents)

The most useful thing to do is to simply scrape one article and then study the most frequent words before reading that article.

First, scrape the article:

`$ nhkore news easy -u 'https://www3.nhk.or.jp/news/easy/k10011862381000/k10011862381000.html'`

If your internet is slow, there are several global options to help alleviate your internet woes, which can be used with any sub command:

```
-m --max-retry=<value>       maximum number of times to retry URLs
                             (-1 or integer >= 0) (default: 3)
-o --open-timeout=<value>    seconds for URL open timeouts
                             (-1 or decimal >= 0)
-r --read-timeout=<value>    seconds for URL read timeouts
                             (-1 or decimal >= 0)
-t --timeout=<value>         seconds for all URL timeouts: [open, read]
                             (-1 or decimal >= 0)
```

Example usage:

`$ nhkore -t 300 -m 10 news easy -u 'https://www3.nhk.or.jp/news/easy/k10011862381000/k10011862381000.html'`

Some older articles will fail to scrape and need additional options (this is very rare):

```
-D --no-dict             do not try to parse the dictionary files
                         for the articles; useful in case of errors
                         trying to load the dictionaries (or for offline testing)
-L --lenient             leniently (not strict) scrape articles:
                           body & title content without the proper
                           HTML/CSS classes/IDs and no futsuurl;
                         example URLs:
                         - https://www3.nhk.or.jp/news/easy/article/disaster_earthquake_02.html
                         - https://www3.nhk.or.jp/news/easy/tsunamikeihou/index.html
-M --missingno           very rarely an article will not have kana or kanji
                         for a Ruby tag; to not raise an error, this will
                         use previously scraped data to fill it in;
                         example URL:
                         - https://www3.nhk.or.jp/news/easy/k10012331311000/k10012331311000.html
-d --datetime=<value>    date time to use as a fallback in cases
                         when an article doesn't have one;
                         format: YYYY-mm-dd H:M; example: 2020-03-30 15:30
```

Example usage:

`$ nhkore -t 300 -m 10 news -D -L -M -d '2011-03-07 06:30' easy -u 'https://www3.nhk.or.jp/news/easy/tsunamikeihou/index.html'`

Now that the data from the article has been scraped, you can generate a CSV/HTML/YAML file of the words ordered by frequency:

```
$ nhkore sift easy -e csv
$ nhkore sift easy -e html
$ nhkore sift easy -e yml
```

Complete demo:

[![asciinema Demo - The Basics](https://asciinema.org/a/318958.png)](https://asciinema.org/a/318958)

### Unlimited Powah! [^](#contents)

Generate a core word list (e.g., CSV file) for 1 or more pre-scraped articles with ease.

Unlimited powah at your finger tips!

#### Get Command [^](#contents)

The `get` command will download and extract `nhkore-core.zip` from the [latest release](https://github.com/esotericpig/nhkore/releases/latest) for you.

This already has tons of articles scraped so that you don't have to re-scrape them. Then, for example, you can easily create a CSV file from all of `2019` or all of `December 2019`.

Example usage:

`$ nhkore get`

By default, it will extract the data to `./core/`. You can change this:

`$ nhkore get -o 'my dir/'`

Complete demo:

[![asciinema Demo - Get](https://asciinema.org/a/318967.png)](https://asciinema.org/a/318967)

#### Sift Command [^](#contents)

After obtaining the scraped data, you can `sift` all of the data (or select data) into one of these file formats:

| Format | Typical Purpose |
| --- | --- |
| CSV | For uploading to a flashcard website (e.g., Memrise, Anki, Buffl) after changing the data appropriately. |
| HTML | For comfortable viewing in a web browser or for sharing. |
| YAML | For developers to automatically add translations or to manipulate the data in some other way programmatically. |

The data is sorted by frequency in descending order (i.e., most frequent words first).

If you wish to sort/arrange the data in some other way, CSV editors (e.g., LibreOffice, WPS Office, Microsoft Office) can do this easily and efficiently, or if you are code-savvy, you can programmatically manipulate the CSV/YAML/HTML file.

The defaults will sift all of the data into a CSV file, which may not be what you want:

`$ nhkore sift easy`

You can filter the data by using different options:

```
-d --datetime=<value>    date time to filter on; examples:
                         - '2020-7-1 13:10...2020-7-31 11:11'
                         - '2020-12'   (2020, December 1st-31st)
                         - '7-4...7-9' (July 4th-9th of Current Year)
                         - '7-9'       (July 9th of Current Year)
                         - '9'         (9th of Current Year & Month)
-t --title=<value>       title to filter on, where search text only
                         needs to be somewhere in the title
-u --url=<value>         URL to filter on, where search text only
                         needs to be somewhere in the URL
```

Filter examples:

```
# Filter by URL.
$ nhkore sift easy -u 'k10011862381000'

# Filter by title.
$ nhkore sift easy -t 'マリオ'
$ nhkore sift easy -t '植えられた桜'

# Filter by date time.
$ nhkore sift easy -d 2019
$ nhkore sift easy -d '2019-12'
$ nhkore sift easy -d '2019-7-4...9' # July 4th to 9th of 2019
$ nhkore sift easy -d '2019-12-25 13:10'

# Filter by date time & title.
$ nhkore sift easy -d '2019-3-29' -t '桜'
```

You can save the data to a different format using one of these options:

```
-e --ext=<value>    type of file (extension) to save;
                    valid options: [csv, htm, html, yaml, yml];
                    not needed if you specify a file extension with
                    the '--out' option: '--out sift.html'
                    (default: csv)
-o --out=<value>    'directory/file' to save sifted data to;
                    if you only specify a directory or a file, it will
                    attach the appropriate default directory/file name
                    (defaults:
                     core/sift_nhk_news_web_easy{search.criteria}{file.ext},
                     core/sift_nhk_news_web_regular{search.criteria}{file.ext})
```

Format examples:

```
$ nhkore sift easy -e html
$ nhkore sift easy -e yml
$ nhkore sift easy -o 'mario.html'
$ nhkore sift easy -o 'sakura.yml'
```

Lastly, you can ignore certain columns from the output. Definitions can be quite long, and English translations are currently always blank (meant to be filled in manually/programmatically).

```
-D --no-defn    do not output the definitions for words
                (which can be quite long)
-E --no-eng     do not output the English translations for words
```

Complete demo:

[![asciinema Demo - Sift](https://asciinema.org/a/318982.png)](https://asciinema.org/a/318982)

### Sakura Fields Forever [^](#contents)

No more waiting on a new release with pre-scraped files.

Scrape all of the latest articles for yourself, forever!

#### Search Command [^](#contents)

The [news](#news-command-) command (for scraping articles) relies on having a file of article links.

Currently, the NHK website doesn't provide an historical record of all of its articles, and it's up to the user to find them.

The format of the file is simple, so you can edit it by hand (or programmatically) very easily:

```YAML
# core/links_nhk_news_web_easy.yml
---
links:
  https://www3.nhk.or.jp/news/easy/k10012323711000/k10012323711000.html:
    url: https://www3.nhk.or.jp/news/easy/k10012323711000/k10012323711000.html
    scraped: false
  https://www3.nhk.or.jp/news/easy/k10012321401000/k10012321401000.html:
    url: https://www3.nhk.or.jp/news/easy/k10012321401000/k10012321401000.html
    scraped: false
```

Only the key (which is the URL) and the `url` field are required. The rest of the fields will be populated when you scrape the data.

> &lt;rambling&gt;  
> Originally, I was planning on using a different key so that's why the URL is duplicated. This also allows for a possible future breaking version (major version change) to alter the key. In addition, I was originally planning to allow filtering in this file, so that's why additional fields are populated after scraping the data.  
> &lt;/rambling&gt;  

Example after running the `news` command:

```YAML
# core/links_nhk_news_web_easy.yml
# - After being scraped
---
links:
  https://www3.nhk.or.jp/news/easy/k10012323711000/k10012323711000.html:
    url: https://www3.nhk.or.jp/news/easy/k10012323711000/k10012323711000.html
    scraped: true
    datetime: '2020-03-11T16:00:00+09:00'
    title: 安倍総理大臣「今月２０日ごろまで大きなイベントをしないで」
    futsuurl: https://www3.nhk.or.jp/news/html/20200310/k10012323711000.html
    sha256: d1186ebbc2013564e52f21a2e8ecd56144ed5fe98c365f6edbd4eefb2db345eb
  https://www3.nhk.or.jp/news/easy/k10012321401000/k10012321401000.html:
    url: https://www3.nhk.or.jp/news/easy/k10012321401000/k10012321401000.html
    scraped: true
    datetime: '2020-03-11T11:30:00+09:00'
    title: 島根県の会社　中国から技能実習生が来なくて困っている
    futsuurl: https://www3.nhk.or.jp/news/html/20200309/k10012321401000.html
    sha256: 2df91884fbbafdc69bc3126cb0cb7b63b2c24e85bc0de707643919e4581927a9
```

If you don't wish to edit this file by hand (or programmatically), that's where the `search` command comes into play.

Currently, it only searches &amp; scrapes `bing.com`, but other search engines and/or methods can easily be added in the future.

Example usage:

`$ nhkore search easy bing`

There are a few notable options:

```
-r --results=<value>    number of results per page to request from search
                        (default: 100)
   --show-count         show the number of links scraped and exit;
                        useful for manually writing/updating scripts
                        (but not for use in a variable);
                        implies '--dry-run' option
   --show-urls          show the URLs -- if any -- used when searching &
                        scraping and exit; you can download these for offline
                        testing and/or slow internet (see '--in' option)
```

Complete demo:

[![asciinema Demo - Search](https://asciinema.org/a/320457.png)](https://asciinema.org/a/320457)

#### News Command [^](#contents)

In [The Basics](#the-basics-), you learned how to scrape 1 article using the `-u/--url` option with the `news` command.

After creating a file of links from the [search](#search-command-) command (or manually/programmatically), you can also scrape multiple articles from this file using the `news` command.

The defaults will scrape the 1st unscraped article from the `links` file:

`$ nhkore news easy`

You can scrape the 1st **X** unscraped articles with the `-s/--scrape` option:

```
# Scrape the 1st 11 unscraped articles.
$ nhkore news -s 11 easy
```

You may wish to re-scrape articles that have already been scraped with the `-r/--redo` option:

`$ nhkore news -r -s 11 easy`

If you only wish to scrape specific article links, then you should use the `-k/--like` option, which does a fuzzy search on the URLs. For example, `--like '00123'` will match these links:

- http<span>s://w</span>ww3.nhk.or.jp/news/easy/k1**00123**23711000/k10012323711000.html
- http<span>s://w</span>ww3.nhk.or.jp/news/easy/k1**00123**21401000/k10012321401000.html
- http<span>s://w</span>ww3.nhk.or.jp/news/easy/k1**00123**21511000/k10012321511000.html
- ...

`$ nhkore news -k '00123' -s 11 easy`

Lastly, you can show the dictionary URL and contents for the 1st article if you're getting dictionary-related errors:

```
# This will exit after showing the 1st article's dictionary.
$ nhkore news easy --show-dict
```

For the rest of the options, please see [The Basics](#the-basics-).

Complete demo:

## Using the Library [^](#contents)

### Setup

Pick your poison...

In your *Gemspec* (*&lt;project&gt;.gemspec*):

```Ruby
spec.add_runtime_dependency 'nhkore', '~> X.X'
```

In your *Gemfile*:

```Ruby
# Pick one...
gem 'nhkore', '~> X.X'
gem 'nhkore', :git => 'https://github.com/esotericpig/psychgus.git', :tag => 'vX.X.X'
```

### Scraper

## Hacking [^](#contents)

```
$ git clone 'https://github.com/esotericpig/nhkore.git'
$ cd nhkore
$ bundle install
$ bundle exec rake -T
```

Install Nokogiri:

```
$ bundle exec rake nokogiri_apt   # Ubuntu/Debian
$ bundle exec rake nokogiri_dnf   # Fedora/CentOS/Red Hat
$ bundle exec rake nokogiri_other # macOS, Windows, etc.
```

### Running

`$ ruby -w lib/nhkore.rb`

### Testing

`$ bundle exec rake test`

### Generating Doc

`$ bundle exec rake doc`

### Installing Locally (without Network Access)

`$ bundle exec rake install:local`

### Releasing/Publishing

`$ bundle exec rake release`

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
