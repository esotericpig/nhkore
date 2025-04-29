# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020 Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++

require 'attr_bool'
require 'nokogiri'
require 'open-uri'
require 'ronin/web/user_agents'

require 'nhkore/error'
require 'nhkore/util'

module NHKore
  class Scraper
    extend AttrBool::Ext

    DEFAULT_HEADER = {
      # See for better ones:
      # - https://www.useragentstring.com/pages/Chrome/
      'user-agent' => Ronin::Web::UserAgents.random,

      'accept' => 'text/html,application/xhtml+xml,application/xml,application/rss+xml,text/xml;' \
                  'q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'accept-language' => 'en;q=0.9,ja-JP;q=0.8,ja',
      'cache-control' => 'max-age=0',
      'dnt' => '1',
      'ect' => '4g',
      'priority' => 'u=0, i',
      'upgrade-insecure-requests' => '1',
    }.freeze

    attr_accessor? :eat_cookie
    attr_accessor? :is_file
    attr_reader :kargs
    attr_accessor :max_redirects
    attr_accessor :max_retries
    attr_accessor :redirect_rule
    attr_accessor :str_or_io
    attr_accessor :url

    # +max_redirects+ defaults to 3 for safety (infinite-loop attack).
    #
    # All URL options: https://ruby-doc.org/stdlib-2.7.0/libdoc/open-uri/rdoc/OpenURI/OpenRead.html
    #
    # Pass in +header: {}+ for the default HTTP header fields to be set.
    #
    # @param eat_cookie [true,false] true to set the HTTP header field 'cookie', which can be an expensive
    #                   (time-consuming) operation since it opens the URL again, but necessary for some URLs.
    # @param redirect_rule [nil,:lenient,:strict]
    def initialize(url,eat_cookie: false,header: nil,is_file: false,max_redirects: 3,max_retries: 3,
                   redirect_rule: :strict,str_or_io: nil,**kargs)
      super()

      if !header.nil? && !is_file
        # Some sites (Search Engines) hate scrapers, so need HTTP header fields.
        # If this isn't enough, look at googler for more header fields to set:
        # - https://github.com/jarun/googler
        # If necessary, can use Faraday, HTTParty, or RestClient gem and
        #   pass in to str_or_io.

        header = DEFAULT_HEADER.merge(header)
        kargs.merge!(header)
      end

      @eat_cookie = eat_cookie
      @is_file = is_file
      @kargs = kargs
      @max_redirects = max_redirects
      @max_retries = max_retries
      @redirect_rule = redirect_rule

      self.open(url,str_or_io,is_file: is_file)
    end

    def fetch_cookie(url)
      require 'http-cookie'

      open_url(url)

      cookies = Array(@str_or_io.meta['set-cookie']) # nil will be []

      if !cookies.empty?
        jar = HTTP::CookieJar.new
        uri = URI(url)

        cookies.each do |cookie|
          jar.parse(cookie,uri)
        end

        @kargs['cookie'] = HTTP::Cookie.cookie_value(jar.cookies(uri))
      end

      return self
    end

    def html_doc
      return Nokogiri::HTML(@str_or_io)
    end

    def join_url(relative_url)
      # For a file, don't know what to do.
      # It would be unsafe to return something else;
      #   for example, it could return a lot of "../../../" to your root dir.
      return nil if @is_file

      return URI.join(@url,relative_url)
    end

    def open(url,str_or_io = nil,is_file: @is_file)
      @is_file = is_file
      @str_or_io = str_or_io
      @url = url

      if str_or_io.nil?
        if @is_file
          open_file(url)
        else
          fetch_cookie(url) if @eat_cookie
          open_url(url)
        end
      end

      return self
    end

    def open_file(file)
      @is_file = true
      @url = file

      # NHK's website tends to always use UTF-8.
      @str_or_io = File.open(file,'rt:UTF-8',**@kargs)

      return self
    end

    def open_url(url)
      max_redirects = (@max_redirects.nil? || @max_redirects < 0) ? 10_000 : @max_redirects
      max_retries = (@max_retries.nil? || @max_retries < 0) ? 10_000 : @max_retries

      top_uri = URI(url)
      top_domain = Util.domain(top_uri.host)

      begin
        # Use URI().open() instead of URI.open()/(Kernel.)open() for safety (code-injection attack).
        # Use URI() instead of URI.parse() because url can be a URI (not just a string).
        @str_or_io = URI(url).open(redirect: false,**@kargs)
        @url = url
      rescue OpenURI::HTTPRedirect => redirect
        redirect_uri = redirect.uri

        if (max_redirects -= 1) < 0
          raise redirect.exception("redirected to URL[#{redirect_uri}]: #{redirect}")
        end

        case @redirect_rule
        when :lenient,:strict
          if redirect_uri.scheme != top_uri.scheme
            raise redirect.exception(
              "redirect scheme[#{redirect_uri.scheme}] does not match original " \
              "scheme[#{top_uri.scheme}] at redirect URL[#{redirect_uri}]: #{redirect}"
            )
          end

          if @redirect_rule == :strict
            redirect_domain = Util.domain(redirect_uri.host)

            if redirect_domain != top_domain
              raise redirect.exception(
                "redirect domain[#{redirect_domain}] does not match original " \
                "domain[#{top_domain}] at redirect URL[#{redirect_uri}]: #{redirect}"
              )
            end
          end
        end

        url = redirect_uri

        retry
      # Must come after HTTPRedirect since a subclass of HTTPError.
      rescue OpenURI::HTTPError => e
        msg = "HTTP error[#{e}] at URL[#{url}]"

        if e.to_s.include?('404 Not Found')
          raise Http404Error,msg
        else
          raise e.exception(msg)
        end
      rescue SocketError => e
        if (max_retries -= 1) < 0
          raise e.exception("Socket error[#{e}] at URL[#{url}]")
        end

        retry
      end

      return self
    end

    def read
      @str_or_io = @str_or_io.read if @str_or_io.respond_to?(:read)

      return @str_or_io
    end

    def reopen
      return self.open(@url)
    end

    def rss_doc
      require 'rss'

      return RSS::Parser.parse(@str_or_io,validate: false)
    end
  end
end
