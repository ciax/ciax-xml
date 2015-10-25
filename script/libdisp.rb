#!/usr/bin/ruby
require 'libenumx'
# Display: Sortable Caption Database (Value is String)
#   Shows visiual command list categorized by sub-group
#   Holds valid command list in @select
#   Used by Command and XmlDoc
module CIAX
  # Index of Display (Used for validation, display)
  class Display < Hashx
    attr_reader :select, :group
    def initialize(atrb = { column: 2}, select = [])
      @group = Group.new(self, atrb)
      @select = select
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

    def merge_group!(other)
      @group.merge_sub(other.group)
      update(type?(other, Display))
      reset!
    end

    def to_s
      @group.to_s
    end

    # Grouping class (Used for setting db)
    #   Attributes (all level): column(#), line_number(t/f)
    #   Attributes (one level): sep(string), color(#), indent(#)
    #   Attributes (one group): caption(text), members(array)
    class Group < Hashx
      attr_accessor :index
      def initialize(index, atrb = { column: 2 })
        @atrb = atrb
        @index = type?(index, Display)
        @indent = atrb[:indent] || 0
        @members = atrb[:members] || []
      end

      # generate sub level groups
      def init_sub(sep, color)
        @subat = {}.update(@atrb)
        inc = @subat.key?(:caption) ? 1 : 0
        @subat.update(sep: sep, color: color, indent: @indent + inc)
        self
      end

      def add_sub(id, caption)
        atrb = {}.update(@subat).update(caption: caption)
        atrb[:gid] = atrb.key?(:gid) ? atrb[:gid] + ':' + id : id
        self[atrb[:gid]] = Group.new(@index, atrb)
      end

      def put(k, v)
        @members << k
        @index.select << k
        @index[k]=v
      end

      def to_s
        if empty?
          view(@members & @index.select)
        else
          [mk_caption, *values].map(&:to_s).grep(/./).join("\n")
        end
      end

      def merge_sub(other)
        rec_merge_index(other)
        update(other)
      end

      private

      def view(select)
        list = mk_list(select)
        return if list.empty?
        columns(list, @atrb[:column], @indent, mk_caption)
      end

      def mk_list(select)
        list = {}
        select.compact.sort.each_with_index do|id, num|
          title = @atrb[:line_number] ? "[#{num}](#{id})" : id
          list[title] = @index[id]
        end
        list
      end

      def mk_caption
        return unless @atrb[:caption]
        indent(@indent) +
          caption(@atrb[:caption], @atrb[:color] || 6, @atrb[:sep])
      end

      def rec_merge_index(gr)
        type?(gr, Group).values.each do |sg|
          rec_merge_index(sg)
        end
        gr.index = @index
      end
    end
  end

  if __FILE__ == $PROGRAM_NAME
    # Top level only
    idx0 = Display.new(column: 3, caption: 'Top Level', sep: '---')
    grp0 = idx0.group
    10.times{ |i| grp0.put("x#{i}","caption #{i}")}
    puts idx0
    puts
    # Three level groups
    idx1 = Display.new(column: 3)
    grp1 = idx1.group.init_sub('****', 2)
    2.times do |i|
      s11 = grp1.add_sub("g#{i}", "Group#{i}").init_sub('==', 6)
      3.times do |j|
        s12 = s11.add_sub("sg#{j}", "SubGroup#{j}")
        4.times do |k|
          cstr = '*' * rand(5)
          s12.put("#{i}-#{j}-#{k}", "caption#{i}-#{j}-#{k},#{cstr}")
        end
      end
    end
    puts idx1
    puts
    # Two level groups with item number
    idx2 = Display.new(column: 2, line_number: true)
    grp2 = idx2.group.init_sub('%%%%', 5)
    3.times do |i|
      s21 = grp2.add_sub("g2#{i}", "Gp#{i}")
      3.times do |j|
        cstr = '*' * rand(5)
        s21.put("#{i}-#{j}", "cp#{i}-#{j},#{cstr}")
      end
    end
    puts idx2
    puts
    # Merging groups
    idx1.merge_group!(idx2)

    # Confirm merged index
    idx1.select.delete('0-0')
    puts idx1
  end
end
