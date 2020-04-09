# TODO | NHKore

## [vY]
- [ ] Add the ability to scrape/sift the regular news
    - Use the futsuurls from the easy news (in addition to bing)
    - [ ] Look up the kana/pronunciation using some gem?
    - [ ] Move easy-specific options to the `easy` sub commands (like `nhkore news --no-dict`)
- [ ] Add the ability to add translations using some dictionary gem?
    - At first, just English

## [vX]
- [ ] Save the `News` (scraped articles) faster
    - Either by `seek to end, and then write new data` or by using multiple files?
- [ ] Make `sifting` faster somehow? Multiple threads?
    - [ ] Multiple threads option for `get` and other compatible commands as well (global option)?

## [v1.0.0]
- [x] `news` command
- [x] `sift` command (output to CSV file)
- [x] Add `--no-color` option
- [x] Add files to release (zipped)
    - [x] Manually download Google results and scrape them
        - Ensures have all article links
- [x] `get` command for downloading release files
- [x] Add `sift` HTML output to my GitHub Pages
- [ ] Finish fleshing out README
    - [x] Add a section for non-coders (non-power-users) to README
    - [ ] Create & add asciinema links
- [ ] Create tests
    - [ ] Add to CI
- [ ] Add documentation
