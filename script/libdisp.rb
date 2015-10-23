#!/usr/bin/ruby
require 'libenumx'
# CIAX-XML
module CIAX
  # Display: Sortable Caption Database (Value is String)
  #    Shows visiual command list categorized by sub-group
  #    Holds valid command list in @select
  #    Used by Command and XmlDoc
  #    Attribute items : caption(text), separator(string), color(#),  column(#), line_number(t/f)

  class Display < Hashx
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
    def initialize(atrb = {:column => 2}, index = Index.new)
      @atrb = atrb
      @index = index
      @member = []
    end

    # generate sub level groups
    def ext_group(sep, color)
      @subat={}.update(@atrb).update( sep: sep, color: color )
      self
    end

    def add_group(id, caption)
      atrb={}.update(@subat).update(caption: caption)
      self[id] = Display.new(atrb,@index)
    end

    def put(k, v)
      @member << k
      @index.put(k,v)
    end

    def merge_group!(other)
      update(type?(other, Display))
      values.each {|g| g.index = @index.update(g.index) }
      reset!
    end

    def to_s
      if empty?
        view(@member & @index.select)
      else
        [ mk_caption, *values ].map{ |g| g.to_s }.grep(/./).join("\n")
      end
    end

    private
    
    def view(select)
      list = mk_list(select)
      return if list.empty?
      columns(list, @atrb[:column],mk_caption)
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
      Msg.caption(@atrb[:caption], @atrb[:color] || 6, @atrb[:sep])
    end
  end
  
  if __FILE__ == $PROGRAM_NAME
    atrb = { :caption => 'TEST', sep: '****', column: 3, color: 2}
    atrb[:line_number] = true
    dl = Display.new(atrb).ext_group('==', 6)
    5.times do |i|
      grp = dl.add_group("g#{i}", "Group#{i}")
      5.times do |j|
        istr = '+' * rand(5)
        cstr = '*' * rand(5)
        grp.put("#{i}-#{j},#{istr}", "caption#{i}-#{j},#{cstr}")
      end
    end
    puts dl.to_s
  end
end
