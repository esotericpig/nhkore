# NHKore

[![Gem Version](https://badge.fury.io/rb/nhkore.svg)](https://badge.fury.io/rb/nhkore)

[![Source Code](https://img.shields.io/badge/source-github-%23A0522D.svg?style=for-the-badge)](https://github.com/esotericpig/nhkore)
[![Changelog](https://img.shields.io/badge/changelog-md-%23A0522D.svg?style=for-the-badge)](CHANGELOG.md)
[![License](https://img.shields.io/github/license/esotericpig/nhkore.svg?color=%23A0522D&style=for-the-badge)](LICENSE.txt)

A CLI app that scrapes [NHK News Web Easy](https://www3.nhk.or.jp/news/easy/) to create a list of each word and its frequency (how many times it was used) for Japanese language learners.

This is similar to a [core word/vocabulary list](https://www.fluentin3months.com/core-japanese-words/), hence the name NHKore.

In the future, I would like to add the regular NHK News, using the links from the easy versions.

## Contents

- [Installing](#installing)
- [Using](#using)
- [Hacking](#hacking)
- [License](#license)

## [Installing](#contents)

Pick your poison...

With the RubyGems CLI package manager:

`$ gem install nhkore`

Manually:

```
$ git clone 'https://github.com/esotericpig/nhkore.git'
$ cd nhkore
$ bundle install
$ bundle exec rake install:local
```

## [Using](#contents)

TODO: update README Using section

## [Hacking](#contents)

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

### Generating Documentation

```
$ bundle exec rake doc
```

## [License](#contents)

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
