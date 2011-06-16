#!/usr/bin/ruby
require "libcircular"
require "librepeat"
require "libdb"

class ClsDb < Db
  def initialize(cls)
    super('cdb',cls)
    @rep=Repeat.new
    @command=init_command
    @v.msg{
      @command.keys.map{|k| "Structure:command:#{k} #{@command[k]}"}
    }
    @status=init_stat
    @v.msg{
      @status.keys.map{|k| "Structure:status:#{k} #{@status[k]}"}
    }
  end

  def watch
    return [] unless wdb=@doc.domain('watch')
    update(wdb.to_h)
    line=[]
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
    @v.msg{"Structure:watch #{line}"}
    line
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
    @c=Circular.new(6)
    @cdbs={:cdb => {},:row => {}}
    rec_stat(@doc.domain('status'))
  end

  def rec_stat(e)
    @rep.each(e){|e0|
      if e0.name == 'row'
        @c.reset
        rec_stat(e0)
      else
        id=e0.attr2db(@cdbs){|v|@rep.format(v)}
        fields=[]
        e0.each{|e1|
          st={:type => e1.name}
          e1.to_h.each{|k,v|
            st[k] = @rep.subst(v)
          }
          fields << st
        }
        @cdbs[:cdb][id]=fields
        @cdbs[:row][id]=@c.next.row
        @v.msg{"STATUS:[#{id}] : #{fields}"}
      end
    }
    @cdbs
  end
end
