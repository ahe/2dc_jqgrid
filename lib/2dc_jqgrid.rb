module ActionView

  module Helpers
    
    def jqgrid_stylesheets
      css = capture { stylesheet_link_tag 'jqgrid/ui.all' }
      css << capture { stylesheet_link_tag 'jqgrid/ui.jqgrid' }    
    end

    def jqgrid_javascripts
      js = capture { javascript_include_tag 'jqgrid/jquery' }
      js << capture { javascript_include_tag 'jqgrid/jquery.ui.all' }
      js << capture { javascript_include_tag 'jqgrid/jquery.layout' }
      js << capture { javascript_include_tag 'jqgrid/jqModal' }
      js << capture { javascript_include_tag 'jqgrid/jquery.jqGrid' }
    end

    def jqgrid(title, id, action, columns = {}, options = {})

      # Default options
      options[:rows_per_page] = "10" if options[:rows_per_page].blank?
      options[:sort_column] = "id" if options[:sort_column].blank?
      options[:sort_order] = "asc" if options[:sort_order].blank?

      options[:add] = (options[:add].blank?) ? "false" : options[:add].to_s    
      options[:delete] = (options[:delete].blank?) ? "false" : options[:delete].to_s
      options[:inline_edit] = (options[:inline_edit].blank?) ? "false" : options[:inline_edit].to_s
      edit_button = (options[:edit] == true && options[:inline_edit] == "false") ? "true" : "false"      

      # Generate columns data
      col_names = "[" # Labels
      col_model = "[" # Options
      columns.each do |c|
        col_names << "'#{c[:label]}',"
        col_model << "{name:'#{c[:field]}', index:'#{c[:field]}',#{get_attributes(c)}},"
      end
      col_names.chop! << "]"
      col_model.chop! << "]"

      # Enable multi-selection (checkboxes)
      multiselect = ""
      if options[:multi_selection]
        multiselect = %Q/multiselect: true,/
        multihandler = %Q/
          jQuery("##{id}_select_button").click( function() { 
            var s; s = jQuery("##{id}").getGridParam('selarrrow'); 
            #{options[:selection_handler]}(s); 
          });/
      end

      # Enable master-details
      masterdetails = ""
      if options[:master_details]
        masterdetails = %Q/
          onSelectRow: function(ids) { 
            if(ids == null) { 
              ids=0; 
              if(jQuery("##{id}_details").getGridParam('records') >0 ) 
              { 
                jQuery("##{id}_details").setGridParam({url:"#{options[:details_url]}?q=1&id="+ids,page:1})
                .setCaption("#{options[:details_caption]}: "+ids)
                .trigger('reloadGrid'); 
              } 
            } 
            else 
            { 
              jQuery("##{id}_details").setGridParam({url:"#{options[:details_url]}?q=1&id="+ids,page:1})
              .setCaption("#{options[:details_caption]} : "+ids)
              .trigger('reloadGrid'); 
            } 
          },/
      end

      # Enable selection link, button
      # The javascript function created by the user (options[:selection_handler]) will be called with the selected row id as a parameter
      selection_link = ""
      if (options[:direct_selection].blank? || options[:direct_selection] == false) && options[:selection_handler].present? && (options[:multi_selection].blank? || options[:multi_selection] == false)
        selection_link = %Q/
        jQuery("##{id}_select_button").click( function(){ 
          var id = jQuery("##{id}").getGridParam('selrow'); 
          if (id) { 
            #{options[:selection_handler]}(id); 
          } else { 
            alert("Please select a row");
          } 
        });/
      end

      # Enable direct selection (when a row in the table is clicked)
      # The javascript function created by the user (options[:selection_handler]) will be called with the selected row id as a parameter
      direct_link = ""
      if options[:direct_selection] && options[:selection_handler].present? && options[:multi_selection].blank?
        direct_link = %Q/
        onSelectRow: function(id){ 
          if(id){ 
            #{options[:selection_handler]}(id); 
          } 
        },/
      end

      # Enable grid_loaded callback
      # When data are loaded into the grid, call the Javascript function options[:grid_loaded] (defined by the user)
      grid_loaded = ""
      if options[:grid_loaded].present?
        grid_loaded = %Q/
        loadComplete: function(){ 
          #{options[:grid_loaded]}();
        },
        /
      end

      # Enable inline editing
      # When a row is selected, all fields are transformed to input types
      editable = ""
      if options[:edit] && options[:inline_edit] == "true"
        editable = %Q/
        onSelectRow: function(id){ 
          if(id && id!==lastsel){ 
            jQuery('##{id}').restoreRow(lastsel);
            jQuery('##{id}').editRow(id,true); 
            lastsel=id; 
          } 
        },/
      end

      # Generate required Javascript & html to create the jqgrid
      %Q(
        <script type="text/javascript">
        var lastsel;
        jQuery(document).ready(function(){
        jQuery("##{id}").jqGrid({
            // adding ?nd='+new Date().getTime() prevent IE caching
            url:'#{action}?nd='+new Date().getTime(),
            editurl:'#{options[:edit_url]}',
            datatype: "json",
            colNames:#{col_names},
            colModel:#{col_model},
            pager: jQuery('##{id}_pager'),
            rowNum:#{options[:rows_per_page]},
            rowList:[10,25,50,100],
            imgpath: '/images/themes/lightness/images',
            sortname: '#{options[:sort_column]}',
            viewrecords: true,
            toolbar : [true,"top"], 
            sortorder: '#{options[:sort_order]}',
            #{multiselect}
            #{masterdetails}
            #{grid_loaded}
            #{direct_link}
            #{editable}
            caption: "#{title}"
        });
        jQuery("#t_#{id}").height(25).hide().filterGrid("#{id}",{gridModel:true,gridToolbar:true});
        #{multihandler}
        #{selection_link}
        jQuery("##{id}").navGrid('##{id}_pager',{edit:#{edit_button},add:#{options[:add]},del:#{options[:delete]},search:false,refresh:true})
        .navButtonAdd("##{id}_pager",{caption:"Search",title:"Toggle Search",buttonimg:'/images/jqgrid/search.png',
        	onClickButton:function(){ 
        		if(jQuery("#t_#{id}").css("display")=="none") {
        			jQuery("#t_#{id}").css("display","");
        		} else {
        			jQuery("#t_#{id}").css("display","none");
        		}
        	} 
        });
        });
        </script>
        <table id="#{id}" class="scroll" cellpadding="0" cellspacing="0"></table>
        <div id="#{id}_pager" class="scroll" style="text-align:center;"></div>
      )
    end

    private

    # Generate a list of attributes for related column (align:'right', sortable:true, resizable:false, ...)
    def get_attributes(column)
      options = ""
      column.except(:field, :label).each do |couple|
        if couple[0] == :editoptions
          options << "editoptions:#{get_edit_options(couple[1])},"
        else
          if couple[1].class == String
            options << "#{couple[0]}:'#{couple[1]}',"
          else
            options << "#{couple[0]}:#{couple[1]},"
          end
        end
      end
      options.chop!
    end

    # Generate options for editable fields (value, data, width, maxvalue, cols, rows, ...)
    def get_edit_options(editoptions)
      options = "{"
      editoptions.each do |couple|
        if couple[0] == :value # :value => [[1, "Rails"], [2, "Ruby"], [3, "jQuery"]]
          options << %Q/value:"/
          couple[1].each do |v|
            options << "#{v[0]}:#{v[1]};"
          end
          options.chop! << %Q/",/
        elsif couple[0] == :data # :data => [Category.all, :id, :title])
          options << %Q/value:"/
          couple[1].first.each do |v|
            options << "#{v[couple[1].second]}:#{v[couple[1].third]};"
          end
          options.chop! << %Q/",/
        else # :size => 30, :rows => 5, :maxlength => 20, ...
          options << %Q/#{couple[0]}:"#{couple[1]}",/
        end
      end
      options.chop! << "}"
    end 
  end
end


module JqgridJson
  def to_jqgrid_json(attributes, current_page, per_page, total)
    json = %Q({"page":"#{current_page}","total":#{total/per_page.to_i+1},"records":"#{total}","rows":[)
    each do |elem|
      json << %Q({"id":"#{elem.id}","cell":[)
      couples = elem.attributes.symbolize_keys
      attributes.each do |atr|
        json << %Q("#{couples[atr]}",)
      end
      json.chop! << "]},"
    end
    json.chop! << "]}"
  end
end

class Array
  include JqgridJson
end