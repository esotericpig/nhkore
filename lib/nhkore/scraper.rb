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


require 'nokogiri'
require 'open-uri'

require 'nhkore/util'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class Scraper
    # Copied from googler (https://github.com/jarun/googler).
    USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36'
    
    attr_accessor :is_file
    attr_accessor :str_or_io
    attr_accessor :url
    
    alias_method :is_file?,:is_file
    
    # +max_redirects+ defaults to 3 for safety (infinite-loop attack).
    # 
    # All URL options: https://ruby-doc.org/stdlib-2.7.0/libdoc/open-uri/rdoc/OpenURI/OpenRead.html
    # 
    # Pass in +header: {}+ for the default HTTP header fields to be set.
    # 
    # @param redirect_rule [nil,:lenient,:strict]
    def initialize(url,header: nil,is_file: false,max_redirects: 3,max_retries: 3,redirect_rule: :strict,str_or_io: nil,**kargs)
      super()
      
      @is_file = is_file
      @url = url
      
      if !header.nil?() && !is_file
        # Some sites (Search Engines) hate scrapers, so need HTTP header fields.
        # If this isn't enough, look at googler for more header fields to set:
        # - https://github.com/jarun/googler
        # If necessary, can use Faraday, HTTParty, or RestClient gem and
        #   pass in to str_or_io.
        
        header['User-Agent'] = USER_AGENT unless header.key?('User-Agent')
        
        kargs.merge!(header) # header will overwrite duplicate kargs entries
      end
      
      if str_or_io.nil?()
        if is_file
          # NHK's website tends to always use UTF-8.
          @str_or_io = File.open(url,'rt:UTF-8',**kargs)
        else
          max_redirects = 10000 if max_redirects.nil?() || max_redirects < 0
          
          top_uri = URI(url)
          top_domain = Util.domain(top_uri.host)
          
          begin
            # Use URI.open() instead of (Kernel.)open() for safety (code-injection attack).
            @str_or_io = URI.open(url,redirect: false,**kargs)
            @url = url
          rescue OpenURI::HTTPRedirect => redirect
            redirect_uri = redirect.uri
            
            if (max_redirects -= 1) < 0
              raise redirect.exception("redirected to URL[#{redirect_uri}]: #{redirect}")
            end
            
            case redirect_rule
            when :lenient,:strict
              if redirect_uri.scheme != top_uri.scheme
                raise redirect.exception("redirect scheme[#{redirect_uri.scheme}] does not match original " +
                  "scheme[#{top_uri.scheme}] at redirect URL[#{redirect_uri}]: #{redirect}")
              end
              
              if redirect_rule == :strict
                redirect_domain = Util.domain(redirect_uri.host)
                
                if redirect_domain != top_domain
                  raise redirect.exception("redirect domain[#{redirect_domain}] does not match original " +
                    "domain[#{top_domain}] at redirect URL[#{redirect_uri}]: #{redirect}")
                end
              end
            end
            
            url = redirect_uri
            
            retry
          rescue SocketError
            raise if max_retries.nil?() || (max_retries -= 1) < 0
            
            retry
          end
        end
      else
        @str_or_io = str_or_io
      end
    end
    
    def html_doc()
      return Nokogiri::HTML(@str_or_io)
    end
    
    def join_url(relative_url)
      # For a file, don't know what to do.
      # It would be unsafe to return something else;
      #   for example, it could return a lot of "../../../" to your root dir.
      return nil if @is_file
      
      return URI::join(@url,relative_url)
    end
  end
end
