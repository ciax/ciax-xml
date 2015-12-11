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
    attr_reader :valid_keys, :line_number, :dummy_keys, :rank
    attr_accessor :num
    def initialize(caption: nil, color: nil, column: 2, line_number: false)
      @valid_keys = Arrayx.new
      @dummy_keys = Arrayx.new
      @caption = caption
      @color = color
      @column = Array.new(column) { [0, 0] }
      @line_number = line_number
      @num = -1
      @rank = 0
    end

    # New Item
    def put_item(k, v)
      self[k] = v
      @valid_keys << k
      self
    end

    def put_dummy(k, v)
      self[k] = v
      @dummy_keys << v
      self
    end

    # Data Handling
    def sort!
      @valid_keys.sort!
      self
    end

    def reset!
      @valid_keys.concat(keys-@dummy_keys).uniq!
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

    # Display part
    def to_s
      @num = -1
      view(keys, @caption, @color, @level).to_s
    end

    def mk_caption(caption, color: nil, level: nil)
      return unless caption
      level = level.to_i
      sep, col = SEPTBL[level]
      indent(level) + caption(caption, color || col, sep)
    end

    def view(select, caption, color, level)
      list = {}
      displist = (@valid_keys + @dummy_keys) & select
      displist.compact.sort.each do|id|
        name = @line_number ? "[#{@num += 1}](#{id})" : id
        list[name] = self[id] if self[id]
      end
      return if list.empty?
      cap = mk_caption(caption, color: color, level: level)
      columns(list, @column, level, cap)
    end

    # Making Sub Section/Group
    def ext_grp
      extend(Grouping).ext_grp
    end

    ####### Sub Group Handling #######
    module Grouping
      attr_reader :sub
      def ext_grp
        @sub = Section.new(self, caption: @caption, color: @color)
        self
      end

      def put_sec(id, cap, color = nil)
        sec = @sub.put_sec(id, cap, color)
        sec
      end

      def put_grp(id, cap, color = nil, rank = nil)
        grp = @sub.put_grp(id, cap, color, rank)
        grp
      end

      def to_s
        @num = -1
        @sub.view.to_s
      end

      def merge_sub(other)
        update(type?(other, Disp))
        _rec_merge_(other.sub)
        @sub.update(other.sub)
        reset!
        self
      end

      private

      def _rec_merge_(gr)
        type?(gr, Section).index = self
        gr.values.each do |sg|
          if sg.is_a? Section
            _rec_merge_(sg)
          else
            sg.index = self
          end
        end
      end
    end

    # Parent of Group
    class Section < Hashx
      attr_accessor :index, :level
      def initialize(index, caption: nil, color: nil, level: nil, rank: nil)
        @index = type?(index, Disp)
        @caption = caption
        @color = color
        @level = level.to_i
        @rank = rank.to_i
      end

      # add sub caption if sub is true
      def put_sec(id, cap, color = nil)
        _put_sub_(Section, id, cap, color)
      end

      def put_grp(id, cap, color = nil, rank = nil)
        _put_sub_(Group, id, cap, color, rank)
      end

      def view
        return '' if @rank > @index.rank
        ary = values.map(&:view).grep(/./)
        return '' if ary.empty?
        if @caption
          ary.unshift(@index.mk_caption(@caption, color: @color, level: @level))
        end
        ary.join("\n")
      end

      def to_s
        view.to_s
      end

      private

      def _put_sub_(mod, id, cap, color = nil, rank = nil)
        return self[id] if self[id]
        level = @level + 1
        self[id] = mod.new(@index, caption: cap, color: color, level: level, rank: rank)
      end
    end

    # Group has member of visible item
    class Group < Arrayx
      attr_accessor :index, :level
      def initialize(index, caption: nil, color: nil, level: nil, rank: nil)
        @index = type?(index, Disp)
        @caption = caption
        @color = color
        @level = level.to_i
        @rank = rank.to_i
      end

      # add item
      def put_item(k, v)
        push k
        @index.put_item(k, v).sub.view
        self
      end

      def put_dummy(k, v)
        push k
        @index.put_dummy(k, v).sub.view
        self
      end

      def view(select = self)
        return '' if @rank > @index.rank
        @index.view(select, @caption, @color, @level)
      end

      def to_s
        view.to_s
      end
    end
  end

  if __FILE__ == $PROGRAM_NAME
    # Top level only
    idx = Disp.new(column: 3, caption: 'top1')
    6.times { |i| idx.put_item("x#{i}", "caption #{i}") }
    puts idx
    puts '--'
    # Two level groups with item number
    cap2 = 'top2'
    idx1 = Disp.new(column: 3, caption: cap2, line_number: true).ext_grp
    3.times do |i|
      grp1 = idx1.put_grp("g1#{i}", "Gp#{i}")
      3.times do |j|
        cstr = '*' * rand(5)
        grp1.put_item("x#{i}-#{j}", "cap#{i}-#{j},#{cstr}")
      end
    end
    puts idx1
    puts '--'
    # Three level groups
    idx2 = Disp.new(column: 2, caption: 'top3', color: 4).ext_grp
    2.times do |i|
      sec = idx2.put_sec("g2#{i}", "Group#{i}")
      2.times do |j|
        grp2 = sec.put_grp("sg#{j}", "SubGroup#{j}")
        2.times do |k|
          cstr = '*' * rand(5)
          grp2.put_item("x#{i}-#{j}-#{k}", "caption#{i}-#{j}-#{k},#{cstr}")
        end
      end
    end
    puts idx2
    puts '--'
    # Merging groups
    cap2 << ' (merged with top3)'
    idx1.merge_sub(idx2)
    puts idx1
    puts '--'
    # Confirm merged index
    cap2 << ' (delete x0-0)'
    idx1.valid_keys.delete('x0-0')
    puts idx1
  end
end
