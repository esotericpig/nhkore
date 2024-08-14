# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++


require 'attr_bool'
require 'time'

require 'nhkore/fileable'
require 'nhkore/util'


module NHKore
  class SearchLink
    extend AttrBool::Ext

    attr_reader :datetime
    attr_reader :futsuurl
    attr_accessor? :scraped
    attr_accessor :sha256
    attr_accessor :title
    attr_reader :url

    def initialize(url,scraped: false)
      super()

      @datetime = nil
      @futsuurl = nil
      @scraped = scraped
      @sha256 = sha256
      @title = nil
      self.url = url
    end

    def encode_with(coder)
      # Order matters.

      coder[:url] = @url.nil? ? nil : @url.to_s
      coder[:scraped] = @scraped
      coder[:datetime] = @datetime.nil? ? nil : @datetime.iso8601
      coder[:title] = @title
      coder[:futsuurl] = @futsuurl.nil? ? nil : @futsuurl.to_s
      coder[:sha256] = @sha256
    end

    def self.load_data(key,hash)
      slink = SearchLink.new(
        hash[:url],
        scraped: hash[:scraped],
      )

      slink.datetime = hash[:datetime]
      slink.futsuurl = hash[:futsuurl]
      slink.sha256 = hash[:sha256]
      slink.title = hash[:title]

      return slink
    end

    def update_from_article(article)
      # Don't update the url, as it may be different (e.g., http vs https).

      self.datetime = article.datetime if @datetime.nil?
      self.futsuurl = article.futsuurl if Util.empty_web_str?(@futsuurl)
      @scraped = true # If we have an article, it's been scraped
      @sha256 = article.sha256 if Util.empty_web_str?(@sha256)
      @title = article.title if Util.empty_web_str?(@title)
    end

    def datetime=(value)
      if value.is_a?(Time)
        @datetime = value
      else
        @datetime = Util.empty_web_str?(value) ? nil : Time.iso8601(value)
      end
    end

    def futsuurl=(value)
      # Don't store URI, store String.
      @futsuurl = value.nil? ? nil : value.to_s
    end

    def url=(value)
      # Don't store URI, store String.
      @url = value.nil? ? nil : value.to_s
    end

    def to_s(mini: false)
      s = ''.dup

      s << "'#{@url}': "

      if mini
        s << "{ scraped? #{@scraped ? 'yes' : 'NO'} }"
      else
        s << "\n  scraped?  #{@scraped ? 'yes' : 'NO'}"
        s << "\n  datetime: '#{@datetime}'"
        s << "\n  title:    '#{@title}'"
        s << "\n  futsuurl: '#{@futsuurl}'"
        s << "\n  sha256:   '#{@sha256}'"
      end

      return s
    end
  end

  class SearchLinks
    include Fileable

    DEFAULT_DIR = Util::CORE_DIR

    DEFAULT_FUTSUU_FILENAME = 'links_nhk_news_web_regular.yml'
    DEFAULT_YASASHII_FILENAME = 'links_nhk_news_web_easy.yml'

    def self.build_file(filename)
      return File.join(DEFAULT_DIR,filename)
    end

    DEFAULT_FUTSUU_FILE = build_file(DEFAULT_FUTSUU_FILENAME)
    DEFAULT_YASASHII_FILE = build_file(DEFAULT_YASASHII_FILENAME)

    attr_reader :links

    def initialize
      super()

      @links = {}
    end

    def add_link(link)
      url = link.url.nil? ? nil : link.url.to_s

      return self if @links.key?(url)

      @links[url] = link

      return self
    end

    def each(&block)
      return @links.each(&block)
    end

    def encode_with(coder)
      # Order matters.

      coder[:links] = @links
    end

    def self.load_data(data,file: nil,**kargs)
      data = Util.load_yaml(data,file: file)

      links = data[:links]

      slinks = SearchLinks.new

      links&.each() do |key,hash|
        key = key.to_s unless key.nil?
        slinks.links[key] = SearchLink.load_data(key,hash)
      end

      return slinks
    end

    def [](url)
      url = url.url if url.respond_to?(:url)
      url = url.to_s unless url.nil?

      return @links[url]
    end

    def length
      return @links.length
    end

    def to_s
      return Util.dump_yaml(self)
    end
  end
end
