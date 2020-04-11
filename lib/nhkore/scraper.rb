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


require 'http-cookie'
require 'nokogiri'
require 'open-uri'
require 'rss'
require 'user_agent_randomizer'

require 'nhkore/util'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class Scraper
    DEFAULT_HEADER = {
      'user-agent' => UserAgentRandomizer::UserAgent.fetch(type: 'desktop_browser').string,
      'accept' => 'text/html,application/xhtml+xml,application/xml,application/rss+xml,text/xml;image/webp,image/apng,*/*;application/signed-exchange',
      'dnt' => '1',
    }
    
    attr_accessor :is_cookie
    attr_accessor :is_file
    attr_reader :kargs
    attr_accessor :max_redirects
    attr_accessor :max_retries
    attr_accessor :redirect_rule
    attr_accessor :str_or_io
    attr_accessor :url
    
    alias_method :is_cookie?,:is_cookie
    alias_method :is_file?,:is_file
    
    # +max_redirects+ defaults to 3 for safety (infinite-loop attack).
    # 
    # All URL options: https://ruby-doc.org/stdlib-2.7.0/libdoc/open-uri/rdoc/OpenURI/OpenRead.html
    # 
    # Pass in +header: {}+ for the default HTTP header fields to be set.
    # 
    # @param is_cookie [true,false] true to set the HTTP header field 'cookie', which can be an expensive
    #                  (time-consuming) operation since it opens the URL again, but necessary for some URLs.
    # @param redirect_rule [nil,:lenient,:strict]
    def initialize(url,header: nil,is_cookie: false,is_file: false,max_redirects: 3,max_retries: 3,redirect_rule: :strict,str_or_io: nil,**kargs)
      super()
      
      if !header.nil?() && !is_file
        # Some sites (Search Engines) hate scrapers, so need HTTP header fields.
        # If this isn't enough, look at googler for more header fields to set:
        # - https://github.com/jarun/googler
        # If necessary, can use Faraday, HTTParty, or RestClient gem and
        #   pass in to str_or_io.
        
        header = DEFAULT_HEADER.merge(header)
        kargs.merge!(header)
      end
      
      @is_cookie = is_cookie
      @is_file = is_file
      @kargs = kargs
      @max_redirects = max_redirects
      @max_retries = max_retries
      @redirect_rule = redirect_rule
      
      open(url,str_or_io)
    end
    
    def fetch_cookie(url)
      open_url(url)
      
      cookies = Array(@str_or_io.meta['set-cookie']) # nil will be []
      
      if !cookies.empty?()
        jar = HTTP::CookieJar.new()
        uri = URI(url)
        
        cookies.each() do |cookie|
          jar.parse(cookie,uri)
        end
        
        @kargs['cookie'] = HTTP::Cookie.cookie_value(jar.cookies(uri))
      end
      
      return self
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
    
    def open(url,str_or_io=nil)
      @str_or_io = str_or_io
      @url = url
      
      if str_or_io.nil?()
        if @is_file
          # NHK's website tends to always use UTF-8.
          @str_or_io = File.open(url,'rt:UTF-8',**@kargs)
        else
          fetch_cookie(url) if @is_cookie
          open_url(url)
        end
      end
      
      return self
    end
    
    def open_url(url)
      max_redirects = (@max_redirects.nil?() || @max_redirects < 0) ? 10_000 : @max_redirects
      max_retries = (@max_retries.nil?() || @max_retries < 0) ? 10_000 : @max_retries
      
      top_uri = URI(url)
      top_domain = Util.domain(top_uri.host)
      
      begin
        # Use URI.open() instead of (Kernel.)open() for safety (code-injection attack).
        @str_or_io = URI.open(url,redirect: false,**@kargs)
        @url = url
      rescue OpenURI::HTTPRedirect => redirect
        redirect_uri = redirect.uri
        
        if (max_redirects -= 1) < 0
          raise redirect.exception("redirected to URL[#{redirect_uri}]: #{redirect}")
        end
        
        case @redirect_rule
        when :lenient,:strict
          if redirect_uri.scheme != top_uri.scheme
            raise redirect.exception("redirect scheme[#{redirect_uri.scheme}] does not match original " +
              "scheme[#{top_uri.scheme}] at redirect URL[#{redirect_uri}]: #{redirect}")
          end
          
          if @redirect_rule == :strict
            redirect_domain = Util.domain(redirect_uri.host)
            
            if redirect_domain != top_domain
              raise redirect.exception("redirect domain[#{redirect_domain}] does not match original " +
                "domain[#{top_domain}] at redirect URL[#{redirect_uri}]: #{redirect}")
            end
          end
        end
        
        url = redirect_uri
        
        retry
      # Must come after HTTPRedirect since a subclass of HTTPError.
      rescue OpenURI::HTTPError => e
        raise e.exception("HTTP error[#{e.to_s()}] at URL[#{url}]")
      rescue SocketError => e
        if (max_retries -= 1) < 0
          raise e.exception("Socket error[#{e.to_s()}] at URL[#{url}]")
        end
        
        retry
      end
      
      return self
    end
    
    def read()
      @str_or_io = @str_or_io.read() if @str_or_io.respond_to?(:read)
      
      return @str_or_io
    end
    
    def rss_doc()
      return RSS::Parser.parse(@str_or_io,validate: false)
    end
  end
end
