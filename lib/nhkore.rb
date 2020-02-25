#!/usr/bin/env ruby
# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020 Jonathan Bradley Whited (@esotericpig)
# 
# NHKore is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# NHKore is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with NHKore.  If not, see <https://www.gnu.org/licenses/>.
#++


IS_TESTING = ($0 == __FILE__)

if IS_TESTING
  require 'rubygems'
  require 'bundler/setup'
end

require 'nhkore/article'
require 'nhkore/util'
require 'nhkore/version'
require 'nhkore/word'


require 'nokogiri'
require 'psychgus'

# 2 files:
# nhk_news_web_easy.yml
# (only Dec 2019 as an example; more in release)
# (add comment about above in this file)
# - 2019-12-25 13:10 JST: (append 1,2,... if duplicate)
#   - url: <url>
#   - md5: <md5sum of content only (in case of ads)>
#   - futsuurl: <url of actual news>
#   - words:
#     - word (kanji/kana):
#       - kana:
#       - freq:
# (only Dec 2019 as an example; more in release)
# nhk_news_web_easy_core_<search criteria>.csv
#   word, kana, freq
#   (sorted by freq, word, or kana [desc/asc])

# nhkore --date '2019-12-01 13:10 #2...2019-12-11 10:10 #2'
# nhkore --date '2019-12'
# nhkore --date '12'    (12 of this year and month)
# nhkore --date '12-01' (Dec 1 of this year)

hash = {
  datetime: '2020-02-25',
  futsuurl: 'google.com',
  sha256: '82a47a2bd57b433f4c21adc0ce44424a46250663e9dee702331005f42050e84f',
  words: {
    '日本語=にほんご' => {
      kana: 'にほんご',
      kanji: '日本語',
      freq: 101
    },
    '=バナナ' => {
      kana: 'バナナ',
      kanji: nil,
      freq: 11
    }
  }
}

a = NHKore::Article.load_hash('google.jp',hash)
puts a.to_s

###
# @author Jonathan Bradley Whited (@esotericpig)
# @since  0.1.0
###
module NHKore
end

# https://www3.nhk.or.jp/news/easy
# https://www.google.com/search?q=site:https://www3.nhk.or.jp/news/easy/&tbas=0&tbs=cdr:1,cd_min:1/1/2019,cd_max:12/31/2019,sbd:1&tbm=nws&sxsrf=ALeKk01oebeT0hWvNro-vDn7WGYkRe0kxw:1582396168988&ei=CHNRXt7dO5KR0QSTnZGYCw&start=20&sa=N&ved=0ahUKEwjega-M5eXnAhWSSJQKHZNOBLM4ChDy0wMIag&biw=1028&bih=672&dpr=1.3

#NHKore::App.new().run() if IS_TESTING
