#!/usr/bin/ruby
require "librepeat"
require "libdb"

module CIAX
  module App
    class Db < Db
      def initialize
        super('adb')
      end

      private
      def doc_to_db(doc)
        hash={}
        hash.update(doc)
        hash['id']=hash.delete('id')
        # Command DB
        cdb=hash[:command]=init_command(doc.domain('commands'))
        # Status DB
        hash[:status]=init_stat(doc.domain('status'))
        # Watch DB
        if doc.domain?('watch')
          hash[:watch]=init_watch(doc.domain('watch'),cdb)
        end
        hash
      end

      # Command Db
      def init_command(adbc)
        hash=adbc.to_h
        [:group,:parameter,:select,:label].each{|k|
          hash[k]={}
        }
        hash[:group]={}
        adbc.each{|e|
          Msg.abort("No group in adbc") unless e.name == 'group'
          gid=e.add_item(hash[:group])
          arc_command(e,hash,gid)
        }
        hash
      end

      def arc_command(e,hash,gid)
        e.each{|e0|
          id=e0['id']
          (hash[:group][gid][:members]||=[]) << id
          hash[:label][id]=e0['label'] unless /true|1/ === e0['hidden']
          Repeat.new.each(e0){|e1,rep|
            set_par(e1,id,hash) && next
            case e1.name
            when 'frmcmd'
              command=[e1['name']]
              e1.each{|e2|
                argv=e2.to_h
                argv['val'] = rep.subst(e2.text)
                if /\$/ !~ argv['val'] && fmt=argv.delete('format')
                  argv['val']=fmt % eval(argv['val'])
                end
                command << argv
              }
              (hash[:select][id]||=[]) << command
            end
          }
        }
        hash
      end

      # Status Db
      def init_stat(sdb)
        hash=sdb.to_h
        group=hash[:group]={}
        group['gtime']={'caption' =>'','column' => 2,:members =>['time','elapse']}
        hash[:label]={'time' => 'TIMESTAMP','elapse' => 'ELAPSED'}
        hash[:select]=rec_stat(sdb,hash,'gtime',Repeat.new)
        hash
      end

      def rec_stat(e,hash,gid,rep)
        struct={}
        rep.each(e){|e0,r0|
          case e0.name
          when 'group'
            gid=e0.add_item(hash[:group]){|k,v| r0.format(v)}
            struct.update(rec_stat(e0,hash,gid,r0))
          else
            id=e0.attr2db(hash){|k,v| r0.format(v)}
            struct[id]={'type' => e0.name, :fields => []}
            r0.each(e0){|e1,r1|
              st={}
              st['inv']='true' if e1.name == 'invert'
              e1.to_h.each{|k,v|
                case k
                when 'bit','index'
                  st[k] = r1.subst(v)
                else
                  st[k] = v
                end
              }
              if i=st.delete('index')
                st['ref']+=":#{i}"
              end
              struct[id][:fields] << st
            }
            (hash[:group][gid][:members]||=[]) << id
          end
        }
        struct
      end

      # Watch Db
      #structure of exec=[cond1,2,...]; cond=[cmd1,2,..]; cmd1=['str','arg1',..]
      def init_watch(wdb,cdb)
        return [] unless wdb
        hash=wdb.to_h
        [:label,:exec,:stat,:int,:block].each{|k| hash[k]={}}
        Repeat.new.each(wdb){|e0,r0|
          idx=r0.format(e0['id'])
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
              (hash[:block][idx]||=[]).concat(cdb[:group][e1['ref']][:members])
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
  end

  if __FILE__ == $0
    begin
      db=App::Db.new.set(ARGV.shift)
    rescue InvalidID
      Msg.usage("[id] (key) ..")
    end
    puts db.path(ARGV)
    exit
  end
end
