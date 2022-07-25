# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020-2022 Jonathan Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++


require 'nhkore/dict'
require 'nhkore/error'
require 'nhkore/scraper'
require 'nhkore/util'


module NHKore
  ###
  # @author Jonathan Bradley Whited
  # @since  0.2.0
  ###
  class DictScraper < Scraper
    attr_accessor :missingno

    def initialize(url,missingno: nil,parse_url: true,**kargs)
      url = self.class.parse_url(url) if parse_url

      super(url,**kargs)

      @missingno = missingno
    end

    def self.parse_url(url,basename: nil)
      url = Util.strip_web_str(url.to_s)

      raise ParseError,"cannot parse dictionary URL from URL[#{url}]" if url.empty?

      i = url.rindex(%r{[/\\]}) # Can be a URL or a file
      i = i.nil? ? 0 : (i + 1) # If no match found, no path

      basename = File.basename(url[i..],'.*') if basename.nil?
      path = url[0...i]

      return "#{path}#{basename}.out.dic"
    end

    def scrape
      require 'json'

      str = read # Make sure it has all been read.
      str = str.string if str.respond_to?(:string) # For StringIO.

      json = JSON.parse(str)

      return Dict.new if json.nil?

      hash = json['reikai']

      return Dict.new if hash.nil?

      hash = hash['entries']

      return Dict.new if hash.nil?
      return Dict.scrape(hash,missingno: @missingno,url: @url)
    end
  end
end
