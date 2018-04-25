#!/usr/bin/ruby
require 'libreclist'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Macro Record List
    class RecList
      def ext_view(init_num = 0)
        extend(View).ext_view(init_num.to_i)
      end

      # Record List View
      module View
        def self.extended(obj)
          Msg.type?(obj, RecList)
        end

        def ext_view(init_num)
          @arc_list.keys.sort.last(init_num).each { |rid| get(rid) }
          self
        end

        # Show Record(id = @page.current_rid) or List of them
        def to_v
          ___list_view
        end

        private

        def ___list_view
          page = ['<<< ' + colorize("Active Macros [#{@id}]", 2) + ' >>>']
          @vis_list.keys.each_with_index do |id, idx|
            page << ___item_view(id, idx + 1)
          end
          page.join("\n")
        end

        def ___item_view(id, idx)
          rec = @vis_list[id]
          tim = Time.at(id[0..9].to_i).to_s
          title = "[#{idx}] #{id} (#{tim}) by #{___get_pcid(id)}"
          msg = "#{rec[:cid]} #{rec.step_num}"
          msg << ___result_view(rec)
          itemize(title, msg)
        end

        def ___result_view(rec)
          if rec[:status] == 'end'
            "(#{rec[:result]})"
          else
            msg = "(#{rec[:status]})"
            msg << optlist(rec[:option]) if rec.last
            msg
          end
        end

        def ___get_pcid(id)
          rec = @arc_list[id]
          pid = rec[:pid]
          return 'user' if pid == '0'
          @arc_list[pid][:cid]
        end
      end

      if __FILE__ == $PROGRAM_NAME
        GetOpts.new('[num]') do |_opt, args|
          puts RecList.new.ext_view(*args).to_v
        end
      end
    end
  end
end
