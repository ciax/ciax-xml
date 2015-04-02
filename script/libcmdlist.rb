#!/usr/bin/ruby
require "libenumx"
module CIAX
  # Sortable Caption Database (Value is String)
  # Including key list (@select) for display chosen items.
  # Including key list (@dummy) for always display.
  # Used by Command and XmlDoc
  # Attribute items: caption(text), color(#), column(#), line_number(t/f)
  class CmdGrp < Hashx
    attr_accessor :select
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

    def view(vx=nil,kx=3)
      return '' if (t=list_table).empty?
      caption+Msg.columns(t,(@attr["column"]||1).to_i,vx,kx)
    end

    def vmax # max text length
      list_table.values.map{|v| v.size }.max||0
    end

    def kmax
      list_table.keys.map{|k| k.size }.max||0
    end

    private
    def caption
      @attr["caption"] ? " == "+Msg.color(@attr["caption"],(@attr["color"]||6).to_i)+" ==\n" : ""
    end

    def list_table
      hash={}
      ((@select+@dummy) & keys).each{|key|
        next unless self[key]
        title=@attr["line_number"] ? "[#{num+=1}](#{key})" : key
        hash[title]=self[key]
      }
      hash
    end
  end

  class CmdList < Arrayx
    def initialize(attr={},select=[])
      @attr=Msg.type?(attr,Hash)
      @select=select
    end

    def add_grp(attr={})
      push(CmdGrp.new(attr,@select)).last
    end

    def select=(select)
      @select=Msg.type?(select,Array)
      each{|cg| cg.select=select}
      select
    end

    def reset!
      each{|cg| cg.reset!}
      self
    end

    def key?(id)
      @select.include?(id)
    end

    def to_s
      if (b=body).empty?
        ''
      else
        (caption+b).join("\n")
      end
    end

    private
    def caption
      page=[]
      if cap=@attr["caption"]
       page << "**** "+Msg.color(cap,(@attr["color"]||6).to_i)+" ****"
      end
      page
    end

    def body
      vmax=map{|cg| cg.vmax }.max
      kmax=map{|cg| cg.kmax }.max
      map{|cg| cg.view(vmax,kmax)}.grep(/./)
    end
  end
end
