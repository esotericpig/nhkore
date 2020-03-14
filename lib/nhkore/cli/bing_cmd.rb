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
        summary 'Search bing.com for links to NHK News Web (Easy)'
        
        description <<-EOD
          Search bing.com for links to NHK News Web (Easy) &
          save to folder: #{Util::CORE_DIR}
        EOD
        
        option :i,:in,<<-EOD,argument: :required
          file to read instead of URL (for offline testing and/or slow internet; see --show-urls option)
        EOD
        option :o,:out,<<-EOD,argument: :required
          'directory/file' to save links to; if you only specify a directory or a file, it will attach the
          the appropriate default directory/file name
          (defaults: #{SearchLinks::DEFAULT_BING_YASASHII_FILE}, #{SearchLinks::DEFAULT_BING_FUTSUU_FILE})
        EOD
        option :r,:results,'number of results per page to request from Bing',argument: :required,
          default: SearchScraper::DEFAULT_RESULT_COUNT,transform: -> (value) do
          value = value.to_i()
          value = 1 if value < 1
          value
        end
        option nil,:'show-urls',<<-EOD do |value,cmd|
          show the URLs used when scraping and exit; you can download these for offline testing and/or
          slow internet (see -i/--in option)
        EOD
          puts "Easy:    #{BingScraper.build_url(SearchScraper::YASASHII_SITE)}"
          puts "Regular: #{BingScraper.build_url(SearchScraper::FUTSUU_SITE)}"
          exit
        end
        
        run do |opts,args,cmd|
          puts cmd.help
        end
      end
      
      @bing_easy_cmd = @bing_cmd.define_command() do
        name    'easy'
        usage   'easy [OPTIONS] [COMMAND]...'
        aliases :e,:ez
        summary 'Search for NHK News Web Easy (Yasashii) links'
        
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
        summary 'Search for NHK News Web Regular (Futsuu) links'
        
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
      dry_run = @cmd_opts[:dry_run]
      in_file = build_in_file(:in)
      out_file = nil
      result_count = @cmd_opts[:results]
      
      case type
      when :futsuu
        out_file = build_out_file(:out,Util::CORE_DIR,SearchLinks::DEFAULT_BING_FUTSUU_FILENAME)
      when :yasashii
        out_file = build_out_file(:out,Util::CORE_DIR,SearchLinks::DEFAULT_BING_YASASHII_FILENAME)
      else
        raise ArgumentError,"invalid type[#{type}]"
      end
      
      return unless check_in_file(:in)
      return unless check_out_file(:out)
      
      start_spin('Scraping bing.com')
      
      is_file = !in_file.nil?()
      links = nil
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
      
      base_links_count = links.links.length
      
      # Do a range to prevent an infinite loop. Ichiman!
      (0..10000).each() do
        scraper = BingScraper.new(type,count: result_count,is_file: is_file,url: url)
        
        next_page = scraper.scrape(links,next_page)
        
        page_count = next_page.count if next_page.count > 0
        
        update_spin_detail(" (page=#{page_num}, count=#{page_count}, links=#{links.links.length}, " +
          "new_links=#{links.links.length - base_links_count})")
        
        break if next_page.empty?()
        
        page_num += 1
        url = next_page.url
        
        sleep_scraper()
      end
      
      stop_spin()
      puts
      
      puts 'Last URL scraped:'
      puts "> #{url}"
      
      if dry_run
        puts
        
        # links.to_s() is too verbose (YAML).
        links.links.each() do |key,link|
          puts link.url
        end
      else
        links.save_file(out_file)
      end
    end
  end
end
end
