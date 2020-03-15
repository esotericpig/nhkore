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
require 'nhkore/news'
require 'nhkore/search_link'
require 'nhkore/util'


module NHKore
module CLI
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  module NewsCmd
    def build_news_cmd()
      app = self
      
      @news_cmd = @app_cmd.define_command() do
        name    'news'
        usage   'news [OPTIONS] [COMMAND]...'
        aliases :n
        summary 'Scrape NHK News Web (Easy) articles'
        
        description <<-EOD
          Scrape NHK News Web (Easy) articles &
          save to folder: #{Util::CORE_DIR}
        EOD
        
        option :i,:in,<<-EOD,argument: :required do |value,cmd|
          HTML file of article to read instead of URL (for offline testing and/or slow internet;
          see '--no-dict' option)
        EOD
          app.check_empty_opt(:in,value)
        end
        option :k,:like,<<-EOD,argument: :required
          text to fuzzy search links for; for example, "--like '00123'" will only scrape links containing
          text '00123' -- like '*00123*'
        EOD
        option :l,:links,<<-EOD,argument: :required do |value,cmd|
          'directory/file' of article links (from a Search Engine) to scrape (see '#{App::NAME} bing';
          defaults: #{SearchLinks::DEFAULT_BING_YASASHII_FILE}, #{SearchLinks::DEFAULT_BING_FUTSUU_FILE})
        EOD
          app.check_empty_opt(:links,value)
        end
        flag :D,:'no-dict',<<-EOD
          do not try to parse the dictionary files for the articles; useful in case of errors trying to load
          the dictionaries (or testing offline)
        EOD
        option :o,:out,<<-EOD,argument: :required do |value,cmd|
          'directory/file' to save words to; if you only specify a directory or a file, it will attach
          the appropriate default directory/file name
          (defaults: #{YasashiiNews::DEFAULT_FILE}, #{FutsuuNews::DEFAULT_FILE})
        EOD
          app.check_empty_opt(:out,value)
        end
        option :s,:scrape,'number of article links to scrape',argument: :optional,default: 1,
          transform: -> (value) do
          value = value.to_i()
          value = 1 if value < 1
        end
        option nil,:'show-dict',<<-EOD
          show the dictionary URL and contents for the first article and exit;
          useful for debugging dictionary errors (see '--no-dict' option)
        EOD
        option :u,:url,<<-EOD,argument: :required do |value,cmd|
          URL of article to scrape, instead of article links file (see '--links' option)
        EOD
          app.check_empty_opt(:url,value)
        end
        
        run do |opts,args,cmd|
          puts cmd.help
        end
      end
      
      @news_easy_cmd = @news_cmd.define_command() do
        name    'easy'
        usage   'easy [OPTIONS] [COMMAND]...'
        aliases :e,:ez
        summary 'Scrape NHK News Web Easy (Yasashii) articles'
        
        description <<-EOD
          Search for NHK News Web Easy (Yasashii) links &
          save to file: #{YasashiiNews::DEFAULT_FILE}
        EOD
        
        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_news_cmd(:yasashii)
        end
      end
      
      @news_regular_cmd = @news_cmd.define_command() do
        name    'regular'
        usage   'regular [OPTIONS] [COMMAND]...'
        aliases :r,:reg
        summary 'Scrape NHK News Web Regular (Futsuu) articles'
        
        description <<-EOD
          Search for NHK News Web Regular (Futsuu) links &
          save to file: #{FutsuuNews::DEFAULT_FILE}
        EOD
        
        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_news_cmd(:futsuu)
        end
      end
    end
    
    def run_news_cmd(type)
      build_in_file(:in)
      
      case type
      when :futsuu
        build_in_file(:links,default_dir: Util::CORE_DIR,default_filename: SearchLinks::DEFAULT_BING_FUTSUU_FILENAME)
        build_out_file(:out,default_dir: Util::CORE_DIR,default_filename: FutsuuNews::DEFAULT_FILENAME)
      when :yasashii
        build_in_file(:links,default_dir: Util::CORE_DIR,default_filename: SearchLinks::DEFAULT_BING_YASASHII_FILENAME)
        build_out_file(:out,default_dir: Util::CORE_DIR,default_filename: YasashiiNews::DEFAULT_FILENAME)
      else
        raise ArgumentError,"invalid type[#{type}]"
      end
      
      return unless check_in_file(:in,empty_ok: true)
      return unless check_out_file(:out)
      
      dry_run = @cmd_opts[:dry_run]
      in_file = @cmd_opts[:in]
      like_str = @cmd_opts[:like]
      links_file = @cmd_opts[:links]
      no_dict = @cmd_opts[:no_dict]
      out_file = @cmd_opts[:out]
      scrape_max = @cmd_opts[:scrape]
      show_dict = @cmd_opts[:show_dict]
      
      # Favor in_file option over url option.
      url = in_file.nil?() ? Util.strip_web_str(@cmd_opts[:url].to_s()) : in_file
      url = nil if url.empty?()
      
      if in_file.nil?() && url.nil?()
        # Then we must have a links file that exists.
        return unless check_in_file(:links,empty_ok: false)
      else
        links_file = nil # Don't need
      end
      
      start_spin('Scraping NHK News articles')
      
      is_file = !in_file.nil?()
      links = links_file.nil?() ? nil : SearchLinks.load_file(links_file)
      news = nil
      scrape_count = 0
      
      if File.exist?(out_file)
        news = (type == :yasashii) ? YasashiiNews.load_file(out_file) : FutsuuNews.load_file(out_file)
      else
        news = (type == :yasashii) ? YasashiiNews.new() : FutsuuNews.new()
      end
      
      #TODO: no_dict
      #TODO: show_dict
      
      if links.nil?()
        # TODO: probably new method for logic can use here or below for 1 file
      else
        links.links.each() do |key,link|
          # TODO: news.article from link/sha256; raise error if 1 is nil & 1 is not
          if link.scraped?() #|| news.article?(link)
            # TODO: update URL if https; remove non-https
            
            next
          end
          
          next if !like_str.nil?() && !link.url.include?(like_str)
          
          if show_dict
            # TODO: DictScraper; show_dict = URL + dict
          end
          
          # TODO: compute sha256 and news.article?(sha256)
          # TODO: scrape article link
          
          break if (scrape_count += 1) >= scrape_max
          
          sleep_scraper()
        end
      end
      
      stop_spin()
      puts
      
      if scrape_count <= 0
        puts 'Nothing scraped!'
      else
        puts 'Last URL scraped:'
        puts "> #{url}"
        
        if show_dict
          puts show_dict
        elsif dry_run
          puts
          
          # TODO: if dry-run, if X > 1, then just output header (no words)
        else
          links.save_file(links_file) unless links.nil?()
          news.save_file(out_file)
        end
      end
    end
  end
end
end
