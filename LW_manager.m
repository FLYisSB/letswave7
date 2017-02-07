function LW_manager()
% LW_init : set paths
LW_init();
% Manager_Init
handles=[];
Manager_Init();

    function Manager_Init()
        % create figure
        handles.fig=figure('Position',[100 50 500 670],...
            'name','Letswave7','NumberTitle','off');
        %% init menu
        set(handles.fig,'MenuBar','none');
        set(handles.fig,'DockControls','off');
        % menu labels
        menu_name={'File','Edit','Process','Toolbox','Statistics','View',...
            'Plugins'};
        for k=1:length(menu_name)
            % find related xml file
            str=['menu_',menu_name{k},'.xml'];
            if ~exist(str,'file')
                continue;
            end
            %convert xml to struct
            s= xml2struct(str);
            if ~isfield(s,'LW_Manager')||~isfield(s.LW_Manager,'menu')
                continue;                
            end
            %build titlebar menu (labels and callback)
            root = uimenu(handles.fig,'Label',s.LW_Manager.Attributes.Label);
            s=s.LW_Manager.menu;
            if ~iscell(s); s={s};end
            for k1=1:length(s)
                mh = uimenu(root,'Label',s{k1}.Attributes.Label);
                if isfield(s{k1},'submenu')
                    ss=s{k1}.submenu;
                    if ~iscell(ss) ss={ss};end
                    for k2=1:length(ss)
                        eh = uimenu(mh,'Label',ss{k2}.Attributes.Label);
                        if isfield(ss{k2},'subsubmenu')
                            sss=ss{k2}.subsubmenu;
                            if ~iscell(sss) sss={sss};end
                            for k3=1:length(sss)
                                if isfield(sss{k3}.Attributes,'callback') 
                                    uimenu(eh,'Label',sss{k3}.Attributes.Label,...
                                        'callback',@(obj,event)menu_callback(sss{k3}.Attributes.callback));
                                else
                                    uimenu(eh,'Label',sss{k3}.Attributes.Label,...
                                        'enable', 'off');
                                end
                             end
                        else
                            if isfield(ss{k2}.Attributes,'callback') 
                                set(eh,'callback',@(obj,event)menu_callback(ss{k2}.Attributes.callback));
                            else
                                set(eh,'enable', 'off');
                            end
                        end
                    end
                else
                    if isfield(s{k1}.Attributes,'callback')
                        set(mh,'callback',@(obj,event)menu_callback(s{k1}.Attributes.callback));
                    else
                        set(mh,'enable', 'off');
                    end
                end
            end
        end
        %build context menu (labels and callbacks)
        hcmenu = uicontextmenu;
        uimenu(hcmenu,'Label','view','Callback',{@(obj,events)dataset_view()});
        uimenu(hcmenu,'Label','rename','Callback',{@(obj,events)menu_callback('GLW_rename')});
        uimenu(hcmenu,'Label','delete','Callback',{@(obj,events)menu_callback('GLW_delete')});
        uimenu(hcmenu,'Label','send to workspace','Callback',{@(obj,events)sendworkspace_btn_Callback});
        uimenu(hcmenu,'Label','read from workspace','Callback',{@(obj,events)readworkspace_btn_Callback});
        %% init the controller
        
        icon=load('icon.mat');
        %refresh button
        handles.refresh_btn=uicontrol('style','pushbutton',...
            'CData',icon.icon_refresh,'position',[3,635,32,32],...
            'TooltipString','refresh the folder');
        %browse button
        handles.path_btn=uicontrol('style','pushbutton',...
            'CData',icon.icon_open_path,'position',[38,635,32,32],...
            'TooltipString','browse for folder');
        %filter path edit
        handles.path_edit=uicontrol('style','edit','string',pwd,...
            'HorizontalAlignment','left','position',[73,637,420,28]);
        %label 'Include'
        uicontrol('style','text','string','Include:',...
            'HorizontalAlignment','left','position',[5,600,80,28]);
        %filter checkbox
        handles.isfilter_checkbox=uicontrol('style','checkbox',...
            'string','Filter','position',[80,608,100,28]);
        %filter include listbox
        handles.suffix_include_listbox=uicontrol('style','listbox',...
            'string','Filter','position',[5,292,120,320]);
        set(handles.suffix_include_listbox,'max',2,'min',0);
        %label 'Exclude'
        uicontrol('style','text','string','Exclude:',...
            'HorizontalAlignment','left','position',[5,255,80,28]);
        %filter exclude listbox
        handles.suffix_exclude_listbox=uicontrol('style','listbox',...
            'string','Filter','position',[5,20,120,247]);
        set(handles.suffix_exclude_listbox,'max',2,'min',0);
        %label 'Datasets'
        uicontrol('style','text','string','Datasets:',...
            'HorizontalAlignment','left','position',[140,600,80,28]);
        %file listbox
        handles.file_listbox=uicontrol('style','listbox','string',...
            'Filter','position',[140,40,355,572]);
        set(handles.file_listbox,'max',2,'min',0);
        set(handles.file_listbox,'uicontextmenu',hcmenu);
        %label epochs
        handles.info_text_epoch=uicontrol('style','text','string','Epochs:',...
            'position',[140,15,100,19],'HorizontalAlignment','left');
        %label channels
        handles.info_text_channel=uicontrol('style','text',...
            'string','Channels:','position',[200,15,100,19],'HorizontalAlignment','left');
        %label Xsize
        handles.info_text_X=uicontrol('style','text','string','X:',...
            'position',[280,15,100,19],'HorizontalAlignment','left');
        %label Ysize
        handles.info_text_Y=uicontrol('style','text','string','Y:',...
            'position',[350,15,100,19],'HorizontalAlignment','left');
        %label Zsize
        handles.info_text_Z=uicontrol('style','text','string','Z:',...
            'position',[400,15,100,19],'HorizontalAlignment','left');
        %label index
        handles.info_text_Index=uicontrol('style','text','string','I:',...
            'position',[440,15,100,19],'HorizontalAlignment','left');
        %label tips
        handles.tip_text=uicontrol('style','text','string','tips:',...
            'position',[2,-1,490,19],'HorizontalAlignment','left');
        %change units to 'normalized'
        try
            set(get(handles.fig,'children'),'units','normalized');
        end
        %set path to pwd
        set(handles.path_edit,'String',pwd);
        set(handles.path_edit,'Userdata',pwd);
        %set callbacks
        set(handles.fig,'CloseRequestFcn',{@(obj,events)fig_Close()});
        set(handles.refresh_btn,'Callback',{@(obj,events)update_handles()});
        set(handles.path_btn,'Callback',{@(obj,events)path_btn_Callback()});
        set(handles.path_edit,'Callback',{@(obj,events)path_edit_Callback()});
        set(handles.isfilter_checkbox,'Callback',{@(obj,events)update_handles()});
        set(handles.suffix_include_listbox,'Callback',{@(obj,events)suffix_listbox_Callback()});
        set(handles.suffix_exclude_listbox,'Callback',{@(obj,events)suffix_listbox_Callback()});
        set(handles.file_listbox,'Callback',{@(obj,events)file_listbox_Callback()});
        set(handles.file_listbox,'KeyPressFcn',@key_Press)
        %update_handles
        update_handles();
        handles.batch={};
        %% init timer
        handles.timer = timer('BusyMode','drop','ExecutionMode','fixedRate','TimerFcn',{@(obj,events)on_Timer()});
        start(handles.timer);
    end

    function file_listbox_Callback()
        %on change in selection
        if strcmp(get(gcf,'SelectionType'),'normal')
            file_listbox_select_changed();
        end
        %on open
        if strcmp(get(gcf,'SelectionType'),'open')
            dataset_view();
        end
    end

    function file_listbox_select_changed()
        %execute on change in selection
        %file_listbox.userdata stores all filenames in the listbox
        str=get(handles.file_listbox,'userdata');
        %get selection
        idx=get(handles.file_listbox,'value');
        if isempty(str)|| isempty(idx)
            %listbox is empty
            filename='<empty>';
            set(handles.info_text_epoch,'string','Epochs:');
            set(handles.info_text_channel,'string','Channels:');
            set(handles.info_text_X,'string','X:');
            set(handles.info_text_Y,'string','Y:');
            set(handles.info_text_Z,'string','Z:');
            set(handles.info_text_Index,'string','I:');
        else
            %listbox is not empty
            %will report the size of the first selected dataset
            filename=str{idx(1)};
            try
            header = CLW_load_header(filename);
            set(handles.info_text_epoch,'string',['Epochs:',num2str(header.datasize(1))]);
            set(handles.info_text_channel,'string',['Channels:',num2str(header.datasize(2))]);
            set(handles.info_text_X,'string',['X:',num2str(header.datasize(6))]);
            set(handles.info_text_Y,'string',['Y:',num2str(header.datasize(5))]);
            set(handles.info_text_Z,'string',['Z:',num2str(header.datasize(4))]);
            set(handles.info_text_Index,'string',['I:',num2str(header.datasize(3))]);
            catch
            set(handles.info_text_epoch,'string',['Epochs:Error']);
            set(handles.info_text_channel,'string',['Channels:Error']);
            set(handles.info_text_X,'string',['X:Error']);
            set(handles.info_text_Y,'string',['Y:Error']);
            set(handles.info_text_Z,'string',['Z:Error']);
            set(handles.info_text_Index,'string',['I:Error']);
            end
        end
    end

    function suffix_listbox_Callback()
        %executes when selecting items in the suffix listbox
        set(handles.isfilter_checkbox,'value',1);
        update_handles;
    end

    function path_edit_Callback()
        %executes when changing content of path_edit
        st=get(handles.path_edit,'String');
        if exist(st,'dir')
            update_handles;
        else
            st=get(handles.path_edit,'userdata');
            set(handles.path_edit,'String',st);
        end
    end

    function path_btn_Callback()
        %executes when clicking path_btn
        st=get(handles.path_edit,'String');
        st=uigetdir(st);
        if ~isequal(st,0) && exist(st,'dir')==7
            set(handles.path_edit,'String',st);
            update_handles;
        end
    end

    function option=get_selectfile()
        %returns a structure with the selected files
        option=[];
        str=get(handles.file_listbox,'userdata');
        idx=get(handles.file_listbox,'value');
        if isempty(idx) || isempty(str)
            warndlg('No datasets selected!','Warning','modal');
            return;
        end
        option.file_str  = [str(idx)];
        option.file_path = get(handles.path_edit,'userdata');
    end

    function sendworkspace_btn_Callback()
        %executes when clicking sendworkspace_btn
        option=get_selectfile();
        if isempty(option)
            return;
        end
        for k=1:length(option.file_str)
            [lwdata(k).header,lwdata(k).data]=...
                CLW_load(fullfile(option.file_path,option.file_str{k}));
        end
        assignin('base','lwdata',lwdata);
    end

    function readworkspace_btn_Callback()
        %executes when clicking readworspace_btn
        option=get_selectfile();
        if isempty(option)
            return;
        end
        if isempty(option)|| length(option.file_str)>1
            disp('Please select the file to update from workspace');
            return;
        end      
        try
            lwdata=evalin('base','lwdata');
        catch
            disp('lwdata variable not found,in workspace');
            return;
        end
        lwdata=lwdata(1);
        if isfield(lwdata,'header')&&isfield(lwdata,'data')
            t=questdlg('Are you sure?');
            if strcmpi(t,'Yes');
                lwdata.header.name=option.file_str{1};
                CLW_save(lwdata,'path',option.file_path);
            end
        else
            if ~isfield(lwdata,'header')
            disp('!!! Header field not found');
            end
            if ~isfield(lwdata,'data')
            disp('!!! Data field not found');
            end
        end
    end

    function menu_callback(fun_name)
        %executes on menu_callback
        %fun_name = name of function associated with menu callback
        if ~isempty([strfind(fun_name,'FLW_export_'),strfind(fun_name,'FLW_import_')])
            %if fun_name is FLW_export or FLW_import
            %execute the function without any arguments
            eval([fun_name,'();']);
            update_handles();
            return;
        else
            %if fun_name is any other function
            %get the selection of files > option
            option=get_selectfile();
            if isempty(option)
                return;
            end
        end
        %if first letter of function name is 'F'
        if(fun_name(1)=='F')
            %add option.fun_name to option
            option.fun_name = fun_name;
            %LW_batch(option)
            handles.batch{end+1}=LW_batch(option);
        else
            eval([fun_name,'(option);']);
            update_handles();
        end
    end

    function key_Press(~,events)
        %keyboard shortcuts
        switch events.Key
            case 'delete'
                menu_callback('GLW_delete');
            case 'backspace'
                menu_callback('GLW_delete');
            case 'r'
                menu_callback('GLW_rename');
            case 'v'
                dataset_view();
            case 'f5'
                update_handles();
        end
    end

    function dataset_view()
        option=get_selectfile();
        if isempty(option)
            return;
        end
        [p, n, ~]=fileparts(fullfile(option.file_path,option.file_str{1}));
        header=CLW_load_header(fullfile(p,n));
        if header.datasize(5)>1
            GLW_multi_viewer_map(option);
        else
            if length(option.file_str)==1 &&...
                    header.datasize(1)==1 &&...
                    header.datasize(6)>1000 && ...
                    header.datasize(6)*header.xstep>=10 &&...
                    strcmpi(header.filetype,'time_amplitude');
                GLW_multi_viewer_continuous(option);
            else
                GLW_multi_viewer_wave(option);
            end
        end
    end

    function on_Timer()
        %executes on timer event
        if ~isempty(handles.batch)
            index=[];
            for k=1:length(handles.batch)
                if ishandle(handles.batch{k})
                    index=[index,k];
                end
            end
            if length(index)~=length(handles.batch)
                handles.batch=[handles.batch{index}];
                update_handles();
            end
        end
    end

    function fig_Close()
        %executes on figure close
        try
            stop(handles.timer);
            delete(handles.timer);
        end
        closereq;
    end

    function update_handles()
        st=get(handles.path_edit,'String');
        if exist(st,'dir')~=7
            return;
        end
        set(handles.path_edit,'userdata',st);
        cd(st);
        filename1=dir([st,filesep,'*.lw6']);
        filename2=dir([st,filesep,'*.lw5']);
        filename={filename1.name,filename2.name};
        filelist=cell(1,length(filename));
        filelist_suffix=cell(1,length(filename));
        for k=1:length(filename)
            filelist_suffix{k}=textscan(filename{k}(1:end-4),'%s');
            filelist_suffix{k}=filelist_suffix{k}{1}';
            switch(filename{k}(end))
                case '6'
                    filelist{k}=filename{k}(1:end-4);
                case '5'
                    filelist{k}=['<HTML><BODY color="blue">',filename{k}];
            end
        end
        suffix=sort(unique([filelist_suffix{:}]));
        str=get(handles.suffix_include_listbox,'String');
        idx=get(handles.suffix_include_listbox,'value');
        if isempty(str)
            selected_str=[];
        else
            selected_str=str(idx);
        end
        %
        str=get(handles.suffix_exclude_listbox,'String');
        idx=get(handles.suffix_exclude_listbox,'value');
        if isempty(str)
            baned_str=[];
        else
            baned_str=str(idx);
        end
        %
        str=get(handles.file_listbox,'String');
        idx=get(handles.file_listbox,'value');
        if isempty(str)
            file_str=[];
        else
            file_str=str(idx);
        end
        %
        is_filter=get(handles.isfilter_checkbox,'value');
        if is_filter==1
            set(handles.suffix_include_listbox,'string',suffix);
            [~,selected_idx]=intersect(suffix,selected_str,'stable');
            set(handles.suffix_include_listbox,'value',selected_idx);
            
            if isempty(selected_idx)
                selected_file_index=1:length(filelist);
            else
                selected_file_index=[];
                for k=1:length(filelist)
                    if isempty(setdiff(suffix(selected_idx),filelist_suffix{k}))
                        selected_file_index=[selected_file_index,k];
                    end
                end
            end
            %
            if isempty(selected_file_index)
                set(handles.file_listbox,'String',{});
                set(handles.file_listbox,'userdata',{});
                set(handles.file_listbox,'value',[]);
                set(handles.suffix_exclude_listbox,'String',{});
                set(handles.suffix_exclude_listbox,'value',[]);
            else
                suffix_baned=sort(unique([filelist_suffix{selected_file_index}]));
                suffix_baned=setdiff(suffix_baned,suffix(selected_idx));
                [~,baned_idx]=intersect(suffix_baned,baned_str,'stable');
                set(handles.suffix_exclude_listbox,'String',suffix_baned);
                set(handles.suffix_exclude_listbox,'value',baned_idx);
                band_file_index=[];
                for j=selected_file_index
                    if isempty(intersect(suffix_baned(baned_idx),filelist_suffix{j}))
                        band_file_index=[band_file_index,j];
                    end
                end
                [~,idx]=intersect(filelist(band_file_index),file_str,'stable');
                set(handles.file_listbox,'String',filelist(band_file_index));
                set(handles.file_listbox,'userdata',{filename{band_file_index}});
                set(handles.file_listbox,'value',idx);
            end
        else
            set(handles.suffix_include_listbox,'string',suffix);
            set(handles.suffix_include_listbox,'value',[]);
            set(handles.suffix_exclude_listbox,'string',suffix);
            set(handles.suffix_exclude_listbox,'value',[]);
            set(handles.file_listbox,'string',filelist);
            set(handles.file_listbox,'userdata',filename);
            [~,idx]=intersect(filelist,file_str,'stable');
            set(handles.file_listbox,'value',idx);
        end
        file_listbox_select_changed();
    end
end