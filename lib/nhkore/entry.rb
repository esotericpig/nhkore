# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++


require 'nhkore/defn'
require 'nhkore/util'


module NHKore
  class Entry
    HYOUKI_SEP = '・'

    attr_reader :defns
    attr_accessor :id

    def initialize
      super

      @defns = []
      @id = nil
    end

    def build_defn
      i = 0
      defns = @defns.map do |defn|
        "#{i += 1}）#{defn}" # Japanese parenthesis
      end

      return defns.join("\n")
    end

    def build_hyouki
      # Since Ruby v1.9, Hash preserves order.
      # Ruby v2.7 doc for Set still says no guarantee of order, so don't use.
      hyoukis = {}

      @defns.each do |defn|
        defn.hyoukis.each do |hyouki|
          hyouki = hyouki.chomp(HYOUKI_SEP)

          next if hyouki.empty?

          hyoukis[hyouki] = true
        end
      end

      return hyoukis.keys.join(HYOUKI_SEP)
    end

    def self.scrape(id,array,missingno: nil,url: nil)
      entry = Entry.new

      entry.id = Util.unspace_web_str(id.to_s).downcase

      return nil if entry.id.empty?

      array.each do |hash|
        defn = Defn.scrape(hash,missingno: missingno,url: url)
        entry.defns << defn unless defn.nil?
      end

      return nil if entry.defns.empty?
      return entry
    end

    def to_s
      s = ''.dup

      return s if @defns.empty?

      hyouki = build_hyouki

      s << "#{hyouki}\n" unless Util.empty_web_str?(hyouki)
      s << build_defn

      return s
    end
  end
end
