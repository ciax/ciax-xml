#!/usr/bin/ruby
require 'libconf'
# CIAX-XML
module CIAX
  # Display: Sortable Caption Database (Value is String)
  #    Shows visiual command list categorized by sub-group
  #    Holds valid command list in @select
  #    Used by Command and XmlDoc
  #    Attribute items : caption(text), color(#),  column(#), line_number(t/f)
  class SubDisp < Hashx
    attr_reader :cfg
    def initialize(cfg,atrb = {})
      @cfg= type?(cfg, Config).gen(self).update(atrb)
      @member = Arrayx.new
    end

    def put(k, v)
      @member.push(k)
      @cfg[:index].put(k, v)
    end
      
    def to_s
      if empty?
        view
      else
        values.map{ |g| g.to_s }.join("\n")
      end
    end

    # generate sub level groups
    def sub_atrb(sep, color, column = 2)
      @subat = { sep: sep, color: color, column: column}
      self
    end

    def add_sub(id, capt)
      @subat['caption'] = capt
      self[id] = SubDisp.new(@cfg,@subat)
    end

    private

    def view
      list = {}
      (@member & @cfg[:select]).compact.sort.each_with_index do|id, num|
        title = @cfg['line_number'] ? "[#{num}](#{id})" : id
        list[title] = @cfg[:index][id]
      end
      return if list.empty?
      cap = Msg.caption(@cfg['caption'], @cfg[:color] || 6, @cfg[:sep]) if @cfg['caption']
      columns(list, @cfg[:column],cap)
    end
  end
  
  class Display < SubDisp
    attr_reader :select, :sub
    def initialize(atrb = {})
      @cfg=Config.new(atrb)
      @cfg[:index] = self
      @select=@cfg[:select] = []
      @caption = caption(@cfg)
      @sub = Hashx.new
      @member = Arrayx.new
    end

    def put(k, v)
      @select << k
      super
    end

    def merge_group!(other)
      type?(other, Display).select.replace(@select)
      @sub.update(other.sub)
      update(other)
      reset!
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
      @sub.each_value { |s| s.clear }
      super
    end

    def delete(id)
      @select.delete(id)
      @sub.each_value { |s| s.delete(id) }
      super
    end

    def to_s
      if @sub.empty?
        view(keys)
      else
        @sub.values.map{ |g| g.to_s }.join("\n")
      end
    end

    def add_sub(id, capt)
      @subat['caption'] = capt
      @sub[id] = SubDisp.new(@cfg,@subat)
    end
  end

  if __FILE__ == $PROGRAM_NAME
    atrb = { 'caption' => 'TEST', sep: '****', column: 3, color: 2}
    atrb['line_number'] = true
    dl = Display.new(atrb).sub_atrb('==', 6)
    5.times do |i|
#      grp = dl.add_sub("g#{i}", "Group#{i}")
      #      5.times do |j|
      j = 0
        istr = '+' * rand(5)
        cstr = '*' * rand(5)
        dl.put("#{i}-#{j},#{istr}", "caption#{i}-#{j},#{cstr}")
      end
#    end
    puts dl.to_s
  end
end
