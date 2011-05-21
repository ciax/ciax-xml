#!/usr/bin/ruby
require "librepeat"
require "libverbose"
require "libxmldoc"
require "libsymdb"

class ClsDb < Hash
  attr_reader :command,:status,:symtbl
  def initialize(cls)
    doc=XmlDoc.new('cdb',cls)
    @v=Verbose.new("cdb/#{doc['id']}",2)
    @doc=doc
    update(doc)
    @rep=Repeat.new
    @command=init_command
    @v.msg{"Structure:command #{@command}"}
    @status=init_stat
    @v.msg{"Structure:status #{@status}"}
    @symtbl=SymDb.new(doc)
    @v.msg{"Structure:symtbl #{@symtbl}"}
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
  def init_command
    cdbc={:cdb => {}}
    @doc.find_each('commands'){|e0|
      id=e0.attr2db(cdbc)
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
      cdbc[:cdb][id]=list
      @v.msg{"COMMAND:[#{id}] #{list}"}
    }
    cdbc
  end

  def init_stat
    cdbs={:cdb => {}}
    @rep.each(@doc.domain('status')){|e0|
      id=e0.attr2db(cdbs){|v|@rep.format(v)}
      fields=[]
      e0.each{|e1|
        st={:type => e1.name}
        e1.to_h.each{|k,v|
          st[k] = @rep.subst(v)
        }
        fields << st
      }
      cdbs[:cdb][id]=fields
      @v.msg{"STATUS:[#{id}] : #{fields}"}
    }
    cdbs
  end
end
