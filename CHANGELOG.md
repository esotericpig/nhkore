# Changelog | NHKore

All notable changes to this project will be documented in this file.

Format is based on [Keep a Changelog v1.0.0](https://keepachangelog.com/en/1.0.0),
and this project adheres to [Semantic Versioning v2.0.0](https://semver.org/spec/v2.0.0.html).

## [[Unreleased]](https://github.com/esotericpig/nhkore/compare/v0.3.13...HEAD)
-


## [v0.3.13] - 2022-04-27

### Fixed
- Updated gems (`nokogiri`).
- Added `rss` gem (no longer included with Ruby core).


## [v0.3.12] - 2022-02-27

### Fixed
- Updated `nokogiri` gem for *Dependabot* security vulnerability.

### Changed
- Added border/frame to post install message in Gemspec.


## [v0.3.11] - 2021-10-25

### Fixed
- Updated `nokogiri` gem for *Dependabot* security vulnerability.


## [v0.3.10] - 2021-07-13

### Fixed
- Updated `public_suffix` gem, which has a dependency on `addressable` gem vulnerability found by *Dependabot*.


## [v0.3.9] - 2021-06-26

### Fixed
- Reverted `App#refresh_cmd()` back to not copying over the `default_proc` (from v0.3.8). Because the old code didn't know about this, it created some unintended issues with command options. Nothing major, but for example, specifying `output.html` with the `sift` command would not produce HTML output (however, using the `-e html` option still worked). This is the only instance that I know of, but reverting the code back in case of more instances. In the future, I'll need to thoroughly test all CLI options after changing `App#refresh_cmd()` to copy over the `default_proc`, but for now, not worrying about it (as it's not necessary).


## [v0.3.8] - 2021-06-26

### Fixed
- Fixed `App#refresh_cmd()` to also copy Cri's `default_proc` to the new Hash for the command options.
- Fixed to check for non-strings for JSON & URI.
    - For JSON, convert `StringIO` to string in `DictScraper.scrape()`.
    - For URL, convert URL using `URI()` because `URI.parse()` will crash with a non-string (URI object) in `Scraper.open_url()`.
- Fixed to scrape multiple HTML Ruby tag words (instead of just 1).
    - I thought multiple Ruby bases/texts (`<rb>`/`<rt>`) were invalid, but after running into the article below and checking the HTML with a validator, it's actually valid HTML:
          - https://www3.nhk.or.jp/news/easy/k10012759201000/k10012759201000.html
          - No previous articles/URLs ran into this problem (would have raised an error), so it should only be a problem with this specific, new article.

### Changed
- Formatted/Linted all code using RuboCop.
- Updated Gems.


## [v0.3.7] - 2020-11-07

### Changed
- Updated Gem `attr_bool` to v0.2
- Changed upper-case *'-V'* flag for *version* to be a lower-case *'-v'*
    - Seems like a lot of apps/people expect this
- Refactored/Formatted some code
    - *nhkore.gemspec* especially
- Added *samples/*, *Gemfile.lock*, and *.yardopts* to the files in *nhkore.gemspec*

### Fixed
- ArticleScraper
    - Fixed to accept text nodes that have Kanji, due to bad article:
        - https://www3.nhk.or.jp/news/easy/k10012639271000/k10012639271000.html
            - `第３のビール` should have HTML ruby tags around *第*


## [v0.3.6] - 2020-08-18

### Added
- `update_showcase` Rake task for development & personal site (GitHub Page)
    - `$ bundle exec rake update_showcase`

### Changed
- Updated Gems

### Fixed
- ArticleScraper for title for specific site
    - https://www3.nhk.or.jp/news/easy/article/disaster_earthquake_illust.html
- Ignored `/cgi2.*enqform/` URLs from SearchScraper (Bing)
- Added more detail to dictionary error in ArticleScraper


## [v0.3.5] - 2020-05-04

### Added
- Added check for environment var `NO_COLOR`
    - [https://no-color.org/](https://no-color.org/)

### Fixed
- Fixed URLs stored in YAML data to always be of type String (not URI)
    - This initially caused a problem in DictScraper.parse_url() from ArticleScraper, but fixed it for all data


## [v0.3.4] - 2020-04-25

### Added
- DatetimeParser
    - Extracted from SiftCmd into its own class
    - Fixed some minor logic bugs from the old code
    - Added new feature where 1 range can be empty:
        - `sift ez -d '...2019'` (from = 1924)
        - `sift ez -d '2019...'` (to = current year)
        - `sift ez -d '...'` (still an error)
- Added `update_core` rake task for dev
    - Makes pushing a new release much easier
    - See *Hacking.Releasing* section in *README*

### Fixed
- SiftCmd `parse_sift_datetime()` for `-d/--datetime` option
    - Didn't work exactly right (as written in *README*) for some special inputs:
        - `-d '2019...3'`
        - `-d '3-3'`
        - `-d '3'`


## [v0.3.3] - 2020-04-23

### Added
- Added JSON support to Sifter & SiftCmd.
- Added use of `attr_bool` Gem for `attr_accessor?` & `attr_reader?`.


## [v0.3.2] - 2020-04-22

### Added
- lib/nhkore/lib.rb
    - Requires all files, excluding CLI-related files for speed when using this Gem as a library.
- Scraper
    - Added open_file() & reopen().
- samples/looper.rb
    - Script example of continuously scraping all articles.

### Changed
- README
    - Finished writing the initial version of all sections.
- ArticleScraper
    - Changed the `year` param to expect an int, instead of a string.
- Sifter
    - In filter_by_datetime(), renamed keyword args `from_filter,to_filter` to simply `from,to`.

### Fixed
- Reduced load time of app a tiny bit more (see v0.3.1 for details).
- ArticleScraper
    - Renamed `mode` param to `strict`. `mode` was overshadowing File.open()'s in Scraper.


## [v0.3.1] - 2020-04-20

### Changed
- Fleshed out more of README.
- NewsCmd/SiftCmd
    - Added `--no-sha256` option to not check if article links have already been scraped based on their contents' SHA-256.
- Util
    - Changed `dir_str?()` and `filename_str?()` to check any slash. Previously, it only checked the slash for your system. But now on both Windows & Linux, it will check for both `/` & `\`.

### Fixed
- Reduced load time of app from about 1s to about 0.3-0.5s.
    - Moved many `require '...'` statements into methods.
    - It looks ugly & is not good coding practice, but a necessary evil.
    - Load time is still pretty slow (but a lot better!).
- BingScraper
    - Fixed possible RSS infinite loop.


## [v0.3.0] - 2020-04-12

### Added
- UserAgents
    - Tons of random `User-Agent` strings for `Scraper`.

### Changed
- BingCmd => SearchCmd
    - Major (breaking) change.
    - Changed `$ nhkore bing easy` to:
        - `$ nhkore search easy bing`
        - `$ nhkore se ez b`
- App
    - Added options:
        - `--color` (force color output for demos)
        - `--user-agent` (specify a custom HTTP header field `User-Agent`)
    - If `out_dir` is empty, don't prompt if okay to overwrite.
- README/nhkore.gemspec
    - Added more info.
    - Changed description.

### Fixed
- Scraper/BingScraper
    - Big fix.
    - Fixed to get around bing's strictness.
        - Use a random `User-Agent` from `UserAgents`.
        - Set HTTP header field `cookie` from `set-cookie` response.
            - Added `http-cookie` gem.
        - Use RSS as a fallback.
- GetCmd
    - When extracting files...
        - ignore empty filenames in the Zip for safety.
        - ask to overwrite files instead of erroring.


## [v0.2.0] - 2020-04-01

First working version.

### Added
- Gemfile.lock
- lib/nhkore/app.rb
- lib/nhkore/article.rb
- lib/nhkore/article_scraper.rb
- lib/nhkore/cleaner.rb
- lib/nhkore/defn.rb
- lib/nhkore/dict.rb
- lib/nhkore/dict_scraper.rb
- lib/nhkore/entry.rb
- lib/nhkore/error.rb
- lib/nhkore/fileable.rb
- lib/nhkore/missingno.rb
- lib/nhkore/news.rb
- lib/nhkore/polisher.rb
- lib/nhkore/scraper.rb
- lib/nhkore/search_link.rb
- lib/nhkore/search_scraper.rb
- lib/nhkore/sifter.rb
- lib/nhkore/splitter.rb
- lib/nhkore/util.rb
- lib/nhkore/variator.rb
- lib/nhkore/cli/bing_cmd.rb
- lib/nhkore/cli/fx_cmd.rb
- lib/nhkore/cli/get_cmd.rb
- lib/nhkore/cli/news_cmd.rb
- lib/nhkore/cli/sift_cmd.rb
- test/nhkore/test_helper.rb

### Removed
- test/nhkore_tester.rb
    - Renamed to `test/nhkore/test_helper.rb`


## [v0.1.0] - 2020-02-24

### Added
- .gitignore
- CHANGELOG.md
- Gemfile
- LICENSE.txt
- nhkore.gemspec
- Rakefile
- README.md
- TODO.md
- bin/nhkore
- lib/nhkore.rb
- lib/nhkore/version.rb
- lib/nhkore/word.rb
- test/nhkore_test.rb
- test/nhkore_tester.rb
- yard/templates/default/layout/html/footer.erb
