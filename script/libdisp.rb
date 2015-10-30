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
    attr_accessor :column, :line_number
    def initialize(valid = [], column = 2, line_number = false)
      @column = column
      @line_number = line_number
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

    def view(select: @valid, level: 0, cap: nil, color: nil)
      list = {}
      (@valid & select).compact.sort.each_with_index do|id, num|
        title = @line_number ? "[#{num}](#{id})" : id
        list[title] = self[id]
      end
      return if list.empty?
      columns(list, @column, level, mk_caption(cap, level, color))
    end

    def mk_caption(cap, level, color)
      return unless cap
      sep, col = SEPTBL[level]
      indent(level) +
        caption(cap, color || col, sep)
    end

    # Parent of Group
    class Section < Hashx
      attr_accessor :index
      def initialize(index: nil, valid: [], cap: nil, color: nil, level: nil)
        @index = index ? type?(index,Disp) : Disp.new(valid) 
        @caption = cap
        @color = color
        @level = level || -1
      end

      # add sub caption if sub is true
      def put_sec(id, cap = nil, color = nil)
        self[id] = Section.new(index: @index, cap: cap, color: color, level: @level + 1)
      end

      def put_grp(id, cap = nil, color = nil)
        self[id] = Group.new(index: @index, cap: cap, color: color, level: @level + 1)
      end

      def view
        ary = values.map(&:view).grep(/./)
        ary.unshift(@index.mk_caption(@caption, @level, @color)) if @caption
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
          sg.index = @index.update(sg.index)
        end
      end
    end

    # It has members of item
    class Group < Arrayx
      attr_accessor :index
      def initialize(index: nil, valid: [], cap: nil, color: nil, level: nil)
        @index = index ? type?(index,Disp) : Disp.new(valid) 
        @caption = cap
        @color = color
        @level = level || 0
      end

      # add item
      def put_item(k, v)
        push k
        @index.valid << k
        @index[k] = v
      end

      def view
        @index.view(select: self, level: @level, cap: @caption, color: @color)
      end

      def to_s
        view.to_s
      end
    end
  end

  if __FILE__ == $PROGRAM_NAME
    # Top level only
    grp0 = Disp::Group.new
    grp0.index.column = 3
    10.times { |i| grp0.put_item("x#{i}", "caption #{i}") }
    puts grp0.view
    puts
    # Three level groups
    grp1 = Disp::Section.new
    grp1.index.column = 3
    2.times do |i|
      s11 = grp1.put_sec("g#{i}", "Group#{i}", 1)
      3.times do |j|
        s12 = s11.put_grp("sg#{j}", "SubGroup#{j}")
        4.times do |k|
          cstr = '*' * rand(5)
          s12.put_item("#{i}-#{j}-#{k}", "caption#{i}-#{j}-#{k},#{cstr}")
        end
      end
    end
    puts grp1
    puts
    # Two level groups with item number
    grp2 = Disp::Section.new
    grp2.index.line_number = true
    3.times do |i|
      s21 = grp2.put_grp("g2#{i}", "Gp#{i}")
      3.times do |j|
        cstr = '*' * rand(5)
        s21.put_item("#{i}-#{j}", "cp#{i}-#{j},#{cstr}")
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
