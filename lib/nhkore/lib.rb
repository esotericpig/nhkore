# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020 Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++

###
# Include this file to only require the files needed to use this
# Gem as a library (i.e., don't include CLI-related files).
###

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
require 'nhkore/util'
require 'nhkore/variator'
require 'nhkore/version'
require 'nhkore/word'
