#!/usr/bin/ruby
require "libcircular"
require "librepeat"
require "libdb"

module ModAdbc
  def init_command(adb)
    hash=adb.to_h
    hash[:group]={}
    hash[:caption]={}
    hash[:parameter]={}
    hash[:select]={}
    hash[:label]={}
    arc_command(adb,hash,'g0')
  end

  def arc_command(e,hash,gid)
    e.each{|e0|
      case e0.name
      when 'group'
        id=e0.attr2db(hash)
        arc_command(e0,hash,id)
      else
        id=e0['id']
        (hash[:group][gid]||=[]) << id
        hash[:label][id]=e0['label'] unless /true|1/ === e0['hidden']
        Repeat.new.each(e0){|e1,rep|
          case e1.name
          when 'par'
            (hash[:parameter][id]||=[]) << e1.text
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
            (hash[:select][id]||=[]) << command.freeze
          end
        }
      end
    }
    hash
  end
end

module ModAdbs
  private
  def init_stat(sdb)
    hash=sdb.to_h
    hash[:label]={'g0' => '','time' => 'TIMESTAMP','elapse' => 'ELAPSED'}
    hash[:group]={'g0' => [['time','elapse']]}
    hash[:select]=rec_stat(sdb,hash,'g0',Repeat.new)
    hash
  end

  def rec_stat(e,hash,gid,rep)
    struct={}
    rep.each(e){|e0,r0|
      case e0.name
      when 'group'
        gid=e0.attr2db(hash){|k,v| r0.format(v)}
        hash[:group][gid]=[]
        struct.update(rec_stat(e0,hash,gid,r0))
      else
        id=e0.attr2db(hash){|k,v| k == 'format' ? v : r0.format(v)}
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
        hash[:group][gid] << id
      end
    }
    struct
  end
end

module ModWdb
  def init_watch(wdb)
    return [] unless wdb
    hash=wdb.to_h
    Repeat.new.each(wdb){|e0,r0|
      (hash[:label]||=[]) << (e0['label'] ? r0.format(e0['label']) : nil)
      bg={}
      e0.each{ |e1|
        case name=e1.name.to_sym
        when :block,:int,:exec
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
      [:stat,:exec,:int,:block].each{|k|
        (hash[k]||=[]) << bg[k]
      }
    }
    hash
  end
end


class AppDb < Db
  include ModAdbc
  include ModAdbs
  include ModWdb
  def initialize(app,nocache=nil)
    super('adb')
    cache(app,nocache){|doc|
      update(doc)
      delete('id')
      # Command DB
      self[:command]=init_command(doc.domain('commands'))
      # Status DB
      self[:status]=init_stat(doc.domain('status'))
      # Watch DB
      self[:watch]=init_watch(doc.domain('watch'))
    }
  end

  def cover_frm(nocache=nil)
    require "libfrmdb"
    frm=FrmDb.new(self['frm_type'],nocache)
    frm.deep_update(self)
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
