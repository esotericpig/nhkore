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
  # @since  0.3.0
  ###
  module SearchCmd
    def build_search_cmd()
      app = self

      @search_cmd = @app_cmd.define_command() do
        name    'search'
        usage   'search [OPTIONS] [COMMAND]...'
        aliases :se,:sea
        summary "Search for links to NHK News Web (Easy) (aliases: #{app.color_alias('se sea')})"

        description <<-EOD
          Search for links (using a Search Engine, etc.) to NHK News Web (Easy) &
          save to folder: #{SearchLinks::DEFAULT_DIR}
        EOD

        option :i,:in,<<-EOD,argument: :required,transform: lambda { |value|
          file to read instead of URL (for offline testing and/or slow internet;
          see '--show-*' options)
        EOD
          app.check_empty_opt(:in,value)
        }
        option :o,:out,<<-EOD,argument: :required,transform: lambda { |value|
          'directory/file' to save links to; if you only specify a directory or a file, it will attach the
          appropriate default directory/file name
          (defaults: #{SearchLinks::DEFAULT_YASASHII_FILE}, #{SearchLinks::DEFAULT_FUTSUU_FILE})
        EOD
          app.check_empty_opt(:out,value)
        }
        option :r,:results,'number of results per page to request from search',argument: :required,
            default: SearchScraper::DEFAULT_RESULT_COUNT,transform: lambda { |value|
          value = value.to_i()
          value = 1 if value < 1
          value
        }
        option nil,:'show-count',<<-EOD
          show the number of links scraped and exit;
          useful for manually writing/updating scripts (but not for use in a variable);
          implies '--dry-run' option
        EOD
        option nil,:'show-urls',<<-EOD
          show the URLs -- if any -- used when searching & scraping and exit;
          you can download these for offline testing and/or slow internet
          (see '--in' option)
        EOD

        run do |opts,args,cmd|
          opts.each() do |key,value|
            key = key.to_s()

            if key.include?('show')
              raise CLIError,"must specify a sub command for option[#{key}]"
            end
          end

          puts cmd.help
        end
      end

      @search_easy_cmd = @search_cmd.define_command() do
        name    'easy'
        usage   'easy [OPTIONS] [COMMAND]...'
        aliases :e,:ez
        summary "Search for NHK News Web Easy (Yasashii) links (aliases: #{app.color_alias('e ez')})"

        description <<-EOD
          Search for NHK News Web Easy (Yasashii) links &
          save to file: #{SearchLinks::DEFAULT_YASASHII_FILE}
        EOD

        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_search_help()
        end
      end

      @search_regular_cmd = @search_cmd.define_command() do
        name    'regular'
        usage   'regular [OPTIONS] [COMMAND]...'
        aliases :r,:reg
        summary "Search for NHK News Web Regular (Futsuu) links (aliases: #{app.color_alias('r reg')})"

        description <<-EOD
          Search for NHK News Web Regular (Futsuu) links &
          save to file: #{SearchLinks::DEFAULT_FUTSUU_FILE}
        EOD

        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_search_help()
        end
      end

      @search_bing_cmd = Cri::Command.define() do
        name    'bing'
        usage   'bing [OPTIONS] [COMMAND]...'
        aliases :b
        summary "Search bing.com for links (aliases: #{app.color_alias('b')})"

        description <<-EOD
          Search bing.com for links & save to folder: #{SearchLinks::DEFAULT_DIR}
        EOD

        run do |opts,args,cmd|
          app.refresh_cmd(opts,args,cmd)
          app.run_search_cmd(cmd.supercommand.name.to_sym(),:bing)
        end
      end

      # dup()/clone() must be called for `cmd.supercommand` to work appropriately.
      @search_easy_cmd.add_command @search_bing_cmd.dup()
      @search_regular_cmd.add_command @search_bing_cmd.dup()
    end

    def run_search_cmd(nhk_type,search_type)
      case nhk_type
      when :easy
        nhk_type = :yasashii
      when :regular
        nhk_type = :futsuu
      end

      return if show_search_urls(search_type)

      @cmd_opts[:dry_run] = true if @cmd_opts[:show_count]

      build_in_file(:in)

      case nhk_type
      when :futsuu
        build_out_file(:out,default_dir: SearchLinks::DEFAULT_DIR,
          default_filename: SearchLinks::DEFAULT_FUTSUU_FILENAME)
      when :yasashii
        build_out_file(:out,default_dir: SearchLinks::DEFAULT_DIR,
          default_filename: SearchLinks::DEFAULT_YASASHII_FILENAME)
      else
        raise ArgumentError,"invalid nhk_type[#{nhk_type}]"
      end

      return unless check_in_file(:in,empty_ok: true)
      return unless check_out_file(:out)

      dry_run = @cmd_opts[:dry_run]
      in_file = @cmd_opts[:in]
      out_file = @cmd_opts[:out]
      result_count = @cmd_opts[:results]
      result_count = SearchScraper::DEFAULT_RESULT_COUNT if result_count.nil?()
      show_count = @cmd_opts[:show_count]

      start_spin("Scraping #{search_type}") unless show_count

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

        links.links.each_value() do |link|
          scraped_count += 1 if link.scraped?()
        end

        puts "#{scraped_count} of #{links_count} links scraped."

        return
      end

      range = (0..10_000) # Do a range to prevent an infinite loop; ichiman!

      case search_type
      # Anything that extends SearchScraper.
      when :bing
        range.each() do
          scraper = nil

          case search_type
          when :bing
            scraper = BingScraper.new(nhk_type,count: result_count,is_file: is_file,url: url,**@scraper_kargs)
          else
            raise NHKore::Error,"internal code broken; add missing search_type[#{search_type}]"
          end

          next_page = scraper.scrape(links,next_page)

          new_links.concat(links.links.values[links_count..-1])
          links_count = links.length
          page_count = next_page.count if next_page.count > 0

          update_spin_detail(" (page=#{page_num}, count=#{page_count}, links=#{links.length}," \
            " new_links=#{new_links.length})")

          break if next_page.empty?()

          page_num += 1
          url = next_page.url

          sleep_scraper()
        end
      else
        raise ArgumentError,"invalid search_type[#{search_type}]"
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

    def run_search_help()
      if @cmd_opts[:show_count] || @cmd_opts[:show_urls]
        run_search_cmd(@cmd.name.to_sym(),nil)
      else
        puts @cmd.help
      end
    end

    def show_search_urls(search_type)
      return false unless @cmd_opts[:show_urls]

      count = @cmd_opts[:results]
      count = SearchScraper::DEFAULT_RESULT_COUNT if count.nil?()

      case search_type
      when :bing
        puts 'Bing:'
        puts "> Easy:    #{BingScraper.build_url(SearchScraper::YASASHII_SITE,count: count)}"
        puts "> Regular: #{BingScraper.build_url(SearchScraper::FUTSUU_SITE,count: count)}"
      else
        raise CLIError,'must specify a sub command for option[show-urls]'
      end

      return true
    end
  end
end
end
