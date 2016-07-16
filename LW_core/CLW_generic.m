classdef CLW_generic<handle
    %CLW_generic
    properties
        h_tab;
        h_panel;
        index_num=1;
        is_selected=1;
        
        h_txt_cmt;
        h_btn_script;
        h_affix_txt;
        h_affix_edit;
        h_is_save_chx;
        h_title_str;
        h_help_str;
        lwdataset;
        virtual_filelist;
    end
    
    methods
        function obj = CLW_generic(batch_handle,fun_name,affix_name,help_str)
            obj.h_title_str=['==========',class(obj),'=========='];
            obj.h_help_str=help_str;
            
            obj.h_tab = uicontrol(batch_handle.tab_panel,'style','pushbutton',...
                'string',fun_name);
            obj.h_panel=uipanel(batch_handle.fig,...
                'units','pixels','position',[99,45,421,526]);
            
            obj.h_txt_cmt = uicontrol('parent',obj.h_panel,'style','edit','max',2,'Enable','inactive',...
                'position',[5,5,305,120],'HorizontalAlignment','left',...
                'backgroundcolor',[1,1,1]);
            set(obj.h_txt_cmt,'string',{obj.h_title_str,obj.h_help_str});
            
            obj.h_affix_txt=uicontrol('style','text','position',[315,100,40,20],...
                'string','prefix:',...
                'HorizontalAlignment','left','parent',obj.h_panel);
            obj.h_affix_edit=uicontrol('style','edit','position',[315,80,100,25],...
                'HorizontalAlignment','left','string',affix_name,'parent',obj.h_panel);
            obj.h_is_save_chx=uicontrol('style','checkbox','value',1,...
                'position',[315,50,200,30],'string','save','parent',obj.h_panel);
            obj.h_btn_script = uicontrol('style','pushbutton',...
                'String','Script','position',[315,5,100,35],...
                'parent',obj.h_panel,'Callback',@obj.view_Script);
            obj.virtual_filelist=struct('filename',{},'header',{});
        end
                
        function option=get_option(obj)
            option=[];
            option.affix=get(obj.h_affix_edit,'string');
            option.is_save=get(obj.h_is_save_chx,'value');
            option.function=class(obj);
        end
        
        function set_option(obj,option)
            set(obj.h_affix_edit,'string',option.affix);
            set(obj.h_is_save_chx,'value',option.is_save);
        end
        
        function GUI_update(obj,batch_pre)
            obj.virtual_filelist=batch_pre.virtual_filelist;
            set(obj.h_txt_cmt,'String',{obj.h_title_str,obj.h_help_str},'ForegroundColor','black');
        end
        
        function header_update(obj,batch_pre)
            obj.virtual_filelist=batch_pre.virtual_filelist;
            lwdataset=batch_pre.lwdataset;
            option=get_option(obj);
            for data_pos=1:length(lwdataset)
                obj.lwdataset(data_pos).header = obj.get_header(lwdataset(data_pos).header,option);
                evalc('obj.lwdataset(data_pos).header = obj.get_header(lwdataset(data_pos).header,option);');
                if option.is_save
                    obj.virtual_filelist(end+1)=struct(...
                        'filename',obj.lwdataset(data_pos).header.name,...
                        'header',obj.lwdataset(data_pos).header);
                end
            end
        end
        
        function str=get_Script(obj,frag_code,option)
            temp='option=struct(';
            temp=[temp,frag_code];
            temp=[temp,'''affix'',''',option.affix,''','];
            temp=[temp,'''is_save'',',num2str(option.is_save)];
            temp=[temp,');'];
            str=[{temp},{['lwdata= ',class(obj),'.get_lwdata(lwdata,option);']}];
        end
        
        function view_Script(obj,varargin)
            script=get_Script(obj);
            CLW_show_script(script);
        end        
    end
end