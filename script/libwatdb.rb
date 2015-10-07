#!/usr/bin/ruby
require 'librepeat'
require 'libdb'

module CIAX
  module Wat
    module Db
      # Wat Db
      # structure of exec=[cond1,2,...]; cond=[args1,2,..]; args1=['cmd','par1',..]
      def init_watch(doc, db)
        return {} unless doc[:domain].key?('watch')
        wdb = doc[:domain]['watch']
        cmdgrp = db[:command][:group]
        idx = {}
        regular = { 'period' => 300, :exec => [] }
        Repeat.new.each(wdb) do|e0, r0|
          case e0.name
          when 'regular'
            regular.update(e0.to_h)
            e0.each do|e1|
              args = [e1['name']]
              e1.each do|e2|
                args << e2.text
              end
              regular[:exec] << args
            end
          when 'event'
            id = e0.attr2item(idx) { |_, v| r0.formatting(v) }
            item = idx[id]
            cnd = item[:cnd] = []
            act = item[:act] = {}
            e0.each do|e1|
              case name = e1.name.to_sym
              when :block, :int, :exec
                args = [e1['name']]
                e1.each do|e2|
                  args << r0.subst(e2.text)
                end
                (act[name] ||= []) << args
              when :block_grp
                blk = (act[:block] ||= [])
                cmdgrp[e1['ref']][:members].each { |k| blk << [k] }
              else
                h = e1.to_h
                h.each_value { |v| v.replace(r0.formatting(v)) }
                h['type'] = e1.name
                cnd << h
              end
            end
          end
        end
        regular[:exec] << ['upd'] if regular[:exec].empty?
        db[:watch] = wdb.to_h.update(index: idx, regular: regular)
      end

      private
      def get_cmd
        args = [e1['name']]
        e1.each do|e2|
          args << r0.subst(e2.text)
        end
        (act[name] ||= []) << args
      end
    end
  end
end
