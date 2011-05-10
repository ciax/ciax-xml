#!/usr/bin/ruby
module ModSym
  def init_sym(doc,tbl)
    doc.find_each('symbol','table'){|e1|
      row=e1.to_h
      id=row.delete('id')
      tbl=row[:table]={}
      e1.each{|e2|
        if e2.text
          tbl[e2.text]=e2.to_h
        else
          tbl.default=e2.to_h
        end
      }
      tbl[id]=row
    }
    @v.msg{"Table:#{@sdb}"}
  end
end
