#!/usr/bin/ruby
require "libwatdb"

module CIAX
  module App
    class Db < Db
      include Wat::Db
      def initialize
        super('adb')
      end

      private
      def doc_to_db(doc)
        db=Dbi[doc[:attr]]
        # Domains
        init_command(doc,db)
        init_stat(doc,db)
        init_watch(doc,db)
        db['app_id']=db['id']
        db
      end

      # Command Db
      def init_command(doc,db)
        adbc=doc[:domain]['commands']
        idx={}
        grp={}
        adbc.each{|e|
          Msg.abort("No group in adbc") unless e.name == 'group'
          gid=e.attr2item(grp)
          arc_command(e,idx,grp[gid])
        }
        db[:command]={:group => grp,:index => idx}
      end

      def arc_command(e,idx,grp)
        e.each{|e0|
          id=e0.attr2item(idx)
          item=idx[id]
          label=item['label']
          label=nil if /true|1/ === e0['hidden']
          (grp[:members]||={})[id]=label
          Repeat.new.each(e0){|e1,rep|
            par2item(e1,item) && next
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
              (item[:body]||=[]) << command
            end
          }
        }
        idx
      end

      # Status Db
      def init_stat(doc,db)
        adbs=doc[:domain]['status']
        mbr={'time'=>'TIMESTAMP','elapse'=>'ELAPSED'}
        grp={'gtime'=>{'caption' =>'','column' => 2,:members =>mbr}}
        idx=Hashx.new
        Repeat.new.each(adbs){|e,r|
          gid=e.attr2item(grp){|k,v| r.format(v)}
          rec_stat(e,idx,grp[gid],r)
        }
        db[:status]=adbs.to_h.update(:group => grp,:index => idx)
      end

      def rec_stat(e,idx,grp,rep)
        rep.each(e){|e0,r0|
          id=e0.attr2item(idx){|k,v| r0.format(v)}
          item=idx[id]
          (grp[:members]||={})[id]=item['label']
          item['type'] = e0.name
          item[:fields] = []
          r0.each(e0){|e1,r1|
            st={}
            st['sign']='true' if e1.name == 'sign'
            e1.to_h.each{|k,v|
              case k
              when 'bit','index'
                st[k] = r1.subst(v)
              else
                st[k] = v
              end
            }
            if i=st.delete('index')
              st['ref'] << ":#{i}"
            end
            e1.each{|e2|
              (st[:conv]||={})[e2.text]=e2['msg']
            }
            item[:fields] << st
          }
        }
        idx
      end
    end

    if __FILE__ == $0
      begin
        db=Db.new.get(ARGV.shift)
      rescue InvalidID
        Msg.usage("[id] (key) ..")
      end
      puts db.path(ARGV)
      exit
    end
  end
end
