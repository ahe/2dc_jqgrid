require '2dc_jqgrid'

begin
  Jqgrid.jrails_present = true
  require 'jrails'
rescue Exception
  Jqgrid.jrails_present = false
end

Array.send :include, JqgridJson
ActionView::Base.send :include, Jqgrid