#!/usr/bin/ruby
require 'libreclist'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Macro Record List
    class RecList
      def ext_view(visible = [])
        extend(View).ext_view(visible)
      end

      # Record Visible View
      module View
        def self.extended(obj)
          Msg.type?(obj, RecList)
        end

        def ext_view(visible)
          @visible = visible
          @id = @rec_arc.id
          self
        end

        def get_arc(num = 1)
          @visible.replace(@rec_arc.list.keys.sort.last(num.to_i))
          self
        end

        # Show Record(id = @page.current_rid) or List of them
        def to_v
          ___list_view
        end

        private

        def ___list_view
          page = ['<<< ' + colorize("Active Macros [#{@id}]", 2) + ' >>>']
          @visible.each_with_index do |id, idx|
            page << ___item_view(id, idx + 1)
          end
          page.join("\n")
        end

        def ___item_view(id, idx)
          rec = get(id)
          tim = Time.at(id[0..9].to_i).to_s
          title = "[#{idx}] #{id} (#{tim}) by #{___get_pcid(rec[:pid])}"
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

        def ___get_pcid(pid)
          return 'user' if pid == '0'
          @rec_arc.list[pid][:cid]
        end
      end

      if __FILE__ == $PROGRAM_NAME
        GetOpts.new('[num]') do |_opt, args|
          puts RecList.new.ext_view.get_arc(args.shift).to_v
        end
      end
    end
  end
end
