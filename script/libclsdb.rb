#!/usr/bin/ruby
require "librepeat"
require "libverbose"
require "libxmldoc"

class ClsDb
  attr_reader :cdbc,:cdbs,:label,:symbol,:watch
  def initialize(cls)
    doc=XmlDoc.new('cdb',cls,"==== Device Classes ====")
    @v=Verbose.new("cdb/#{doc['id']}",2)
    @cdbc={}
    @cdbs={}
    @label={}
    @symbol={}
    @watch=doc['watch'].to_h
    @rep=Repeat.new
    init_cmd(doc)
    init_stat(doc)
    init_watch(doc['watch'])
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
      @v.msg{"CMD:[#{id}] #{hash}"}
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
        @v.msg{"SYMBOL:[#{id}] : #{symbol}"}
      end
      @label[id]=label
      @v.msg{"LABEL:[#{id}] : #{label}"}
      fields=[]
      e0.each{|e1|
        st={:type => e1.name}
        e1.to_h.each{|k,v|
          st[k] = @rep.subst(v)
        }
        fields << st
      }
      @cdbs[id]=fields
      @v.msg{"STAT:[#{id}] : #{fields}"}
    }
    self
  end

  def init_watch(e)
    line=@watch[:conditions]=[]
    @rep.each(e){|e0|
      bg={:type => e0.name}
      e0.to_h.each{|a,v|
        bg[a]=@rep.format(v)
      }
      @v.msg(1){"WATCH:#{bg[:type]}:#{bg['label']}"}
      e0.each{ |e1|
        ssn=[e1['command']]
        e1.each{|e2|
          ssn << @rep.subst(e2.text)
        }
        bg[e1.name]=[] unless Array === bg[e1.name]
        bg[e1.name] << ssn.freeze
        @v.msg{"WATCH:"+e1.name.capitalize+":#{ssn}"}
      }
      bg[:var]={}
      if e0.name == 'periodic'
        bg[:var][:current]=Time.now
        bg[:var][:next]=Time.at(0)
      end
      @v.msg(-1){"WATCH:#{bg[:type]}"}
      line << bg.freeze
    }
    self
  end
end
