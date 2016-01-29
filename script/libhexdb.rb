#!/usr/bin/ruby
require 'libdb'

# id = Table Group ID
module CIAX
  # Hex module
  module Hex
    # Hex DB
    class Db < Db
      def initialize
        super('hdb')
      end

      private

      def doc_to_db(doc)
        db = super
        doc[:top].each do|e1| #top is 'hexpack'
          item = Hashx.new(e1.to_h)
          id = item[:id]
          label = item[:label]
          case e1.name
          when 'pack'
            (db[:pack] ||= []) << item
            e1.each do |e2|
              (item[:fields] ||= []) << Hashx.new(e2.to_h)
            end
          when 'field'
            (db[:fields] ||= [])<< item
          end
          verbose { "Hex Table:#{id} : #{label}" }
        end
        db
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('r')
      begin
        dbi = Db.new.get(ARGV.shift)
      rescue InvalidID
        OPT.usage('[id] (key) ..')
      end
      puts OPT[:r] ? dbi.to_v : dbi.path(ARGV)
    end
  end
end
