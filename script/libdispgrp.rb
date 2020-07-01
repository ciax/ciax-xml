#!/usr/bin/env ruby
require 'libdisp'
# Display with Group:
#   New feature: can make recursive groups
#   Shows visiual command list categorized by sub-group
module CIAX
  # Index of Display (Used for validation, display)
  module Disp
    # Making Sub Section/Group
    class Index
      def ext_grp
        extend(Grouping).ext_grp
      end
    end

    ####### Sub Group Handling #######
    module Grouping
      attr_reader :sub
      def ext_grp
        @sub = Section.new(self, caption: @caption, color: @color)
        self
      end

      def add_sec(id, cap, color = nil)
        @sub.add_sec(id, cap, color)
      end

      def add_grp(id, cap, color = nil, rank = nil)
        @sub.add_grp(id, cap, color, rank)
      end

      def to_v
        @num = -1
        res = @sub.view.to_s
        warning('SubGroup [%s] is empty', @caption) if res.empty?
        res
      end

      def merge_sub(other)
        update(type?(other, Index))
        @valid_keys.concat(other.valid_keys)
        __rec_merge(other.sub)
        @sub.update(other.sub)
        self
      end

      private

      def __rec_merge(gr)
        type?(gr, Section).index = self
        gr.each_value do |sg|
          if sg.is_a? Section
            __rec_merge(sg)
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
        @index = type?(index, Index)
        @caption = caption
        @color = color
        @level = level.to_i
        @rank = rank.to_i
      end

      # add sub caption if sub is true
      def add_sec(id, cap, color = nil)
        __add_sub(Section, id, cap, color)
      end

      def add_grp(id, cap, color = nil, rank = nil)
        __add_sub(Group, id, cap, color, rank)
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

      def to_v
        view.to_s
      end

      private

      def __add_sub(mod, id, cap, color = nil, rank = nil)
        return self[id] if self[id]
        level = @level + 1
        atrb = { caption: cap, color: color, level: level, rank: rank }
        self[id] = mod.new(@index, atrb)
      end
    end

    # Group has member of visible item
    class Group < Arrayx
      attr_accessor :index, :level
      def initialize(index, caption: nil, color: nil, level: nil, rank: nil)
        @index = type?(index, Index)
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
        cap = @caption
        cap += "(#{@rank})" if @rank > 0
        @index.view(select, cap, @color, @level)
      end

      def to_v
        view.to_s
      end
    end

    if $PROGRAM_NAME == __FILE__
      # Two level groups with item number
      cap2 = 'top2'
      idx1 = Index.new(column: 3, caption: cap2, line_number: true).ext_grp
      3.times do |i|
        grp1 = idx1.add_grp("g1#{i}", "Gp#{i}")
        3.times do |j|
          cstr = '*' * rand(5)
          grp1.put_item("x#{i}-#{j}", "cap#{i}-#{j},#{cstr}")
        end
      end
      puts idx1
      puts '--'
      # Three level groups
      idx2 = Index.new(column: 2, caption: 'top3', color: 4).ext_grp
      2.times do |i|
        sec = idx2.add_sec("g2#{i}", "Group#{i}")
        2.times do |j|
          grp2 = sec.add_grp("sg#{j}", "SubGroup#{j}")
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
end
