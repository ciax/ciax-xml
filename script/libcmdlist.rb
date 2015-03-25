#!/usr/bin/ruby
require "libmsg"
module CIAX
  # Sortable Hash of title
  # Used by Command and XmlDoc
  # Attribute items: caption(text), color(#), column(#), show_all(t/f), line_number(t/f)
  class CmdList < Hash
    attr_reader :select
    def initialize(attr,select=[])
      @attr=Msg.type?(attr,Hash)
      @select=Msg.type?(select,Array)
      @dummy=[]
    end

    def []=(k,v)
      @select << k
      super
    end

    def dummy(k,v)
      @dummy << k
      store(k,v)
    end

    def update(h)
      @select.concat h.keys
      super
    end

    # Reset @select(could be shared)
    def reset!
      @select.concat(keys).uniq!
      self
    end

    # For ver 1.9 or more
    def sort!
      @select.sort!
      self
    end

    def to_s
      cap=@attr["caption"]
      cap= '==== '+Msg.color(cap,(@attr["color"]||6).to_i)+' ====' if cap
      page=[cap]
      num=0
      ((@select+@dummy) & keys).each_slice((@attr["column"]||1).to_i){|a|
        l=a.map{|key|
          next unless self[key]
          title=@attr["line_number"] ? "[#{num+=1}](#{key})" : key
          Msg.item(title,self[key])
        }.compact
        page << l.join("\t") unless l.empty?
      }
      if @attr["show_all"] || page.size > 1
        page.compact.join("\n")
      else
        ''
      end
    end
  end

  class CmdGrp
    def initialize(select=[])
      @select=[]
      @groups=[]
    end

    def add_grp(attr)
      @groups.push(CmdList.new(attr,@select)).last
    end

    def [](id)
      @groups.map{|l| l[id]}.compact.first
    end

    def key?(id)
      @select.include?(id)
    end

    def to_s
      @groups.map{|l| l.to_s}.grep(/./).join("\n")
    end
  end
end
