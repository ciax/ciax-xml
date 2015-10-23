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
    # Index of Display
    class Index < Hashx
      attr_reader :select
      def initialize
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
    end

    # Element is group
    attr_accessor :index
    def initialize(atrb = { column: 2 }, index = Index.new)
      @atrb = atrb
      @index = index
      @indent = atrb[:indent] || 0
      @member = []
    end

    # generate sub level groups
    def ext_group(sep, color)
      @subat = {}.update(@atrb)
      @subat.update(sep: sep, color: color, indent: @indent + 1)
      self
    end

    def add_group(id, caption)
      atrb = {}.update(@subat).update(caption: caption)
      self[id] = Display.new(atrb, @index)
    end

    def put(k, v)
      @member << k
      @index.put(k, v)
    end

    def merge_group!(other)
      update(type?(other, Display))
      @index.update(other.index)
      values.each { |g| g.index = @index }
      @index.reset!
      self
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

  if __FILE__ == $PROGRAM_NAME
    atrb = { caption: 'TEST', sep: '****', column: 3, color: 2 }
    atrb[:line_number] = true
    dl = Display.new(atrb).ext_group('==', 6)
    2.times do |i|
      grp = dl.add_group("g#{i}", "Group#{i}").ext_group('+', 4)
      3.times do |j|
        sg = grp.add_group("sg#{j}", "SubGroup#{j}")
        4.times do |k|
          cstr = '*' * rand(5)
          sg.put("#{i}-#{j}-#{k}", "caption#{i}-#{j}-#{k},#{cstr}")
        end
      end
    end
    atrb = { caption: 'TSET', sep: '%%%%', column: 2 }
    dl2 = Display.new(atrb).ext_group('++', 5)
    3.times do |i|
      grp2 = dl2.add_group("g2#{i}", "Gp#{i}")
      3.times do |j|
        cstr = '*' * rand(5)
        grp2.put("#{i}-#{j}", "cp#{i}-#{j},#{cstr}")
      end
    end
    dl.merge_group!(dl2)
    dl.index.select.delete('0-0')
    puts dl
  end
end
