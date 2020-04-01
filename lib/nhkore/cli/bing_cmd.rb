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
require 'nhkore/search_link'
require 'nhkore/search_scraper'
require 'nhkore/util'


module NHKore
module CLI
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
  module BingCmd
    def build_bing_cmd()
      app = self
      
      @bing_cmd = @app_cmd.define_command() do
        name    'bing'
        usage   'bing [OPTIONS] [COMMAND]...'
        aliases :b
        summary "Search bing.com for links to NHK News Web (Easy) (aliases: #{app.color_alias('b')})"
        
        description <<-EOD
          Search bing.com for links to NHK News Web (Easy) &
          save to folder: #{SearchLinks::DEFAULT_DIR}
        EOD
        
        option :i,:in,<<-EOD,argument: :required,transform: -> (value) do
          HTML file to read instead of URL (for offline testing and/or slow internet;
          see '--show-urls' option)
        EOD
          app.check_empty_opt(:in,value)
        end
        option :o,:out,<<-EOD,argument: :required,transform: -> (value) do
          'directory/file' to save links to; if you only specify a directory or a file, it will attach the
          appropriate default directory/file name
          (defaults: #{SearchLinks::DEFAULT_BING_YASASHII_FILE}, #{SearchLinks::DEFAULT_BING_FUTSUU_FILE})
        EOD
          app.check_empty_opt(:out,value)
        end
        option :r,:results,'number of results per page to request from Bing',argument: :required,
          default: SearchScraper::DEFAULT_RESULT_COUNT,transform: -> (value) do
          value = value.to_i()
          value = 1 if value < 1
          value
        end
        option nil,:'show-count',<<-EOD
          show the number of links scraped and exit;
          useful for manually writing/updating scripts (but not for use in a variable);
          implies '--dry-run' option
        EOD
        option nil,:'show-urls',<<-EOD
          show the URLs used when scraping and exit; you can download these for offline testing and/or
          slow internet (see '--in' option)
        EOD
        
        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.show_bing_urls()
          
          puts cmd.help
        end
      end
      
      @bing_easy_cmd = @bing_cmd.define_command() do
        name    'easy'
        usage   'easy [OPTIONS] [COMMAND]...'
        aliases :e,:ez
        summary "Search for NHK News Web Easy (Yasashii) links (aliases: #{app.color_alias('e ez')})"
        
        description <<-EOD
          Search for NHK News Web Easy (Yasashii) links &
          save to file: #{SearchLinks::DEFAULT_BING_YASASHII_FILE}
        EOD
        
        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_bing_cmd(:yasashii)
        end
      end
      
      @bing_regular_cmd = @bing_cmd.define_command() do
        name    'regular'
        usage   'regular [OPTIONS] [COMMAND]...'
        aliases :r,:reg
        summary "Search for NHK News Web Regular (Futsuu) links (aliases: #{app.color_alias('r reg')})"
        
        description <<-EOD
          Search for NHK News Web Regular (Futsuu) links &
          save to file: #{SearchLinks::DEFAULT_BING_FUTSUU_FILE}
        EOD
        
        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_bing_cmd(:futsuu)
        end
      end
    end
    
    def run_bing_cmd(type)
      show_bing_urls()
      
      @cmd_opts[:dry_run] = true if @cmd_opts[:show_count]
      
      build_in_file(:in)
      
      case type
      when :futsuu
        build_out_file(:out,default_dir: SearchLinks::DEFAULT_DIR,default_filename: SearchLinks::DEFAULT_BING_FUTSUU_FILENAME)
      when :yasashii
        build_out_file(:out,default_dir: SearchLinks::DEFAULT_DIR,default_filename: SearchLinks::DEFAULT_BING_YASASHII_FILENAME)
      else
        raise ArgumentError,"invalid type[#{type}]"
      end
      
      return unless check_in_file(:in,empty_ok: true)
      return unless check_out_file(:out)
      
      dry_run = @cmd_opts[:dry_run]
      in_file = @cmd_opts[:in]
      out_file = @cmd_opts[:out]
      result_count = @cmd_opts[:results]
      result_count = SearchScraper::DEFAULT_RESULT_COUNT if result_count.nil?()
      show_count = @cmd_opts[:show_count]
      
      start_spin('Scraping bing.com') unless show_count
      
      is_file = !in_file.nil?()
      links = nil
      new_links = [] # For --dry-run
      next_page = NextPage.new()
      page_count = 0
      page_num = 1
      url = in_file # nil will use default URL, else a file
      
      # Load previous links for 'scraped?' vars.
      if File.exist?(out_file)
        links = SearchLinks.load_file(out_file)
      else
        links = SearchLinks.new()
      end
      
      links_count = links.length
      
      if show_count
        scraped_count = 0
        
        links.links.values.each() do |link|
          scraped_count += 1 if link.scraped?()
        end
        
        puts "#{scraped_count} of #{links_count} links scraped."
        
        return
      end
      
      # Do a range to prevent an infinite loop. Ichiman!
      (0..10000).each() do
        scraper = BingScraper.new(type,count: result_count,is_file: is_file,url: url,**@scraper_kargs)
        
        next_page = scraper.scrape(links,next_page)
        
        new_links.concat(links.links.values[links_count..-1])
        links_count = links.length
        page_count = next_page.count if next_page.count > 0
        
        update_spin_detail(" (page=#{page_num}, count=#{page_count}, links=#{links.length}, " +
          "new_links=#{new_links.length})")
        
        break if next_page.empty?()
        
        page_num += 1
        url = next_page.url
        
        sleep_scraper()
      end
      
      stop_spin()
      puts
      
      puts 'Last URL scraped:'
      puts "> #{url}"
      puts
      
      if dry_run
        new_links.each() do |link|
          puts link.to_s(mini: true)
        end
      else
        links.save_file(out_file)
        
        puts 'Saved scraped links to file:'
        puts "> #{out_file}"
      end
    end
    
    def show_bing_urls()
      return unless @cmd_opts[:show_urls]
      
      count = @cmd_opts[:results]
      count = SearchScraper::DEFAULT_RESULT_COUNT if count.nil?()
      
      puts "Easy:    #{BingScraper.build_url(SearchScraper::YASASHII_SITE,count: count)}"
      puts "Regular: #{BingScraper.build_url(SearchScraper::FUTSUU_SITE,count: count)}"
      
      exit
    end
  end
end
end
