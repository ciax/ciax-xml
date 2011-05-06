#!/usr/bin/ruby
require "librepeat"
require "libverbose"

class ClsDb
  attr_reader :cdbc,:cdbs,:label,:symbol
  def initialize(doc)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
    @v=Verbose.new("cdb/#{doc['id']}",2)
    @cdbc={}
    @cdbs={}
    @label={}
    @symbol={}
    @rep=Repeat.new
    init_cmd(doc)
    init_stat(doc)
  end

  private
  def init_cmd(doc)
    doc['commands'].each{|e0|
      hash=e0.to_h
      id=hash.delete('id')
      hash[:statements]=[]
      @rep.each(e0){|e1|
        command=[e1['command']]
        e1.each{|e2|
          argv=e2.to_h
          argv['val'] = @rep.subst(e2.text)
          command << argv.freeze
        }
        hash[:statements] << command.freeze
      }
      @cdbc[id]=hash.freeze
      @v.msg{"CMD:Init[#{id}] #{hash}"}
    }
    self
  end

  def init_stat(doc)
    @rep.each(doc['status']){|e0|
      label={}
      e0.to_h.each{|k,v|
        label[k]=@rep.format(v)
      }
      id=label.delete('id')
      if symbol=label.delete('symbol')
        @symbol[id]=symbol
        @v.msg{"STAT:Init SYMBOL [#{id}] : #{symbol}"}
      end
      @label[id]=label
      @v.msg{"STAT:Init LABEL [#{id}] : #{label}"}
      fields=[]
      e0.each{|e1|
        st={:type => e1.name}
        e1.to_h.each{|k,v|
          st[k] = @rep.subst(v)
        }
        fields << st
      }
      @cdbs[id]=fields
      @v.msg{"STAT:Init VAL [#{id}] : #{fields}"}
    }
    self
  end
end
