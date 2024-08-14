# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++


require 'nhkore/article'
require 'nhkore/fileable'
require 'nhkore/util'


module NHKore
  class Sifter
    include Fileable

    DEFAULT_DIR = Util::CORE_DIR

    DEFAULT_FUTSUU_FILENAME = 'sift_nhk_news_web_regular'
    DEFAULT_YASASHII_FILENAME = 'sift_nhk_news_web_easy'

    def self.build_file(filename)
      return File.join(DEFAULT_DIR,filename)
    end

    DEFAULT_FUTSUU_FILE = build_file(DEFAULT_FUTSUU_FILENAME)
    DEFAULT_YASASHII_FILE = build_file(DEFAULT_YASASHII_FILENAME)

    attr_accessor :articles
    attr_accessor :caption
    attr_accessor :filters
    attr_accessor :ignores
    attr_accessor :output

    def initialize(news)
      @articles = news.articles.values.dup
      @caption = nil
      @filters = {}
      @ignores = {}
      @output = nil
    end

    def build_header
      header = []

      header << 'Frequency' unless @ignores[:freq]
      header << 'Word' unless @ignores[:word]
      header << 'Kana' unless @ignores[:kana]
      header << 'English' unless @ignores[:eng]
      header << 'Definition' unless @ignores[:defn]

      return header
    end

    def build_rows(words)
      rows = []

      words.each do |word|
        rows << build_word_row(word)
      end

      return rows
    end

    def build_word_row(word)
      row = []

      row << word.freq unless @ignores[:freq]
      row << word.word unless @ignores[:word]
      row << word.kana unless @ignores[:kana]
      row << word.eng unless @ignores[:eng]
      row << word.defn unless @ignores[:defn]

      return row
    end

    def filter?(article)
      return false if @filters.empty?

      datetime_filter = @filters[:datetime]
      title_filter = @filters[:title]
      url_filter = @filters[:url]

      if !datetime_filter.nil?
        datetime = article.datetime

        return true if datetime.nil? ||
          datetime < datetime_filter[:from] || datetime > datetime_filter[:to]
      end

      if !title_filter.nil?
        title = article.title.to_s
        title = Util.unspace_web_str(title) if title_filter[:unspace]
        title = title.downcase if title_filter[:uncase]

        return true unless title.include?(title_filter[:filter])
      end

      if !url_filter.nil?
        url = article.url.to_s
        url = Util.unspace_web_str(url) if url_filter[:unspace]
        url = url.downcase if url_filter[:uncase]

        return true unless url.include?(url_filter[:filter])
      end

      return false
    end

    def filter_by_datetime(datetime_filter=nil,from: nil,to: nil)
      if !datetime_filter.nil?
        if datetime_filter.respond_to?(:[])
          # If out-of-bounds, just nil.
          from = datetime_filter[0] if from.nil?
          to = datetime_filter[1] if to.nil?
        else
          from = datetime_filter if from.nil?
          to = datetime_filter if to.nil?
        end
      end

      from = to if from.nil?
      to = from if to.nil?

      from = Util.jst_time(from) unless from.nil?
      to = Util.jst_time(to) unless to.nil?

      datetime_filter = [from,to]

      return self if datetime_filter.flatten.compact.empty?

      @filters[:datetime] = {from: from,to: to}

      return self
    end

    def filter_by_title(title_filter,uncase: true,unspace: true)
      title_filter = Util.unspace_web_str(title_filter) if unspace
      title_filter = title_filter.downcase if uncase

      @filters[:title] = {filter: title_filter,uncase: uncase,unspace: unspace}

      return self
    end

    def filter_by_url(url_filter,uncase: true,unspace: true)
      url_filter = Util.unspace_web_str(url_filter) if unspace
      url_filter = url_filter.downcase if uncase

      @filters[:url] = {filter: url_filter,uncase: uncase,unspace: unspace}

      return self
    end

    def ignore(key)
      @ignores[key] = true

      return self
    end

    # This does not output {caption}.
    def put_csv!
      require 'csv'

      words = sift

      @output = CSV.generate(headers: :first_row,write_headers: true) do |csv|
        csv << build_header

        words.each do |word|
          csv << build_word_row(word)
        end
      end

      return @output
    end

    def put_html!
      words = sift

      @output = ''.dup

      @output << <<~HTML
        <!DOCTYPE html>
        <html lang="ja">
        <head>
        <meta charset="utf-8">
        <title>NHKore</title>
        <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Noto+Serif+JP&amp;display=fallback">
        <style>
        body {
          background-color: #FCFBF9;
          color: #333333;
          font-family: 'Noto Serif JP',Verdana,sans-serif;
        }
        h1 {
          color: #737373;
        }
        table {
          border-collapse: collapse;
          table-layout: fixed;
          width: 100%;
        }
        tr:nth-child(even) {
          background-color: #A5C7ED;
        }
        tr:hover {
          background-color: #FFDDCA;
        }
        td,th {
          border: 1px solid #333333;
          padding: 8px;
          text-align: left;
        }
        th {
          background-color: #082A8E;
          color: #FCFBF9;
        }
        td {
          vertical-align: top;
        }
        td:nth-child(1) {
          padding-right: 1em;
          text-align: right;
        }
        </style>
        </head>
        <body>
        <h1>NHKore</h1>
        <h2>#{@caption}</h2>
        <table>
      HTML

      # If have too few or too many '<col>', invalid HTML.
      @output << %Q(<col style="width:6em;">\n) unless @ignores[:freq]
      @output << %Q(<col style="width:17em;">\n) unless @ignores[:word]
      @output << %Q(<col style="width:17em;">\n) unless @ignores[:kana]
      @output << %Q(<col style="width:5em;">\n) unless @ignores[:eng]
      @output << "<col>\n" unless @ignores[:defn] # No width for defn, fills rest of page

      @output << '<tr>'

      build_header.each do |h|
        @output << "<th>#{h}</th>"
      end

      @output << "</tr>\n"

      words.each do |word|
        @output << '<tr>'

        build_word_row(word).each do |w|
          @output << "<td>#{Util.escape_html(w.to_s)}</td>"
        end

        @output << "</tr>\n"
      end

      @output << <<~HTML
        </table>
        </body>
        </html>
      HTML

      return @output
    end

    def put_json!
      require 'json'

      words = sift

      @output = ''.dup

      @output << <<~JSON
        {
        "caption": #{JSON.generate(@caption)},
        "header": #{JSON.generate(build_header)},
        "words": [
      JSON

      if !words.empty?
        0.upto(words.length - 2) do |i|
          @output << "  #{JSON.generate(build_word_row(words[i]))},\n"
        end

        @output << "  #{JSON.generate(build_word_row(words[-1]))}\n"
      end

      @output << "]\n}\n"

      return @output
    end

    def put_yaml!
      require 'psychgus'

      words = sift

      yaml = {
        caption: @caption,
        header: build_header,
        words: build_rows(words),
      }

      header_styler = Class.new do
        include Psychgus::Styler

        def style_sequence(sniffer,node)
          parent = sniffer.parent

          if !parent.nil? && parent.node.respond_to?(:value) && parent.value == 'header'
            node.style = Psychgus::SEQUENCE_FLOW
          end
        end
      end

      # Put each Word on one line (flow/inline style).
      @output = Util.dump_yaml(yaml,flow_level: 4,stylers: header_styler.new)

      return @output
    end

    def sift
      master_article = Article.new

      @articles.each do |article|
        next if filter?(article)

        article.words.each_value do |word|
          # TODO: Try to remove garbage data better.
          next if word.word.length < 2
          next if word.freq <= 1
          next if word.word =~ /\p{Latin}|[[:digit:]]/

          master_article.add_word(word,use_freq: true)
        end
      end

      words = master_article.words.values

      words.sort! do |word1,word2|
        # Order by freq DESC (most frequent words to top).
        i = (word2.freq <=> word1.freq)

        # Order by !defn.empty, word ASC, !kana.empty, kana ASC, defn.len DESC, defn ASC.
        i = compare_empty_str(word1.defn,word2.defn) if i == 0 # Favor words that have definitions
        i = (word1.word.to_s <=> word2.word.to_s) if i == 0
        i = compare_empty_str(word1.kana,word2.kana) if i == 0 # Favor words that have kana
        i = (word1.kana.to_s <=> word2.kana.to_s) if i == 0
        i = (word2.defn.to_s.length <=> word1.defn.to_s.length) if i == 0 # Favor longer definitions
        i = (word1.defn.to_s <=> word2.defn.to_s) if i == 0

        i
      end

      return words
    end

    def compare_empty_str(str1,str2)
      has_str1 = !Util.empty_web_str?(str1)
      has_str2 = !Util.empty_web_str?(str2)

      if has_str1 && !has_str2
        return -1 # Bubble word1 to top
      elsif !has_str1 && has_str2
        return 1 # Bubble word2 to top
      end

      return 0 # Further comparison needed
    end

    def to_s
      return @output.to_s
    end
  end
end
