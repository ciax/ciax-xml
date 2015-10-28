#!/usr/bin/ruby
require 'libenumx'
# Display: Sortable Caption Database (Value is String)
#   New feature: can make recursive groups
#   Shows visiual command list categorized by sub-group
#   Holds valid command list in @select
#   Used by Command and XmlDoc
module CIAX
  # Index of Display (Used for validation, display)
  class Display < Hashx
    # Grouping class (Used for setting db)
    #   Attributes (all level): column(#), line_number(t/f)
    #   Attributes (one level): child(module), color(#), indent(#)
    #   Attributes (one group): caption(text), members(array)
    SEPTBL = [['****', 2], ['===', 6], ['--', 9], ['_', 14]]
    attr_reader :select, :atrb
    def initialize(atrb = { column: 2 }, select = [])
      @atrb = atrb
      @select = select
    end

    def put(k, v)
      @select << k
      super
    end

    # For ver 1.9 or more
    def sort!
      @select.sort!
      self
    end

    # Reset @select(could be shared)
    def reset!
      @select.concat(keys).uniq!
      self
    end

    def clear
      @select.clear
      super
    end

    def delete(id)
      @select.delete(id)
      super
    end

    def to_s
      view(@select)
    end

    def view(select, level = 0, cap = nil)
      list = mk_list(select)
      return if list.empty?
      columns(list, @atrb[:column], level, mk_caption(cap, level))
    end

    def mk_caption(cap, level)
      return unless cap
      sep, col = SEPTBL[level]
      indent(level) +
        caption(cap, col, sep)
    end

    private

    def mk_list(select)
      list = {}
      select.compact.sort.each_with_index do|id, num|
        title = @atrb[:line_number] ? "[#{num}](#{id})" : id
        list[title] = self[id]
      end
      list
    end

    # Parent of Group
    class Section < Hashx
      attr_accessor :index, :level, :sub
      def initialize(index, sub = Group, cap = nil, level = nil)
        @index = type?(index, Display)
        @caption = cap
        @level = level || -1
        @sub = sub
      end

      # add sub group
      def put(id, cap, sub = Group)
        self[id] = @sub.new(@index, sub, cap, @level + 1)
      end

      def to_s
        ary = [@index.mk_caption(@caption, @level)]
        (ary + values).map(&:to_s).grep(/./).join("\n")
      end

      def merge_sub(other)
        rec_merge_index(other)
        update(other)
        @index.reset!
      end

      private

      def rec_merge_index(gr)
        type?(gr, Hashx).values.each do |sg|
          rec_merge_index(sg) if sg.is_a? Hashx
        end
        @index.update(gr.index)
        gr.index = @index
      end
    end

    # It has members of item
    class Group < Hashx
      attr_accessor :index
      def initialize(index, _sub, cap, level)
        @index = type?(index, Display)
        @caption = cap
        @level = level || 0
        @members = []
      end

      # add item
      def put(k, v)
        @members << k
        @index.select << k
        @index[k] = v
      end

      def to_s
        @index.view(@members & @index.select, @level, @caption)
      end
    end
  end

  if __FILE__ == $PROGRAM_NAME
    # Top level only
    idx0 = Display.new(column: 3)
    10.times { |i| idx0.put("x#{i}", "caption #{i}") }
    puts idx0
    puts
    # Three level groups
    idx1 = Display.new(column: 3)
    grp1 = Display::Section.new(idx1, Display::Section)
    2.times do |i|
      s11 = grp1.put("g#{i}", "Group#{i}")
      3.times do |j|
        s12 = s11.put("sg#{j}", "SubGroup#{j}")
        4.times do |k|
          cstr = '*' * rand(5)
          s12.put("#{i}-#{j}-#{k}", "caption#{i}-#{j}-#{k},#{cstr}")
        end
      end
    end
    puts grp1
    puts
    # Two level groups with item number
    idx2 = Display.new(column: 2, line_number: true)
    grp2 = Display::Section.new(idx2)
    3.times do |i|
      s21 = grp2.put("g2#{i}", "Gp#{i}")
      3.times do |j|
        cstr = '*' * rand(5)
        s21.put("#{i}-#{j}", "cp#{i}-#{j},#{cstr}")
      end
    end
    puts grp2
    puts
    # Merging groups
    grp1.merge_sub(grp2)
    puts grp1
    puts
    # Confirm merged index
    idx1.select.delete('0-0')
    puts grp1
  end
end
