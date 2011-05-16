#!/usr/bin/ruby
require "librepeat"
require "libverbose"
require "libxmldoc"
require "libsymdb"

class ClsDb < Hash
  attr_reader :status
  def initialize(cls)
    doc=XmlDoc.new('cdb',cls)
    @v=Verbose.new("cdb/#{doc['id']}",2)
    @doc=doc
    update(doc)
    @rep=Repeat.new
    @status={}
    self[:command]=init_command
    init_stat
    self[:symtbl]=SymDb.new(doc)
  end

  def init_command
    cdbc={}
    @doc.find_each('commands'){|e0|
      id=attr2db(e0.to_h,'c')
      list=[]
      @rep.each(e0){|e1|
        command=[e1['command']]
        e1.each{|e2|
          argv=e2.to_h
          argv['val'] = @rep.subst(e2.text)
          command << argv.freeze
        }
        list << command.freeze
      }
      cdbc[id]=list
      @v.msg{"CMD:[#{id}] #{list}"}
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
      id=attr2db(ldb)
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

  def attr2db(e,pre='')
    attr=Hash[e]
    id=attr.delete('id') || return
    attr.each{|k,v|
      str=pre+k
      sym=str.to_sym
      self[sym]={} unless key?(sym)
      self[sym][id]=v
      @v.msg{str.upcase+":[#{id}] : #{v}"}
    }
    id
  end
end
