# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of NHKore.
# Copyright (c) 2020-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#++


module NHKore
  module Fileable
    def self.included(mod)
      mod.extend ClassMethods
    end

    def save_file(file,mode: 'wt',**kargs)
      File.open(file,mode: mode,**kargs) do |f|
        f.write(to_s)
      end
    end

    # Auto-extended when Fileable is included.
    module ClassMethods
      def load_file(file,mode: 'rt:BOM|UTF-8',**kargs)
        data = File.read(file,mode: mode,**kargs)

        return load_data(data,file: file,**kargs)
      end
    end
  end
end
