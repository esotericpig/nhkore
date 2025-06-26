# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020 Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++

require 'fileutils'
require 'time'

require 'nhkore/datetime_parser'
require 'nhkore/error'
require 'nhkore/missingno'
require 'nhkore/news'
require 'nhkore/search_link'
require 'nhkore/util'

module NHKore
module CLI
  module NewsCmd
    DEFAULT_NEWS_SCRAPE = 1

    def build_news_cmd
      app = self

      @news_cmd = @app_cmd.define_command do
        name    'news'
        usage   'news [OPTIONS] [COMMAND]...'
        aliases :n
        summary "Scrape NHK News Web (Easy) articles (aliases: #{app.color_alias('n')})"

        description <<-DESC
          Scrape NHK News Web (Easy) articles &
          save to folder: #{News::DEFAULT_DIR}
        DESC

        option :d,:datetime,<<-DESC,argument: :required,transform: lambda { |value|
          date time to use as a fallback in cases when an article doesn't have one;
          format: YYYY-mm-dd H:M; example: 2020-03-30 15:30
        DESC
          value = Time.strptime(value,'%Y-%m-%d %H:%M') { |year| DatetimeParser.guess_year(year) }
          value = Util.jst_time(value)
          value
        }
        option :i,:in,<<-DESC,argument: :required,transform: lambda { |value|
          HTML file of article to read instead of URL (for offline testing and/or slow internet;
          see '--no-dict' option)
        DESC
          app.check_empty_opt(:in,value)
        }
        flag :L,:lenient,<<-DESC
          leniently (not strict) scrape articles:
          body & title content without the proper HTML/CSS classes/IDs and no futsuurl;
          example URLs that need this flag:
          -https://www3.nhk.or.jp/news/easy/article/disaster_earthquake_02.html
          -https://www3.nhk.or.jp/news/easy/tsunamikeihou/index.html
        DESC
        option :k,:like,<<-DESC,argument: :required,transform: lambda { |value|
          text to fuzzy search links for; for example, "--like '00123'" will only scrape links containing
          text '00123' -- like '*00123*'
        DESC
          value = Util.strip_web_str(value).downcase
          value
        }
        option :l,:links,<<-DESC,argument: :required,transform: lambda { |value|
          'directory/file' of article links to scrape (see '#{App::NAME} search';
          defaults: #{SearchLinks::DEFAULT_YASASHII_FILE}, #{SearchLinks::DEFAULT_FUTSUU_FILE})
        DESC
          app.check_empty_opt(:links,value)
        }
        flag :M,:missingno,<<-DESC
          very rarely an article will not have kana or kanji for a Ruby tag;
          to not raise an error, this will use previously scraped data to fill it in;
          example URL:
          -https://www3.nhk.or.jp/news/easy/k10012331311000/k10012331311000.html
        DESC
        flag :D,:'no-dict',<<-DESC
          do not try to parse the dictionary files for the articles; useful in case of errors trying to load
          the dictionaries (or for offline testing)
        DESC
        flag :H,'no-sha256',<<-DESC
          do not check the SHA-256 of the content to see if an article has already been scraped;
          for example, 2 URLs with the same content, but 1 with 'http' & 1 with 'https', will both be scraped;
          this is useful if 2 articles have the same SHA-256, but different content (unlikely)
        DESC
        option :o,:out,<<-DESC,argument: :required,transform: lambda { |value|
          'directory/file' to save words to; if you only specify a directory or a file, it will attach
          the appropriate default directory/file name
          (defaults: #{YasashiiNews::DEFAULT_FILE}, #{FutsuuNews::DEFAULT_FILE})
        DESC
          app.check_empty_opt(:out,value)
        }
        flag :r,:redo,'scrape article links even if they have already been scraped'
        option :s,:scrape,'number of unscraped article links to scrape',
               argument: :required,
               default: DEFAULT_NEWS_SCRAPE,transform: lambda { |value|
                 value = value.to_i
                 value = 1 if value < 1
                 value
               }
        option nil,:'show-dict',<<-DESC
          show dictionary URL and contents for the first article and exit;
          useful for debugging dictionary errors (see '--no-dict' option);
          implies '--dry-run' option
        DESC
        option :u,:url,<<-DESC,argument: :required,transform: lambda { |value|
          URL of article to scrape, instead of article links file (see '--links' option)
        DESC
          app.check_empty_opt(:url,value)
        }

        run do |_opts,_args,cmd|
          puts cmd.help
        end
      end

      @news_easy_cmd = @news_cmd.define_command do
        name    'easy'
        usage   'easy [OPTIONS] [COMMAND]...'
        aliases :e,:ez
        summary "Scrape NHK News Web Easy (Yasashii) articles (aliases: #{app.color_alias('e ez')})"

        description <<-DESC
          Search for NHK News Web Easy (Yasashii) links &
          save to file: #{YasashiiNews::DEFAULT_FILE}
        DESC

        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_news_cmd(:yasashii)
        end
      end

      @news_regular_cmd = @news_cmd.define_command do
        name    'regular'
        usage   'regular [OPTIONS] [COMMAND]...'
        aliases :r,:reg
        summary "Scrape NHK News Web Regular (Futsuu) articles (aliases: #{app.color_alias('r reg')})"

        description <<-DESC
          Search for NHK News Web Regular (Futsuu) links &
          save to file: #{FutsuuNews::DEFAULT_FILE}
        DESC

        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_news_cmd(:futsuu)
        end
      end
    end

    def run_news_cmd(type)
      @cmd_opts[:dry_run] = true if @cmd_opts[:show_dict]
      news_name = nil

      build_in_file(:in)

      case type
      when :futsuu
        build_in_file(:links,default_dir: SearchLinks::DEFAULT_DIR,
                             default_filename: SearchLinks::DEFAULT_FUTSUU_FILENAME)
        build_out_file(:out,default_dir: News::DEFAULT_DIR,default_filename: FutsuuNews::DEFAULT_FILENAME)

        news_name = 'Regular'
      when :yasashii
        build_in_file(:links,default_dir: SearchLinks::DEFAULT_DIR,
                             default_filename: SearchLinks::DEFAULT_YASASHII_FILENAME)
        build_out_file(:out,default_dir: News::DEFAULT_DIR,default_filename: YasashiiNews::DEFAULT_FILENAME)

        news_name = 'Easy'
      else
        raise ArgumentError,"invalid type[#{type}]"
      end

      return unless check_in_file(:in,empty_ok: true)
      return unless check_out_file(:out)

      datetime = @cmd_opts[:datetime]
      dict = @cmd_opts[:no_dict] ? nil : :scrape
      dry_run = @cmd_opts[:dry_run]
      in_file = @cmd_opts[:in]
      lenient = @cmd_opts[:lenient]
      like = @cmd_opts[:like]
      links_file = @cmd_opts[:links]
      max_scrapes = @cmd_opts[:scrape]
      max_scrapes = DEFAULT_NEWS_SCRAPE if max_scrapes.nil?
      missingno = @cmd_opts[:missingno]
      no_sha256 = @cmd_opts[:no_sha256]
      out_file = @cmd_opts[:out]
      redo_scrapes = @cmd_opts[:redo]
      show_dict = @cmd_opts[:show_dict]

      # Favor in_file option over url option.
      url = in_file.nil? ? Util.strip_web_str(@cmd_opts[:url].to_s) : in_file
      url = nil if url.empty?

      # Then we must have a links file that exists.
      return if url.nil? && !check_in_file(:links,empty_ok: false)

      start_spin("Scraping NHK News Web #{news_name} articles")

      is_file = !in_file.nil?
      link_count = -1
      links = File.exist?(links_file) ? SearchLinks.load_file(links_file) : SearchLinks.new
      new_articles = [] # For --dry-run
      scrape_count = 0

      news = if File.exist?(out_file)
               (type == :yasashii) ? YasashiiNews.load_file(out_file,overwrite: no_sha256)
                                   : FutsuuNews.load_file(out_file,overwrite: no_sha256)
             else
               (type == :yasashii) ? YasashiiNews.new : FutsuuNews.new
             end

      @news_article_scraper_kargs = @scraper_kargs.merge({
        datetime: datetime,
        dict: dict,
        is_file: is_file,
        missingno: missingno ? Missingno.new(news) : nil,
        strict: !lenient,
      })
      @news_dict_scraper_kargs = @scraper_kargs.merge({
        is_file: is_file,
      })

      if url.nil?
        # Why store each() and do `links_len` instead of `links-len - 1`?
        #
        # If links contains 5 entries and you scrape all 5, then the output of
        # update_spin_detail() will end on 4, so all of this complexity is so
        # that update_spin_detail() only needs to be written/updated on one line.

        links_each = links.links.values.each
        links_len = links.length

        0.upto(links_len) do |i|
          update_spin_detail(" (scraped=#{scrape_count}, considered=#{link_count += 1})")

          break if i >= links_len || scrape_count >= max_scrapes

          link = links_each.next

          next if !like.nil? && !link.url.to_s.downcase.include?(like)
          next if !redo_scrapes && scraped_news_article?(news,link)

          url = link.url
          result = scrape_news_article(url,link: link,new_articles: new_articles,news: news)

          if result == :scraped
            scrape_count += 1
          elsif result == :unscraped
            next
          else
            # --show-dict
            url = result
            scrape_count = max_scrapes # Break on next iteration for update_spin_detail().
          end

          # Break on next iteration for update_spin_detail().
          next if scrape_count >= max_scrapes
          sleep_scraper
        end
      else
        link = links[url]

        if link.nil?
          link = SearchLink.new(url)
          links.add_link(link)
        end

        result = scrape_news_article(url,link: link,new_articles: new_articles,news: news)
        scrape_count += 1 if result != :unscraped
      end

      stop_spin
      puts

      if scrape_count <= 0
        puts 'Nothing scraped!'

        if !dry_run && !show_dict
          puts
          start_spin('Saving updated links to file')

          links.save_file(links_file)

          stop_spin
          puts "> #{links_file}"
        end
      else
        puts 'Last URL scraped:'
        puts "> #{url}"
        puts

        if show_dict
          puts @cmd_opts[:show_dict] # Updated in scrape_news_article()
        elsif dry_run
          if new_articles.empty?
            raise CLIError,"scrape_count[#{scrape_count}] != new_articles[#{new_articles.length}]; " \
                           'internal code is broken'
          elsif new_articles.length == 1
            puts new_articles.first
          else
            # Don't show the words (mini), too verbose for more than 1.
            new_articles.each do |article|
              puts article.to_s(mini: true)
            end
          end
        else
          start_spin('Saving scraped data to files')

          links.save_file(links_file)
          news.save_file(out_file)

          stop_spin
          puts "> #{out_file}"
          puts "> #{links_file}"
        end
      end
    end

    def scrape_news_article(url,link:,new_articles:,news:)
      show_dict = @cmd_opts[:show_dict]

      if show_dict
        scraper = DictScraper.new(url,**@news_dict_scraper_kargs)

        @cmd_opts[:show_dict] = scraper.scrape.to_s

        return scraper.url
      end

      scraper = nil

      begin
        scraper = ArticleScraper.new(url,**@news_article_scraper_kargs)
      rescue Http404Error
        # - https://www3.nhk.or.jp/news/easy/k10014157491000/k10014157491000.html
        Util.warn("Ignoring URL with 404 error: #{url}.")
        return :unscraped
      end

      article = scraper.scrape
      # run_news_cmd() handles overwriting with --redo or not
      #   using scraped_news_article?().
      news.add_article(article,overwrite: true)

      news.update_article(article,link.url) # Favors https
      link.update_from_article(article)

      new_articles << article

      return :scraped # No --show-dict
    end

    def scraped_news_article?(news,link)
      return true if link.scraped?

      no_sha256 = @cmd_opts[:no_sha256]

      article = news.article(link.url)

      if !no_sha256 && article.nil?
        if !Util.empty_web_str?(link.sha256) && news.sha256?(link.sha256)
          article = news.article_with_sha256(link.sha256)
        end

        if article.nil?
          scraper = nil

          begin
            scraper = ArticleScraper.new(link.url,**@news_article_scraper_kargs)
          rescue Http404Error
            return false
          end

          sha256 = scraper.scrape_sha256_only
          article = news.article_with_sha256(sha256) if news.sha256?(sha256)
        end
      end

      if article
        news.update_article(article,link.url) # Favors https
        link.update_from_article(article)

        return true
      end

      return false
    end
  end
end
end
