#!/usr/bin/ruby
require "libcircular"
require "librepeat"
require "libdb"

class AppDb < Db
  def initialize(app,nocache=nil)
    super('adb')
    cache(app,nocache){|doc|
      update(doc)
      delete('id')
      # Command DB
      cdb=doc.domain('commands')
      cmd=self[:command]=cdb.to_h
      init_command(cdb,cmd)
      # Status DB
      sdb=doc.domain('status')
      stat=self[:status]=sdb.to_h
      stat[:select]=init_stat(sdb,stat,Repeat.new)
      # Watch DB
      wdb=doc.domain('watch')
      update(wdb.to_h)
      self[:watch]=init_watch(wdb)
    }
  end

  def cover_frm(nocache=nil)
    require "libfrmdb"
    frm=FrmDb.new(self['frm_type'],nocache)
    frm.deep_update(self)
  end

  private
  def init_command(adb,hash)
    adb.each{|e0|
      id=e0.attr2db(hash)
      Repeat.new.each(e0){|e1,rep|
        case e1.name
        when 'par'
          ((hash[:parameter]||={})[id]||=[]) << e1.text
        when 'frmcmd'
          command=[e1['name']]
          e1.each{|e2|
            argv=e2.to_h
            argv['val'] = rep.subst(e2.text)
            if /\$/ !~ argv['val'] && fmt=argv.delete('format')
              argv['val']=fmt % eval(argv['val'])
            end
            command << argv.freeze
          }
          ((hash[:select]||={})[id]||=[]) << command.freeze
        end
      }
      @v.msg{"COMMAND:[#{id}]"}
    }
    self
  end

  def init_stat(e,stat,rep)
    struct={}
    label=(stat[:label]||={'time' => 'TIMESTAMP','elapse' => 'PAST UPD'})
    group=(stat[:group]||=[[['time','elapse']]])
    rep.each(e){|e0,r0|
      if e0.name == 'group'
        id=e0.attr2db(stat){|k,v| r0.format(v)}
        group << [id]
        struct.update(init_stat(e0,stat,r0))
      elsif e0.name == 'row'
        group << [] if group.size < 2
        group.last << []
        struct.update(init_stat(e0,stat,r0))
      else
        id=e0.attr2db(stat){|k,v| k == 'format' ? v : r0.format(v)}
        struct[id]=[]
        e0.each{|e1|
          st={'type' => e1.name}
          e1.to_h.each{|k,v|
            case k
            when 'bit','index'
              st[k] = eval(r0.subst(v)).to_s
            else
              st[k] = v
            end
          }
          if i=st.delete('index')
            st['ref']+=":#{i}"
          end
          struct[id] << st
        }
        group.last.last << id
        @v.msg{"STATUS:[#{id}]"}
      end
    }
    struct
  end

  def init_watch(wdb)
    return [] unless wdb
    i=0
    hash={}
    Repeat.new.each(wdb){|e0,r0|
      ['label','block'].each{|k|
        (hash[k.to_sym]||=[]) << (e0[k] ? r0.format(e0[k]) : nil)
      }
      @v.msg(1){"WATCH:#{hash[:onchange]}:#{hash[:label]}"}
      bg={}
      e0.each{ |e1|
        case name=e1.name.to_sym
        when :exec
          cmd=[e1['name']]
          e1.each{|e2|
            cmd << r0.subst(e2.text)
          }
          (bg[name]||=[]) << cmd
        else
          h=e1.to_h
          h.each_value{|v| v.replace(r0.format(v))}
          h['type']=e1.name
          (bg[:stat]||=[]) << h
        end
      }
      [:stat,:exec].each{|k|
        (hash[k]||=[]) << bg[k]
      }
      i+=1
    }
    @v.msg{"Structure:watch #{hash}"}
    hash
  end
end

if __FILE__ == $0
  begin
    adb=AppDb.new(ARGV.shift,true)
  rescue SelectID
    warn "USAGE: #{$0} [id] (key) .."
    Msg.exit
  end
  puts adb.path(ARGV)
end
