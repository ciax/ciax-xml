#!/usr/bin/ruby
require 'librecord'
require 'librecarc'

module CIAX
  # Macro Layer
  module Mcr
    # Visible Record Database
    class RecList < Hashx
      def initialize(rec_arc = RecArc.new)
        @rec_arc = type?(rec_arc, RecArc)
      end

      # delete from @records other than in ary
      def flush(ary)
        (keys - ary).each do |id|
          delete(id)
        end
        self
      end

      def push(record) # returns self
        id = record[:id]
        return self unless id.to_i > 0
        self[id] = record
        self
      end

      #### Client Methods ####
      def ext_http(host)
        @host = host
        self
      end

      def upd
        values.each(&:upd)
        self
      end

      def get(id)
        type?(id, String)
        super(id) { |key| Record.new(key).ext_http(@host, 'record') }
      end
    end
  end
end
