#!/usr/bin/ruby
require "librepeat"
require "libverbose"
require "libxmldoc"
require "libsymdb"

class ClsDb
  attr_reader :status,:table
  attr_accessor:symref,:label,:group
  def initialize(cls)
    doc=XmlDoc.new('cdb',cls)
    @v=Verbose.new("cdb/#{doc['id']}",2)
    @doc=doc
    @rep=Repeat.new
    @status={}
    @label={}
    @symref={}
    @group={}
    init_stat
    @table=SymDb.new(doc)
  end

  def [](key)
    @doc[key]
  end

  def command
    cdbc={}
    @doc.find_each('commands'){|e0|
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
      cdbc[id]=hash.freeze
      @v.msg{"CMD:[#{id}] #{hash}"}
    }
    cdbc
  end

  def watch
    return unless wdb=@doc.domain('watch')
    watch=wdb.to_h
    line=watch[:conditions]=[]
    @rep.each(wdb){|e0|
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
    watch
  end

  private
  def init_stat
    @rep.each(@doc.domain('status')){|e0|
      ldb={}
      e0.to_h.each{|k,v|
        ldb[k]=@rep.format(v)
      }
      id=ldb.delete('id')
      if symref=ldb.delete('symbol')
        @symref[id]=symref
        @v.msg{"SYMREF:[#{id}] : #{symref}"}
      end
      if label=ldb.delete('label')
        @label[id]=label
        @v.msg{"LABEL:[#{id}] : #{label}"}
      end
      if group=ldb.delete('group')
        @group[id]=group
        @v.msg{"GROUP:[#{id}] : #{group}"}
      end
      fields=[]
      e0.each{|e1|
        st={:type => e1.name}
        e1.to_h.each{|k,v|
          st[k] = @rep.subst(v)
        }
        fields << st
      }
      @status[id]=fields
      @v.msg{"STAT:[#{id}] : #{fields}"}
    }
    self
  end
end
