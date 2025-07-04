# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020 Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++

require 'cgi'
require 'set'
require 'time'
require 'uri'

module NHKore
  module Util
    CORE_DIR = 'core'
    WEB_DIR = 'web'

    JST_OFFSET = '+09:00' # Japan Standard Time (JST) time zone offset from UTC
    JST_OFFSET_HOUR = 9
    JST_OFFSET_MIN = 0

    HIRAGANA_REGEX = /\p{Hiragana}/
    JPN_SPACE = "\u3000" # Must be double-quoted for escape chars.
    KANA_REGEX = /\p{Hiragana}|\p{Katakana}/
    KANJI_REGEX = /\p{Han}/ # Han probably stands for Hanzi?
    KATAKANA_REGEX = /\p{Katakana}/
    NORMALIZE_STR_REGEX = /[^[[:alpha:]]]+/
    STRIP_WEB_STR_REGEX = /(\A[[:space:]]+)|([[:space:]]+\z)/
    WEB_SPACES_REGEX = /[[:space:]]+/

    def self.jst_now
      return Time.now.getlocal(JST_OFFSET)
    end

    JST_YEAR = jst_now.year
    MAX_SANE_YEAR = JST_YEAR + 1 # +1 Justin Case for time zone differences at the end of the year

    # NHK was founded in 1924/25.
    # - https://www.nhk.or.jp/bunken/english/about/history.html
    # - https://en.wikipedia.org/wiki/NHK
    # However, when was the website first created?
    MIN_SANE_YEAR = 1924

    def self.dir_str?(str)
      return str.match?(%r{[/\\]\s*\z/})
    end

    def self.domain(host,clean: true)
      require 'public_suffix'

      domain = PublicSuffix.domain(host)
      domain = unspace_web_str(domain).downcase if !domain.nil? && clean

      return domain
    end

    def self.dump_yaml(obj,flow_level: 8,stylers: nil)
      require 'psychgus'

      stylers = Array(stylers)

      return Psychgus.dump(
        obj,
        deref_aliases: true, # Dereference aliases for load_yaml()
        header: true, # %YAML [version]
        line_width: 10_000, # Try not to wrap; ichiman!
        stylers: [
          Psychgus::FlowStyler.new(flow_level), # Put extra details on one line (flow/inline style)
          Psychgus::NoSymStyler.new(cap: false), # Remove symbols, don't capitalize
          Psychgus::NoTagStyler.new, # Remove class names (tags)
        ].concat(stylers),
      )
    end

    def self.empty_web_str?(str)
      return str.nil? || strip_web_str(str).empty?
    end

    def self.escape_html(str)
      str = CGI.escapeHTML(str)
      str = str.gsub("\n",'<br>')

      return str
    end

    def self.filename_str?(str)
      # Do not use "!dir_str?()"! It's not the same meaning!
      return !str.match?(%r{[/\\]})
    end

    def self.hiragana?(str)
      return HIRAGANA_REGEX =~ str
    end

    # This doesn't modify the hour/minute according to {JST_OFFSET},
    # but instead, it just drops {JST_OFFSET} into it without adjusting it.
    def self.jst_time(time)
      return Time.new(time.year,time.month,time.day,time.hour,time.min,time.sec,JST_OFFSET)
    end

    def self.kana?(str)
      return KANA_REGEX =~ str
    end

    def self.kanji?(str)
      return KANJI_REGEX =~ str
    end

    def self.katakana?(str)
      return KATAKANA_REGEX =~ str
    end

    def self.load_yaml(data,file: nil,**kargs)
      require 'psychgus'

      return Psych.safe_load(
        data,
        aliases: false,
        filename: file,
        # freeze: true, # Not in this current version of Psych
        permitted_classes: [Symbol],
        symbolize_names: true,
        **kargs,
      )
    end

    def self.normalize_str(str)
      return str.gsub(NORMALIZE_STR_REGEX,'')
    end

    def self.reduce_jpn_space(str)
      # Do not strip; use a Japanese space
      return str.gsub(WEB_SPACES_REGEX,JPN_SPACE)
    end

    def self.reduce_space(str)
      return str.gsub(WEB_SPACES_REGEX,' ')
    end

    def self.replace_uri_query!(uri,**new_query)
      return uri if new_query.empty?

      query = uri.query
      query = query.nil? ? [] : URI.decode_www_form(query)

      # First, remove the old ones.
      if !query.empty?
        new_query_keys = Set.new(new_query.keys.map do |key|
          unspace_web_str(key.to_s).downcase
        end)

        query.filter! do |q|
          if q.nil? || q.empty?
            false
          else
            key = unspace_web_str(q[0].to_s).downcase

            !new_query_keys.include?(key)
          end
        end
      end

      # Next, add the new ones.
      new_query.each do |key,value|
        query << [key,value.nil? ? '' : value]
      end

      uri.query = URI.encode_www_form(query)

      return uri
    end

    def self.sane_year?(year)
      return year.between?(MIN_SANE_YEAR,MAX_SANE_YEAR)
    end

    # String's normal strip() method doesn't work with special Unicode/HTML white space.
    def self.strip_web_str(str)
      # After testing with Benchmark, this is slower than one regex.
      # str = str.gsub(/\A[[:space:]]+/,'')
      # str = str.gsub(/[[:space:]]+\z/,'')

      str = str.gsub(STRIP_WEB_STR_REGEX,'')

      return str
    end

    def self.unspace_web_str(str)
      return str.gsub(WEB_SPACES_REGEX,'')
    end

    def self.warn(msg,uplevel: 1)
      Kernel.warn(msg,uplevel: uplevel)
    end
  end
end
