# Changelog | NHKore

Format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [[Unreleased]](https://github.com/esotericpig/nhkore/compare/v0.3.0...master)

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
