# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++


require 'nokogiri'

require 'nhkore/util'
require 'nhkore/word'


module NHKore
  ###
  # @author Jonathan Bradley Whited
  # @since  0.2.0
  ###
  class Defn
    attr_reader :hyoukis
    attr_accessor :text
    attr_reader :words

    def initialize
      super()

      @hyoukis = []
      @text = ''.dup
      @words = []
    end

    # If no data, don't raise errors; don't care if have a definition or not.
    def self.scrape(hash,missingno: nil,url: nil)
      defn = Defn.new

      hyoukis = hash['hyouki']

      hyoukis&.each() do |hyouki|
        next if hyouki.nil?
        next if (hyouki = Util.strip_web_str(hyouki)).empty?

        defn.hyoukis << hyouki
      end

      def_str = hash['def']

      if Util.empty_web_str?(def_str)
        return defn.hyoukis.empty? ? nil : defn
      end

      doc = Nokogiri::HTML(def_str)
      doc = doc.css('body') # Auto-added by Nokogiri.

      doc.children.each do |child|
        name = Util.unspace_web_str(child.name).downcase if child.respond_to?(:name)

        is_text = false
        words = []

        if name == 'ruby'
          # Returns an array.
          words = Word.scrape_ruby_tag(child,missingno: missingno,url: url)
        elsif child.respond_to?(:text) # Don't do child.text?(), just want content.
          words << Word.scrape_text_node(child,url: url)
          is_text = true
        end

        # All word-scraping methods can return nil,
        #   so remove all nils for empty?() check.
        words = words&.compact

        if words.nil? || words.empty?
          defn.text << Util.reduce_jpn_space(child.text) if is_text
        else
          words.each do |word|
            defn.text << Util.reduce_jpn_space(word.word)
            defn.words << word unless Util.empty_web_str?(word.word)
          end
        end
      end

      return nil if defn.hyoukis.empty? && defn.words.empty?

      defn.text = Util.strip_web_str(defn.text)

      return defn
    end

    def to_s
      return @text
    end
  end
end
