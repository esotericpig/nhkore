# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++


require 'nhkore/entry'
require 'nhkore/error'


module NHKore
  class Dict
    attr_reader :entries

    def initialize
      super

      @entries = {}
    end

    def [](id)
      return @entries[id]
    end

    def []=(id,entry)
      @entries[id] = entry
    end

    def self.scrape(hash,missingno: nil,url: nil)
      dict = Dict.new

      hash.each do |id,array|
        id = id.to_s.strip.downcase # 'RSHOK-K-003806', '0000'
        entry = Entry.scrape(id,array,missingno: missingno,url: url)

        next if entry.nil?
        raise ScrapeError,"duplicate ID[#{id}] at URL[#{url}] in hash[#{hash}]" if dict.key?(id)

        dict[id] = entry
      end

      return dict
    end

    def key?(id)
      return @entries.key?(id)
    end

    def to_s
      s = ''.dup

      @entries.each do |id,entry|
        s << "#{id}:\n"
        s << "  #{entry.to_s.gsub("\n","\n  ").rstrip}\n"
      end

      return s
    end
  end
end
