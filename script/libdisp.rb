#!/usr/bin/ruby
require 'libenumx'
# CIAX-XML
module CIAX
  # Display: Sortable Caption Database (Value is String)
  #    Shows visiual command list categorized by sub-group
  #    Holds valid command list in @select
  #    Used by Command and XmlDoc
  #    Attribute items : caption(text), separator(string), color(#),  column(#), line_number(t/f)

  # Making View module
  module DispView
    def view(index,select)
      list = {}
      select.compact.sort.each_with_index do|id, num|
        title = @atrb[:line_number] ? "[#{num}](#{id})" : id
        list[title] = index[id]
      end
      return if list.empty?
      columns(list, @atrb[:column],mk_caption)
    end

    def mk_caption
      return unless @atrb[:caption]
      Msg.caption(@atrb[:caption], @atrb[:color] || 6, @atrb[:sep])
    end
  end

  # Making Sub Group module
  module DispGroup
    attr_reader :sub
    def ext_group(sep, color)
      @sub = Hashx.new
      @subat={}.update(@atrb).update( sep: sep, color: color )
      self
    end

    def add_group(id, caption)
      atrb={}.update(@subat).update(caption: caption)
      @sub[id] = DispMember.new(self,atrb)
    end

    def merge_group!(other)
      @sub.update(other.sub)
      super
    end

    def delete(id)
      @sub.each_value { |s| s.delete(id) }
      super
    end

    def to_s
      [ mk_caption, *@sub.values ].map{ |g| g.to_s }.grep(/./).join("\n")
    end
  end

  # Main class
  class Display < Hashx
    include DispView
    attr_accessor :select
    def initialize(atrb = {:column => 2})
      @atrb = atrb
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
      type?(other, Display).select.replace(@select)
      update(other)
      reset!
    end

    def to_s
      view(self,@select)
    end

    # generate sub level groups
    def ext_group(sep, color)
      extend(DispGroup).ext_group(sep, color)
    end
  end

  # Group class
  class DispMember < Arrayx
    include DispView
    def initialize(index,atrb)
      @index = index
      @atrb = atrb
    end

    def put(k,v)
      push(k)
      @index.put(k,v)
    end

    def to_s
      view(@index,self & @index.select)
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
