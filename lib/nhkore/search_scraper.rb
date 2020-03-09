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


require 'nhkore/error'
require 'nhkore/scraper'
require 'nhkore/search_link'
require 'nhkore/util'
require 'nokogiri'
require 'uri'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class SearchScraper < Scraper
    FUTSUU_SITE = 'nhk.or.jp/news/html/'
    YASASHII_SITE = 'nhk.or.jp/news/easy/'
    
    # https://www3.nhk.or.jp/news/html/20200220/k10012294001000.html
    FUTSUU_REGEX = /#{Regexp.quote(FUTSUU_SITE)}.+\/k.+\.html?/i
    # https://www3.nhk.or.jp/news/easy/k10012294001000/k10012294001000.html
    YASASHII_REGEX = /#{Regexp.quote(YASASHII_SITE)}k.+\/k.+\.html?/i
    
    # Pass in +header: {}+ to trigger using the default HTTP header fields.
    def initialize(url,header: {},**kargs)
      super(url,header: header,**kargs)
    end
  end
  
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class BingScraper < SearchScraper
    attr_reader :regex
    attr_reader :site
    
    def initialize(site,regex: nil,url: nil,**kargs)
      case site
      when :futsuu
        regex = FUTSUU_REGEX if regex.nil?()
        site = FUTSUU_SITE
      when :yasashii
        regex = YASASHII_REGEX if regex.nil?()
        site = YASASHII_SITE
      else
        site = Util.strip_web_str(site.to_s())
        regex = /#{Regexp.quote(site)}/ if regex.nil?()
      end
      
      raise ArgError,"empty regex[#{regex}]" if regex.nil?()
      raise ArgError,"empty site[#{site}]" if site.empty?()
      
      @regex = regex
      @site = site
      url = self.class.build_url(site,**kargs) if url.nil?()
      
      super(url,**kargs)
    end
    
    def self.build_url(site,count: 100,**kargs)
      url = ''.dup()
      
      url << 'https://www.bing.com/search?'
      url << URI.encode_www_form(
        q: "site:#{site}",
        count: count
      )
      
      return url
    end
    
    # TODO: probably don't call it 'first' but 'from_count' or something
    def scrape(links,first)
      doc = html_doc()
      
      next_first = -1
      next_page = nil
      
      # FIXME: check if < 0 && nil/empty, etc.
      doc.css('a').each() do |anchor|
        href = anchor['href'].to_s()
        href = Util.unspace_web_str(href)
        
        next if href.empty?()
        
        href = href.downcase()
        
        if (md = href.match(/first\=(\d+)/))
          i = md[1].to_i()
          
          if i > first && (next_first == -1 || i < next_first)
            next_first = i
            next_page = href
          end
        end
        
        next unless href =~ regex
        
        puts href
      end
      
      # TODO: make this a class?
      return [next_page,next_first]
    end
  end
end
