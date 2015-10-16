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

    class List < Hashx
      attr_accessor :select
      def initialize(attr = {}, select = [])
        @attr = Msg.type?(attr, Hash)
        @column = [attr['column'].to_i, 1].max
        # Selected items for display
        @select = select
        @group = Hashx['def' => @attr]
      end

      def put(k, v , grp='def')
        @select << k
        @group[grp][:member]=k
        super(k, v)
      end

      def new_grp(id,caption = nil)
        attr = Hashx[@attr.to_hash] # attr can be Config
        attr['caption'] = caption
        @group[id]=attr
      end

      def merge!(other)
        type?(other, List).select=@select
        @group.update(other.group)
        deep_update(other)
        reset!
      end

      # Reset @select(could be shared)
      def reset!
        @select.concat(keys).uniq!
        self
      end

      def key?(id)
        @select.include?(id)
      end

      def keys
        @select
      end

      def to_s
        grp_lists
      end

      private

      def caption(attr)
        attr['caption'] ? '**** ' + Msg.color(attr['caption'], (attr['color'] || 2).to_i) + " ****\n" : ''
      end

      def sub_caption(attr)
        attr['caption'] ? ' == ' + Msg.color(attr['caption'], (attr['sub_color'] || 6).to_i) + " ==\n" : ''
      end

      def grp_lists
        vmax = @select.map{|k| self[k].size }.max
        kmax = @select.map(&:size).max
        all=[caption(@attr)]
        @group.values_each do |gr|
          all << sub_caption(gr)
          gr[:member].each do |id|
            next unless @select.include?(id)
            all << Msg.columns(self[id],@column, vmax, kmax)
          end
        end.grep(/./).join("\n")
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
  end
end
