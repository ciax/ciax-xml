#!/usr/bin/ruby
require 'libenumx'
module CIAX
  # Disp::List: Sortable Caption Database (Value is String)
  #    Shows visiual command list categorized by sub-group
  #    Holds valid command list in @select
  #    Used by Command and XmlDoc
  #    Attribute items : caption(text), color(#), sub_color(#),  column(#), line_number(t/f)
  module Disp
    # Sub-Group of the Disp List
    class Group < Hashx
      attr_accessor :select
      def initialize(attr, select = [])
        @attr = Msg.type?(attr, Hash)
        @column = [attr['column'].to_i, 1].max
        # Selected items for display
        @select = Msg.type?(select, Array)
        # Always display items
        @dummy = []
      end

      def []=(k, v)
        @select << k
        super
      end

      def dummy(k, v)
        @dummy << k
        store(k, v)
      end

      def update(h)
        @select.concat h.keys
        super
      end

      # Reset @select(could be shared)
      def reset!
        @select.concat(keys).uniq!
        self
      end

      # For ver 1.9 or more
      def sort!
        @select.sort!
        self
      end

      # view mode
      def view(vx = nil, kx = 3)
        return '' if (t = list_table).empty?
        caption + Msg.columns(t, @column, vx, kx)
      end

      # max value length
      def vmax
        max = 0
        list_table.values.each_with_index do|v, i|
          max = v.size if (i % @column) < @column - 1 && v.size > max
        end
        max
      end

      # max key length
      def kmax
        list_table.keys.map(&:size).max || 0
      end

      private

      def caption
        @attr['caption'] ? ' == ' + Msg.color(@attr['caption'], (@attr['sub_color'] || 6).to_i) + " ==\n" : ''
      end

      def list_table
        hash = {}
        num = 0
        ((@select + @dummy) & keys).each do|key|
          next unless self[key]
          title = @attr['line_number'] ? "[#{num += 1}](#{key})" : key
          hash[title] = self[key]
        end
        hash
      end
    end

    class List < Arrayx
      def initialize(attr = {}, select = [])
        @attr = Msg.type?(attr, Hash)
        @select = select
      end

      def new_grp(caption = nil)
        attr = Hash[@attr.to_hash] # attr can be Config
        attr['caption'] = caption
        push(Group.new(attr, @select)).last
      end

      def select=(select)
        @select = Msg.type?(select, Array)
        each { |cg| cg.select = select }
        select
      end

      def merge!(displist)
        type?(displist, List).each do|cg|
          cg.select = @select
        end
        concat(displist)
        reset!
      end

      def reset!
        each(&:reset!)
        self
      end

      def key?(id)
        @select.include?(id)
      end

      def keys
        @select
      end

      def to_s
        b = grp_lists
        b.empty? ? '' : caption + b
      end

      private

      def caption
        @attr['caption'] ? '**** ' + Msg.color(@attr['caption'], (@attr['color'] || 2).to_i) + " ****\n" : ''
      end

      def grp_lists
        vmax = map(&:vmax).max
        kmax = map(&:kmax).max
        map { |cg| cg.view(vmax, kmax) }.grep(/./).join("\n")
      end
    end
  end
end
