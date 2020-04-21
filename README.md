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

Currently, it only searches & scrapes `bing.com`, but other search engines and/or methods can easily be added in the future.

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

[![asciinema Demo - News](https://asciinema.org/a/322324.png)](https://asciinema.org/a/322324)

When I first scraped all of the articles in [nhkore-core.zip](https://github.com/esotericpig/nhkore/releases/latest), I used a script similar to the one below because my internet isn't very good.

If you run this script, be aware that it uses the `-F` force option (which overwrites files without prompting).

```Ruby
#!/usr/bin/env ruby
# encoding: UTF-8
# frozen_string_literal: true

# looper.rb

case ARGV[0]
when '-c' # count
  system('nhkore search ez --show-count')
  puts
  puts 'Use the first number with the -a option.'
  exit
when '-a' # articles
  articles = ARGV[1].to_i()
  articles = 0 if articles < 0
else
  puts 'Options:'
  puts '  -c          show count to use with -a'
  puts '  -a <int>    number of articles already scraped; execute scraping'
  exit
end

articles_inc = 25
max_errors   = 5 # Exit, for example, if 404 errors repeatedly
max_loop     = 5 # Possible total = articles_inc * max_loop

thread = Thread.new() do
  i = 0
  
  while i < max_loop
    puts "Loop #{i += 1} => #{articles} articles"
    
    if system("nhkore -F -t 300 -m 10 news ez -s #{articles_inc}")
      articles += articles_inc
    else
      break if (max_errors -= 1) <= 0
    end
    
    puts
  end
end

# Ctrl+C
trap('INT') do
  if thread.alive?()
    # Try to exit gracefully.
    max_loop = -1
    thread.join(5)
    
    # Die!
    thread.kill() if thread.alive?()
  end
  
  exit
end

thread.join() # Run
```

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
gem 'nhkore', :git => 'https://github.com/esotericpig/nhkore.git', :tag => 'vX.X.X'
```

### Require

In order to not require all of the CLI-related files, require this file instead:

```Ruby
require 'nhkore/lib'

#require 'nhkore' # Slower
```

### Scraper

All scraper classes extend this class. You can either extend it or use it by itself. It's a simple wrapper around *open-uri*, *Nokogiri*, etc.

`initialize` automatically opens (connects to) the URL.

```Ruby
require 'nhkore/scraper'

class MyScraper < NHKore::Scraper
  def initialize()
    super('https://www3.nhk.or.jp/news/easy/')
  end
end

m = MyScraper.new()
s = NHKore::Scraper.new('https://www3.nhk.or.jp/news/easy/')

# Read all content into a String.
mstr = m.read()
sstr = s.read()

# Get a Nokogiri::HTML object.
mdoc = m.html_doc()
sdoc = s.html_doc()

# Get a RSS object.
s = NHKore::Scraper.new('https://www.bing.com/search?format=rss&q=site%3Anhk.or.jp%2Fnews%2Feasy%2F&count=100')

rss = s.rss_doc()
```

There are several useful options:

```Ruby
require 'nhkore/scraper'

s = NHKore::Scraper.new('https://www3.nhk.or.jp/news/easy/',
  open_timeout: 300, # Open timeout in seconds (default: nil)
  read_timeout: 300, # Read timeout in seconds (default: nil)
  
  # Maximum number of times to retry the URL
  # - default: 3
  # - Open/connect will fail a couple of times on a bad/slow internet connection.
  max_retries: 10,
  
  # Maximum number of redirects allowed.
  # - default: 3
  # - You can set this to nil or -1, but I recommend using a number
  #   for safety (infinite-loop attack).
  max_redirects: 1,
  
  # How to check redirect URLs for safety.
  # - default: :strict
  # - nil      => do not check
  # - :lenient => check the scheme only
  #               (i.e., if https, redirect URL must be https)
  # - :strict  => check the scheme and domain
  #               (i.e., if https://bing.com, redirect URL must be https://bing.com)
  redirect_rule: :lenient,
  
  # Set the HTTP header field 'cookie' from the 'set-cookie' response.
  # - default: false
  # - Currently uses the 'http-cookie' Gem.
  # - This is currently a time-consuming operation because it opens the URL twice.
  # - Necessary for Search Engines or other sites that require cookies
  #   in order to block bots.
  eat_cookie: true,
  
  # Set HTTP header fields.
  # - default: nil
  # - Necessary for Search Engines or other sites that try to block bots.
  # - Simply pass in a Hash (not nil) to set the default ones.
  header: {'user-agent' => 'Skynet'}, # Must use strings
)

# Open the URL yourself. This will be passed in directly to Nokogiri::HTML().
# - In this way, you can use Faraday, HTTParty, RestClient, httprb/http, or
#   some other Gem.
s = NHKore::Scraper.new('https://www3.nhk.or.jp/news/easy/',
  str_or_io: URI.open('https://www3.nhk.or.jp/news/easy/',redirect: false)
)

# Open and parse a file instead of a URL (for offline testing or slow internet).
s = NHKore::Scraper.new('./my_article.html',is_file: true)

doc = s.html_doc()
```

Here are some other useful methods:

```Ruby
require 'nhkore/scraper'

s = NHKore::Scraper.new('https://www3.nhk.or.jp/news/easy/')

s.reopen() # Re-open the current URL.

# Get a relative URL.
url = s.join_url('../../monkey.html')
puts url # https://www3.nhk.or.jp/monkey.html

# Open a new URL or file.
s.open(url)
s.open(url,URI.open(url,redirect: false))

s.open('./my_article.html',is_file: true)

# Open a file manually.
s.open_file('./my_article.html')

# Fetch the cookie & open a new URL manually.
s.fetch_cookie(url)
s.open_url(url)
```

### SearchScraper & BingScraper

`SearchScraper` is used for scraping Search Engines for NHK News Web (Easy) links. It can also be used for search in general.

By default, it sets the default HTTP header fields and fetches & sets the cookie.

```Ruby
require 'nhkore/search_scraper'

ss = NHKore::SearchScraper.new('https://www.bing.com/search?q=nhk&count=100')

doc = ss.html_doc()

doc.css('a').each() do |anchor|
  link = anchor['href']
  
  next if ss.ignore_link?(link)
  
  if link.include?('https://www3.nhk')
    puts link
  end
end
```

`BingScraper` will search `bing.com` for you.

```Ruby
require 'nhkore/search_link'
require 'nhkore/search_scraper'

bs     = NHKore::BingScraper.new(:yasashii)
slinks = NHKore::SearchLinks.new()

next_page = bs.scrape(slinks)
page_num  = 1

while !next_page.empty?()
  puts "Page #{page_num += 1}: #{next_page.count}"
  
  bs = NHKore::BingScraper.new(:yasashii,url: next_page.url)
  
  next_page = bs.scrape(slinks,next_page)
end

slinks.links.values.each() do |link|
  puts link.url
end
```

### ArticleScraper & DictScraper

`ArticleScraper` scrapes an NHK News Web Easy article. Regular articles aren't currently supported.

```Ruby
require 'nhkore/article_scraper'

as = NHKore::ArticleScraper.new(
  'https://www3.nhk.or.jp/news/easy/k10011862381000/k10011862381000.html',
  
  # If false, scrape the article leniently (for older articles which
  # may not have certain tags, etc.).
  # - default: true
  strict: false,
  
  # {Dict} to use as the dictionary for words (Easy articles).
  # - default: :scrape
  # - nil     => don't scrape/use it (necessary for Regular articles)
  # - :scrape => auto-scrape it using {DictScraper}
  # - {Dict}  => your own {Dict}
  dict: nil,
  
  # Date time to use as a fallback if the article doesn't have one
  # (for older articles).
  # - default: nil
  datetime: Time.new(2020,2,2),
  
  # Year to use as a fallback if the article doesn't have one
  # (for older articles).
  # - default: nil
  year: 2020,
)

article = as.scrape()

article.datetime
article.futsuurl
article.sha256
article.title
article.url

article.words.each() do |key,word|
  word.defn
  word.eng
  word.freq
  word.kana
  word.kanji
  word.key
end

puts article.to_s(mini: true)
puts '---'
puts article
```

`DictScraper` scrapes an Easy article's dictionary file (JSON).

```Ruby
require 'nhkore/dict_scraper'

url = 'https://www3.nhk.or.jp/news/easy/k10011862381000/k10011862381000.html'
ds  = NHKore::DictScraper.new(
  url,
  
  # Change the URL appropriately to the dictionary URL.
  # - default: true
  parse_url: true,
)

puts NHKore::DictScraper.parse_url(url)
puts

dict = ds.scrape()

dict.entries.each() do |key,entry|
  entry.id
  
  entry.defns.each() do |defn|
    defn.hyoukis.each() {|hyouki| }
    defn.text
    defn.words.each() {|word| }
  end
  
  puts entry.build_hyouki()
  puts entry.build_defn()
  puts '---'
end

puts
puts dict
```

### Fileable

Any class that includes the `Fileable` mixin will have the following methods:

- Class.load_file(file,mode: 'rt:BOM|UTF-8',**kargs)
- save_file(file,mode: 'wt',**kargs)

Any *kargs* will be passed to `File.open()`.

```Ruby
require 'nhkore/news'
require 'nhkore/search_link'

yn = NHKore::YasashiiNews.load_file()
sl = NHKore::SearchLinks.load_file(NHKore::SearchLinks::DEFAULT_YASASHII_FILE)

yn.articles.each() {|key,article| }
yn.sha256s.each()  {|sha256,url|  }

sl.links.each() do |key,link|
  link.datetime
  link.futsuurl
  link.scraped?
  link.sha256
  link.title
  link.url
end

#yn.save_file()
#sl.save_file(NHKore::SearchLinks::DEFAULT_YASASHII_FILE)
```

### Sifter

`Sifter` will sift & sort the `News` data into a single file. The data is sorted by frequency in descending order (i.e., most frequent words first).

```Ruby
require 'nhkore/news'
require 'nhkore/sifter'
require 'time'

news = NHKore::YasashiiNews.load_file()

sifter = NHKore::Sifter.new(news)

sifter.caption = 'Sakura Fields Forever!'

# Filter the data.
#sifter.filter_by_datetime(Time.new(2019,12,5))
sifter.filter_by_datetime(
  from: Time.new(2019,12,4),to: Time.new(2019,12,7)
)
sifter.filter_by_title('桜')
sifter.filter_by_url('k100')

# Ignore (or blank out) certain columns from the output.
sifter.ignore(:defn)
sifter.ignore(:eng)

# An array of the filtered & sorted words.
words = sifter.sift()

# Choose the file format.
#sifter.put_csv!()
#sifter.put_html!()
sifter.put_yaml!()

# Save to a file.
file = 'sakura.yml'

if !File.exist?(file)
  sifter.save_file(file)
end
```

### Util & UserAgents

These provide a variety of useful methods/constants.

Here are some of the most useful ones:

```Ruby
require 'nhkore/user_agents'
require 'nhkore/util'

include NHKore

puts '======='
puts '[ Net ]'
puts '======='
# Get a random User Agent for HTTP header field 'User-Agent'.
# - This is used by default in Scraper/SearchScraper.
puts "User-Agent:  #{UserAgents.sample()}"

uri = URI('https://www.bing.com/search?q=nhk')
Util.replace_uri_query!(uri,q: 'banana')

puts "URI query:   #{uri}" # https://www.bing.com/search?q=banana
# nhk.or.jp
puts "Domain:      #{Util.domain(URI('https://www.nhk.or.jp/news/easy').host)}"
# Ben &amp; Jerry&#39;s<br>
puts "Escape HTML: #{Util.escape_html("Ben & Jerry's\n")}"
puts

puts '========'
puts '[ Time ]'
puts '========'
puts "JST now:   #{Util.jst_now}"
# Drops in JST_OFFSET, does not change hour/min.
puts "JST time:  #{Util.jst_time(Time.now)}"
puts "JST year:  #{Util::JST_YEAR}"
puts "1999 sane? #{Util.sane_year?(1999)}" # true
puts "1776 sane? #{Util.sane_year?(1776)}" # false
puts "Guess 5:   #{Util.guess_year(5)}"    # 2005
puts "Guess 99:  #{Util.guess_year(99)}"   # 1999
puts
puts "JST timezone offset:        #{Util::JST_OFFSET}"
puts "JST timezone offset hour:   #{Util::JST_OFFSET_HOUR}"
puts "JST timezone offset minute: #{Util::JST_OFFSET_MIN}"
puts

puts '============'
puts '[ Japanese ]'
puts '============'

JPN = ['桜','ぶ','ブ']

def fmt_jpn()
  fmt = []
  
  JPN.each() do |x|
    x = yield(x)
    x = x ? "\u2B55" : Util::JPN_SPACE unless x.is_a?(String)
    fmt << x
  end
  
  return "[ #{fmt.join(' | ')} ]"
end

puts "          #{fmt_jpn{|x| x}}"
puts "Hiragana? #{fmt_jpn{|x| !!Util.hiragana?(x)}}"
puts "Kana?     #{fmt_jpn{|x| !!Util.kana?(x)}}"
puts "Kanji?    #{fmt_jpn{|x| !!Util.kanji?(x)}}"
puts "Reduce:   #{Util.reduce_jpn_space("'     '")}"
puts

puts '========='
puts '[ Files ]'
puts '========='
puts "Dir str?   #{Util.dir_str?('dir/')}"          # true
puts "Dir str?   #{Util.dir_str?('dir')}"           # false
puts "File str?  #{Util.filename_str?('file')}"     # true
puts "File str?  #{Util.filename_str?('dir/file')}" # false
```

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

### Installing Locally

You can make some changes/fixes to the code and then install your local version:

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
