#!/usr/bin/ruby
require 'libenumx'
# Display: Sortable Caption Database (Value is String)
#   New feature: can make recursive groups
#   Shows visiual command list categorized by sub-group
#   Holds valid command list in @valid_keys
#   Used by Command and XmlDoc
module CIAX
  # Index of Display (Used for validation, display)
  class Disp < Hashx
    # Grouping class (Used for setting db)
    #   Attributes (all level): column(#), line_number(t/f)
    #   Attributes (one level): color(#), level(#)
    #   Attributes (one group): caption(text)
    SEPTBL = [['****', 2], ['===', 6], ['--', 12], ['_', 14]]
    attr_reader :valid_keys, :sub, :column, :line_number
    def initialize(caption: nil, color: nil, column: 2, line_number: false)
      @valid_keys = Arrayx.new
      @caption = caption
      @color = color
      @column = column
      @line_number = line_number
      @sub = Dummy.new(self, caption: @caption, color: @color)
    end

    def put_sec
      _put_(Section)
    end

    # Add group with valid_keys
    def put_grp
      _put_(Group)
    end

    def put_item(k, v)
      @sub.put_item(k, v)
    end

    # For ver 1.9 or more
    def sort!
      @valid_keys.sort!
      self
    end

    # Reset @valid_keys(could be shared)
    def reset!
      @valid_keys.concat(keys).uniq!
      self
    end

    def valid?(id)
      @valid_keys.include?(id)
    end

    def clear
      @valid_keys.clear
      super
    end

    def delete(id)
      @valid_keys.delete(id)
      super
    end

    def to_s
      @sub.view
    end

    def mk_caption(caption, color: nil, level: nil)
      return unless caption
      level = level.to_i
      sep, col = SEPTBL[level]
      indent(level) +
        caption(caption, color || col, sep)
    end

    def merge_sub(other)
      update(other)
      osub = type?(other, Disp).sub
      if osub.is_a? Hash
        rec_merge_index(osub)
        put_sec.update(osub)
      end
      reset!
    end

    private

    def _put_(mod)
      return @sub if @sub.is_a? mod
      @sub = mod.new(self, caption: @caption, color: @color)
    end

    def rec_merge_index(gr)
      type?(gr, Hash).values.each do |sg|
        rec_merge_index(sg) if sg.is_a? Hash
        sg.index = self
      end
    end

    # Parent of Group
    class Section < Hashx
      attr_accessor :index, :level
      def initialize(index, caption: nil, color: nil, level: nil)
        @index = index
        @caption = caption
        @color = color
        @level = level.to_i
      end

      # add sub caption if sub is true
      def put_sec(id, cap, color = nil)
        _put_(Section, id, cap, color)
      end

      def put_grp(id, cap, color = nil)
        _put_(Group, id, cap, color)
      end

      def put_dmy(id, cap, color = nil)
        _put_(Group, id, cap, color)
      end

      def reset!
        @index.reset!
        self
      end

      def valid?(id)
        @index.valid?(id)
      end

      def view
        ary = values.map(&:view).grep(/./)
        if @caption
          ary.unshift(@index.mk_caption(@caption, color: @color, level: @level))
        end
        ary.join("\n")
      end

      def to_s
        view
      end

      private

      def _put_(mod, id, cap, color = nil)
        return self[id] if self[id]
        level = @level.to_i + 1
        self[id] = mod.new(@index, caption: cap, color: color, level: level)
      end
    end

    # It has members of item
    class Dummy < Arrayx
      attr_accessor :index, :level
      def initialize(index, caption: nil, color: nil, level: 0)
        @index = index
        @caption = caption
        @color = color
        @level = level
      end

      # add item
      def put_item(k, v)
        push k
        @index[k] = v
      end

      def view(select = self)
        list = {}
        select.compact.sort.each_with_index do|id, num|
          title = @index.line_number ? "[#{num}](#{id})" : id
          list[title] = @index[id]
        end
        return if list.empty?
        cap = @index.mk_caption(@caption, color: @color, level: @level)
        columns(list, @index.column, @level, cap)
      end

      def to_s
        view.to_s
      end
    end

    # With valid_keys
    class Group < Dummy
      # add item
      def put_item(k, v)
        @index.valid_keys << k
        super
      end

      def reset!
        @index.reset!
        self
      end

      def valid?(id)
        @index.valid?(id)
      end

      def view
        super(@index.valid_keys & self)
      end
    end
  end

  if __FILE__ == $PROGRAM_NAME
    # Top level only
    idx0 = Disp.new(column: 3, caption: 'top')
    10.times { |i| idx0.put_item("x#{i}", "caption #{i}") }
    puts idx0
    puts
    # Three level groups
    idx1 = Disp.new(column: 3, caption: 'top1', color: 4)
    grp1 = idx1.put_sec
    2.times do |i|
      s11 = grp1.put_sec("g#{i}", "Group#{i}")
      2.times do |j|
        s12 = s11.put_grp("sg#{j}", "SubGroup#{j}", 1)
        2.times do |k|
          cstr = '*' * rand(5)
          s12.put_item("#{i}-#{j}-#{k}", "caption#{i}-#{j}-#{k},#{cstr}")
        end
      end
    end
    puts idx1
    puts
    # Two level groups with item number
    idx2 = Disp.new(line_number: true, caption: 'top2')
    grp2 = idx2.put_sec
    3.times do |i|
      s21 = grp2.put_grp("g2#{i}", "Gp#{i}")
      3.times do |j|
        cstr = '*' * rand(5)
        s21.put_item("#{i}-#{j}", "cp#{i}-#{j},#{cstr}")
      end
    end
    puts idx2
    puts
    # Merging groups
    idx1.merge_sub(idx2)
    puts idx1
    puts
    # Confirm merged index
    idx1.valid_keys.delete('0-0')
    puts idx1
  end
end
