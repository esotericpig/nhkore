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


require 'nhkore/article'
require 'nhkore/article_scraper'
require 'nhkore/cleaner'
require 'nhkore/datetime_parser'
require 'nhkore/defn'
require 'nhkore/dict'
require 'nhkore/dict_scraper'
require 'nhkore/entry'
require 'nhkore/error'
require 'nhkore/fileable'
require 'nhkore/missingno'
require 'nhkore/news'
require 'nhkore/polisher'
require 'nhkore/scraper'
require 'nhkore/search_link'
require 'nhkore/search_scraper'
require 'nhkore/sifter'
require 'nhkore/splitter'
require 'nhkore/user_agents'
require 'nhkore/util'
require 'nhkore/variator'
require 'nhkore/version'
require 'nhkore/word'


module NHKore
  ###
  # Include this file to only require the files needed to use this
  # Gem as a library (i.e., don't include CLI-related files).
  #
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.3.2
  ###
  module Lib
  end
end
