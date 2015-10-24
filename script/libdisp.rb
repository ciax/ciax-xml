#!/usr/bin/ruby
require 'libenumx'
# CIAX-XML
module CIAX
  # Display: Sortable Caption Database (Value is String)
  #   Shows visiual command list categorized by sub-group
  #   Holds valid command list in @select
  #   Used by Command and XmlDoc
  #   Attributes (global):  column(#), line_number(t/f)
  #   Attributes (shared in groups): sep(string), color(#)
  #   Attributes (each group): caption(text)
  class Display < Hashx
    attr_reader :select, :group
    def initialize(atrb = { column: 2})
      @group = Group.new(self, atrb)
      @select = []
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

    def merge_group!(other)
      update(type?(other, Display))
      @select.concat(other.select)
      @group.update(other.group)
      other.group.index = @index
      reset!
    end

    def to_s
      @group.to_s
    end

    # Element is group
    # Index of Display
    class Group < Hashx
      attr_accessor :index
      def initialize(index, atrb = { column: 2 })
        @atrb = atrb
        @index = type?(index, Display)
        @indent = atrb[:indent] || 0
        @member = []
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
        @member << k
        @index.put(k, v)
      end

      def to_s
        if empty?
          view(@member & @index.select)
        else
          [mk_caption, *values].map(&:to_s).grep(/./).join("\n")
        end
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
    end
  end

  if __FILE__ == $PROGRAM_NAME
    idx0 = Display.new(column: 3, caption: 'TEST', sep: '---')
    grp0 = idx0.group
    10.times{ |i| grp0.put("x#{i}","caption #{i}")}
    puts idx0
    idx1 = Display.new(column: 3, line_number: true)
    grp = idx1.group
    grp.init_sub('****', 2)
    2.times do |i|
      s1 = grp.add_sub("g#{i}", "Group#{i}").init_sub('==', 6)
      3.times do |j|
        s2 = s1.add_sub("sg#{j}", "SubGroup#{j}")
        4.times do |k|
          cstr = '*' * rand(5)
          s2.put("#{i}-#{j}-#{k}", "caption#{i}-#{j}-#{k},#{cstr}")
        end
      end
    end
    idx2 = Display.new(column: 2)
    gr2 = idx2.group
    gr2.init_sub('%%%%', 5)
    3.times do |i|
      s1 = gr2.add_sub("g2#{i}", "Gp#{i}")
      3.times do |j|
        cstr = '*' * rand(5)
        s1.put("#{i}-#{j}", "cp#{i}-#{j},#{cstr}")
      end
    end
    idx1.merge_group!(idx2)
    idx1.select.delete('0-0')
    puts idx1
  end
end
