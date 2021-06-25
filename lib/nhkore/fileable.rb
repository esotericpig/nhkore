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


module NHKore
  ###
  # @author Jonathan Bradley Whited (@esotericpig)
  # @since  0.2.0
  ###
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
