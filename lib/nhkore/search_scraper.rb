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


require 'uri'

require 'nhkore/error'
require 'nhkore/scraper'
require 'nhkore/search_link'
require 'nhkore/util'


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class SearchScraper < Scraper
    DEFAULT_RESULT_COUNT = 100
    FUTSUU_SITE = 'nhk.or.jp/news/html/'
    YASASHII_SITE = 'nhk.or.jp/news/easy/'

    # https://www3.nhk.or.jp/news/html/20200220/k10012294001000.html
    FUTSUU_REGEX = /\A[^.]+\.#{Regexp.quote(FUTSUU_SITE)}.+\.html?/i.freeze()
    # https://www3.nhk.or.jp/news/easy/k10012294001000/k10012294001000.html
    # - https://www3.nhk.or.jp/news/easy/article/disaster_heat.html
    YASASHII_REGEX = /\A[^.]+\.#{Regexp.quote(YASASHII_SITE)}.+\.html?/i.freeze()

    IGNORE_LINK_REGEX = %r{
      /about\.html?             # https://www3.nhk.or.jp/news/easy/about.html
      |/movieplayer\.html?      # https://www3.nhk.or.jp/news/easy/movieplayer.html?id=k10038422811_1207251719_1207251728.mp4&teacuprbbs=4feb73432045dbb97c283d64d459f7cf
      |/audio\.html?            # https://www3.nhk.or.jp/news/easy/player/audio.html?id=k10011555691000
      |/news/easy/index\.html?  # http://www3.nhk.or.jp/news/easy/index.html

      # https://cgi2.nhk.or.jp/news/easy/easy_enq/bin/form/enqform.html?id=k10011916321000&title=日本の会社が作った鉄道の車両「あずま」がイギリスで走る
      # https://www3.nhk.or.jp/news/easy/easy_enq/bin/form/enqform.html?id=k10012689671000&title=「鬼滅の刃」の映画が台湾でも始まって大勢の人が見に行く
      |/enqform\.html?
    }x.freeze()

    # Search Engines are strict, so trigger using the default HTTP header fields
    # with +header: {}+ and fetch/set the cookie using +eat_cookie: true+.
    def initialize(url,eat_cookie: true,header: {},**kargs)
      super(url,eat_cookie: eat_cookie,header: header,**kargs)
    end

    def ignore_link?(link,cleaned: true)
      return true if link.nil?()

      link = Util.unspace_web_str(link).downcase() unless cleaned

      return true if link.empty?()

      return true if IGNORE_LINK_REGEX.match?(link)

      return false
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
        raise ArgumentError,"invalid site[#{site}]"
      end

      raise ArgumentError,"empty regex[#{regex}]" if regex.nil?()

      @regex = regex
      @site = site
      url = self.class.build_url(site,**kargs) if url.nil?()

      # Delete class-specific args (don't pass to Open-URI).
      kargs.delete(:count)

      super(url,**kargs)
    end

    def self.build_url(site,count: DEFAULT_RESULT_COUNT,**kargs)
      url = ''.dup()

      url << 'https://www.bing.com/search?'
      url << URI.encode_www_form(
        q: "site:#{site}",
        count: count
      )

      return url
    end

    def scrape(slinks,page=NextPage.new())
      next_page,link_count = scrape_html(slinks,page)

      if link_count <= 0
        scrape_rss(slinks,page,next_page)
      end

      return next_page
    end

    def scrape_html(slinks,page,next_page=NextPage.new())
      doc = html_doc()
      link_count = 0

      anchors = doc.css('a')

      anchors.each() do |anchor|
        href = anchor['href'].to_s()
        href = Util.unspace_web_str(href).downcase()

        next if ignore_link?(href)

        if (md = href.match(/first=(\d+)/))
          count = md[1].to_i()

          if count > page.count && (next_page.count < 0 || count < next_page.count)
            next_page.count = count
            next_page.url = join_url(href)
          end
        elsif href =~ regex
          slinks.add_link(SearchLink.new(href))

          link_count += 1
        end
      end

      return [next_page,link_count]
    end

    def scrape_rss(slinks,page,next_page=NextPage.new())
      link_count = 0

      if !@is_file
        uri = URI(@url)

        Util.replace_uri_query!(uri,format: 'rss')
        self.open(uri)

        doc = rss_doc()
        rss_links = []

        doc.items.each() do |item|
          link = item.link.to_s()
          link = Util.unspace_web_str(link).downcase()

          rss_links << link

          next if ignore_link?(link)
          next if link !~ regex

          slinks.add_link(SearchLink.new(link))

          link_count += 1
        end

        # For RSS, Bing will keep returning the same links over and over
        # if it's the last page or the "first=" query is the wrong count.
        # Therefore, we have to test the previous RSS links (+page.rss_links+).
        if next_page.empty?() && doc.items.length >= 1 && page.rss_links != rss_links
          next_page.count = (page.count < 0) ? 0 : page.count
          next_page.count += doc.items.length
          next_page.rss_links = rss_links

          uri = URI(page.url.nil?() ? @url : page.url)

          Util.replace_uri_query!(uri,first: next_page.count)

          next_page.url = uri
        end
      end

      return [next_page,link_count]
    end
  end

  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  class NextPage
    attr_accessor :count
    attr_accessor :rss_links
    attr_accessor :url

    def initialize()
      super()

      @count = -1
      @rss_links = nil
      @url = nil
    end

    def empty?()
      return @url.nil?() || @count < 0
    end
  end
end
