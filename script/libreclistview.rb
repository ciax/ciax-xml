#!/usr/bin/ruby
require 'libreclist'
# CIAX-XML
module CIAX
  # Macro Layer
  module Mcr
    # Macro Record List
    class RecList
      def ext_view(id, init_num = 1)
        extend(View).ext_view(id, init_num.to_i)
      end

      # Record List View
      module View
        def self.extended(obj)
          Msg.type?(obj, RecList)
        end

        def ext_view(id, init_num)
          @ciddb = { '0' => 'user' }
          @id = id
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
          @act_list.keys.each_with_index do |id, idx|
            page << ___item_view(id, idx + 1)
          end
          page.join("\n")
        end

        def ___item_view(id, idx)
          rec = @act_list[id]
          tim = Time.at(id[0..9].to_i).to_s
          title = "[#{idx}] #{id} (#{tim}) by #{@ciddb[rec[:pid]]}"
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
      end

      if __FILE__ == $PROGRAM_NAME
        GetOpts.new('[proj] [num]') do |_opt, args|
          puts RecList.new.ext_view(*args).to_v
        end
      end
    end
  end
end
