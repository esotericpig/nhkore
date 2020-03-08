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


require 'nhkore/scraper'
require 'nhkore/search_link'
require 'nokogiri'
require 'uri'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class SearchScraper < Scraper
    YASASHII_SITE = 'nhk.or.jp/news/easy/'
    
    def initialize(url,**kargs)
      super(url,**kargs)
    end
  end
  
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class BingScraper < SearchScraper
    def initialize(url,**kargs)
      super(url,**kargs)
    end
    
    def self.build_url(site,count: 100)
      url = ''.dup()
      
      url << 'https://www.bing.com/search?'
      url << URI.encode_www_form(
        q: "site:#{site}",
        count: count
      )
      
      return url
    end
    
    def self.build_yasashii_url(**kargs)
      return build_url(YASASHII_SITE,**kargs)
    end
    
    # TODO: need to do all pages by grabbing page 1,2,3,... from bottom
    # TODO: add user-agent, etc.
    def scrape()
      doc = html_doc()
      links = SearchLinks.new()
      
      # FIXME: check if < 0 && nil/empty
      # FIXME: choose yasashii/futsuu
      doc.css('a').each() do |anchor|
        href = anchor['href'].to_s().downcase()
        
        next unless href.include?(YASASHII_SITE)
        
        puts href
      end
    end
  end
end
