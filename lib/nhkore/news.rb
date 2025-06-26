# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020 Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++

require 'nhkore/article'
require 'nhkore/error'
require 'nhkore/fileable'
require 'nhkore/util'

module NHKore
  class News
    include Fileable

    DEFAULT_DIR = Util::CORE_DIR
    FAVORED_URL = /https:/i

    attr_reader :articles
    attr_reader :sha256s

    def initialize
      super

      @articles = {}
      @sha256s = {}
    end

    def add_article(article,key: nil,overwrite: false)
      url = article.url
      url = url.to_s unless url.nil?

      key = key.nil? ? url : key.to_s

      if !overwrite
        raise ArgumentError,"duplicate article[#{key}] in articles" if @articles.key?(key)
        raise ArgumentError,"duplicate sha256[#{article.sha256}] in articles" if @sha256s.key?(article.sha256)
      end

      @articles[key] = article
      @sha256s[article.sha256] = url

      return self
    end

    def self.build_file(filename)
      return File.join(DEFAULT_DIR,filename)
    end

    def encode_with(coder)
      # Order matters.
      # Don't output @sha256s.

      coder[:articles] = @articles
    end

    def self.load_data(data,article_class: Article,file: nil,news_class: News,overwrite: false,**_kargs)
      data = Util.load_yaml(data,file: file)

      articles = data[:articles]

      news = news_class.new

      articles&.each do |key,hash|
        key = key.to_s # Change from a symbol
        news.add_article(article_class.load_data(key,hash),key: key,overwrite: overwrite)
      end

      return news
    end

    def update_article(article,url)
      url = url.to_s unless url.nil?

      # Favor https.
      return if FAVORED_URL.match?(article.url.to_s)
      return unless FAVORED_URL.match?(url)

      @articles.delete(article.url) # Probably no to_s() here
      @articles[url] = article
      article.url = url
    end

    def article(key)
      key = key.to_s unless key.nil?

      return @articles[key]
    end

    def article_with_sha256(sha256)
      article = nil

      @articles.each_value do |a|
        if a.sha256 == sha256
          article = a
          break
        end
      end

      return article
    end

    def article?(key)
      key = key.to_s unless key.nil?

      return @articles.key?(key)
    end

    def sha256?(sha256)
      return @sha256s.key?(sha256)
    end

    def to_s
      # Put each Word on one line (flow/inline style).
      return Util.dump_yaml(self,flow_level: 8)
    end
  end

  class FutsuuNews < News
    DEFAULT_FILENAME = 'nhk_news_web_regular.yml'
    DEFAULT_FILE = build_file(DEFAULT_FILENAME)

    def self.load_data(data,**kargs)
      return News.load_data(data,article_class: Article,news_class: FutsuuNews,**kargs)
    end

    def self.load_file(file = DEFAULT_FILE,**kargs)
      return News.load_file(file,article_class: Article,news_class: FutsuuNews,**kargs)
    end

    def save_file(file = DEFAULT_FILE,**kargs)
      super
    end
  end

  class YasashiiNews < News
    DEFAULT_FILENAME = 'nhk_news_web_easy.yml'
    DEFAULT_FILE = build_file(DEFAULT_FILENAME)

    def self.load_data(data,**kargs)
      return News.load_data(data,article_class: Article,news_class: YasashiiNews,**kargs)
    end

    def self.load_file(file = DEFAULT_FILE,**kargs)
      return News.load_file(file,article_class: Article,news_class: YasashiiNews,**kargs)
    end

    def save_file(file = DEFAULT_FILE,**kargs)
      super
    end
  end
end
