#!/usr/bin/ruby
require 'libenumx'
# Display: Sortable Caption Database (Value is String)
#   New feature: can make recursive groups
#   Shows visiual command list categorized by sub-group
#   Holds valid command list in @valid
#   Used by Command and XmlDoc
module CIAX
  # Index of Display (Used for validation, display)
  class Disp < Hashx
    # Grouping class (Used for setting db)
    #   Attributes (all level): column(#), line_number(t/f)
    #   Attributes (one level): child(module), color(#), indent(#)
    #   Attributes (one group): caption(text), members(array)
    SEPTBL = [['****', 2], ['===', 6], ['--', 9], ['_', 14]]
    attr_reader :valid
    def initialize(valid = [])
      @valid = valid
    end

    def put(k, v)
      @valid << k
      super
    end

    # For ver 1.9 or more
    def sort!
      @valid.sort!
      self
    end

    # Reset @valid(could be shared)
    def reset!
      @valid.concat(keys).uniq!
      self
    end

    def clear
      @valid.clear
      super
    end

    def delete(id)
      @valid.delete(id)
      super
    end

    def to_s
      view
    end

    def view(select: @valid, level: 0, cap: nil, column: 2, line_number: false)
      list = {}
      (@valid & select).compact.sort.each_with_index do|id, num|
        title = line_number ? "[#{num}](#{id})" : id
        list[title] = self[id]
      end
      return if list.empty?
      columns(list, column, level, mk_caption(cap, level))
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
      def initialize(index: Disp.new, cap: nil, level: nil, column: 2, line_number: false)
        @index = type?(index, Disp)
        @caption = cap
        @level = level || -1
        @column = column
        @line_number = line_number
      end

      # add sub caption if sub is true
      def put(id, cap = nil, sub = nil)
        mod = sub ? Section : Group
        self[id] = mod.new(index: @index, cap: cap, level: @level + 1, column: @column, line_number: @line_number)
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
      def initialize(index: Disp.new, cap: nil, level: nil, column: 2, line_number: false)
        @index = type?(index, Disp)
        @caption = cap
        @level = level || 0
        @column = column
        @line_number = line_number
      end

      # add item
      def put(k, v)
        push k
        @index.valid << k
        @index[k] = v
      end

      def view
        @index.view(select: self, level: @level, cap: @caption, column: @column, line_number: @line_number)
      end

      def to_s
        view.to_s
      end
    end
  end

  if __FILE__ == $PROGRAM_NAME
    # Top level only
    grp0 = Disp::Group.new(column: 3)
    10.times { |i| grp0.put("x#{i}", "caption #{i}") }
    puts grp0.view
    puts
    # Three level groups
    grp1 = Disp::Section.new(column: 3)
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
    grp2 = Disp::Section.new(column: 2, line_number: true)
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
    grp1.index.valid.delete('0-0')
    puts grp1
  end
end
