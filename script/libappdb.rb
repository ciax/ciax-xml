#!/usr/bin/ruby
require "libcircular"
require "librepeat"
require "libdb"

module App
  module Sdb
    private
    def init_stat(sdb)
      hash=sdb.to_h
      group=hash[:group]={}
      group[:select]={'gtime' => ['time','elapse']}
      group[:caption]={'gtime' => '' }
      group[:column]={'gtime' => 2 }
      hash[:label]={'gtime' => '','time' => 'TIMESTAMP','elapse' => 'ELAPSED'}
      hash[:select]=rec_stat(sdb,hash,'gtime',Repeat.new)
      hash
    end

    def rec_stat(e,hash,gid,rep)
      struct={}
      rep.each(e){|e0,r0|
        case e0.name
        when 'group'
          gid=e0.attr2db(hash[:group]){|k,v| r0.format(v)}
          hash[:group][:select][gid]=[]
          struct.update(rec_stat(e0,hash,gid,r0))
        else
          id=e0.attr2db(hash){|k,v| k == 'format' ? v : r0.format(v)}
          struct[id]=[]
          e0.each{|e1|
            st={'type' => e1.name}
            e1.to_h.each{|k,v|
              case k
              when 'bit','index'
                st[k] = r0.subst(v)
              else
                st[k] = v
              end
            }
            if i=st.delete('index')
              st['ref']+=":#{i}"
            end
            struct[id] << st
          }
          hash[:group][:select][gid] << id
        end
      }
      struct
    end
  end

  module Wdb
    #structure of exec=[cond1,2,...]; cond=[cmd1,2,..]; cmd1=['str','arg1',..]
    def init_watch(wdb,cdb)
      return [] unless wdb
      hash=wdb.to_h
      [:label,:exec,:stat,:int,:block].each{|k| hash[k]={}}
      Repeat.new.each(wdb){|e0,r0|
        idx=e0['id']
        hash[:label][idx]=(e0['label'] ? r0.format(e0['label']) : nil)
        e0.each{ |e1|
          case name=e1.name.to_sym
          when :block,:int,:exec
            cmd=[e1['name']]
            e1.each{|e2|
              cmd << r0.subst(e2.text)
            }
            (hash[name][idx]||=[]) << cmd
          when :block_grp
            cdb[:group][:select][e1['ref']].each{|grp|
              (hash[:block][idx]||=[]) << [grp]
            }
          else
            h=e1.to_h
            h.each_value{|v| v.replace(r0.format(v))}
            h['type']=e1.name
            (hash[:stat][idx]||=[]) << h
          end
        }
      }
      hash
    end
  end

  class Db < Db
    include Sdb
    include Wdb
    def initialize(id)
      super('adb',id){|doc|
        hash={}
        hash.update(doc)
        hash.delete('id')
        hash['app_ver']=hash.delete('version')
        hash['app_label']=hash.delete('label')
        # Command DB
        cdb=hash[:command]=init_command(doc.domain('commands'))
        # Status DB
        hash[:status]=init_stat(doc.domain('status'))
        # Watch DB
        if doc.domain?('watch')
          hash[:watch]=init_watch(doc.domain('watch'),cdb)
        end
        hash
      }
    end

    def cover_frm
      require "libfrmdb"
      cover(Frm::Db.new(self['frm_type']))
    end

    private
    # Command Db
    def init_command(adb)
      hash=adb.to_h
      [:group,:parameter,:select,:label].each{|k|
        hash[k]={}
      }
      hash[:group]={:caption =>{},:select =>{}}
      arc_command(adb,hash,'g0')
    end

    def arc_command(e,hash,gid)
      e.each{|e0|
        case e0.name
        when 'group'
          id=e0.attr2db(hash[:group])
          arc_command(e0,hash,id)
        else
          id=e0['id']
          (hash[:group][:select][gid]||=[]) << id
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
end

if __FILE__ == $0
  require "optparse"
  begin
    opt=ARGV.getopts("f")
    db=App::Db.new(ARGV.shift)
  rescue SelectID
    Msg.usage("(-f) [id] (key) ..","-f:make fdb")
    Msg.exit
  end
  db=db.cover_frm if opt["f"]
  puts db.path(ARGV)
  exit
end
