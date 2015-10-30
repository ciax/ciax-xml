#!/usr/bin/ruby
require 'libenumx'
# Display: Sortable Caption Database (Value is String)
#   New feature: can make recursive groups
#   Shows visiual command list categorized by sub-group
#   Holds valid command list in @select
#   Used by Command and XmlDoc
module CIAX
  # Index of Display (Used for validation, display)
  class Disp < Hashx
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
      view
    end

    def view(select = @select, level = 0, cap = nil)
      list = {}
      (@select & select).compact.sort.each_with_index do|id, num|
        title = @atrb[:line_number] ? "[#{num}](#{id})" : id
        list[title] = self[id]
      end
      return if list.empty?
      columns(list, @atrb[:column], level, mk_caption(cap, level))
    end

    def mk_caption(cap, level)
      return unless cap
      sep, col = SEPTBL[level]
      indent(level) +
        caption(cap, col, sep)
    end

    # Parent of Group
    class Section < Hashx
      attr_accessor :index
      def initialize(index, cap = nil, level = nil)
        @index = type?(index, Disp)
        @caption = cap
        @level = level || -1
      end

      # add sub caption if sub is true
      def put(id, cap = nil, sub = nil)
        mod = sub ? Section : Group
        self[id] = mod.new(@index, cap, @level + 1)
      end

      def view
        ary = values.map(&:view).grep(/./)
        ary.unshift(@index.mk_caption(@caption, @level)) if @caption
        ary.join("\n")
      end

      def to_s
        view
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
    class Group < Arrayx
      attr_accessor :index
      def initialize(index, cap = nil, level = nil)
        @index = type?(index, Disp)
        @caption = cap
        @level = level || 0
      end

      # add item
      def put(k, v)
        push k
        @index.select << k
        @index[k] = v
      end

      def view
        @index.view(self, @level, @caption)
      end

      def to_s
        view
      end
    end
  end

  if __FILE__ == $PROGRAM_NAME
    # Top level only
    idx0 = Disp.new(column: 3)
    10.times { |i| idx0.put("x#{i}", "caption #{i}") }
    puts idx0
    puts
    # Three level groups
    idx1 = Disp.new(column: 3)
    grp1 = Disp::Section.new(idx1)
    2.times do |i|
      s11 = grp1.put("g#{i}", "Group#{i}",true)
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
    idx2 = Disp.new(column: 2, line_number: true)
    grp2 = Disp::Section.new(idx2)
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
