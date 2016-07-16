classdef FLW_segmentation<CLW_generic
    properties
        FLW_TYPE=1;
        h_code_list;
        h_code_btn;
        h_x_start_edit;
        h_x_duration_edit;
    end
    methods
        function obj = FLW_segmentation(tabgp)
            obj@CLW_generic(tabgp,'segmentation','ep',...
                'Segment a continuous dataset into a series of epochs of a given length, relative to the latencies of events. One file for all selected event codes');            
            
            uicontrol('style','text','position',[5,540,200,20],...
                'string','Event codes','HorizontalAlignment','left',...
                'parent',obj.h_tab);
            obj.h_code_list=uicontrol('style','listbox','string',{},...
                'value',[],'max',2,'position',[5,240,200,300],...
                'parent',obj.h_tab);
            obj.h_code_btn=uicontrol('style','pushbutton',...
                'String','Select All','position',[5,180,200,50],...
                'parent',obj.h_tab,'callback',@obj.select_All);
            
            uicontrol('style','text','position',[225,480,200,20],...
                'string','Epoch start (relative to event onset) :',...
                'HorizontalAlignment','left','parent',obj.h_tab);
            obj.h_x_start_edit=uicontrol('style','edit',...
                'position',[230,450,180,30],'HorizontalAlignment','left',...
                'string','0','parent',obj.h_tab);
            uicontrol('style','text','position',[225,400,200,20],...
                'string','Epoch duration (units) :',...
                'HorizontalAlignment','left','parent',obj.h_tab);
            obj.h_x_duration_edit=uicontrol('style','edit',...
                'position',[230,370,180,30],'HorizontalAlignment','left',...
                'string','1','parent',obj.h_tab);
        end
        
        function select_All(obj,varargin)
            str=get(obj.h_code_list,'String');
            if ~isempty(str)
                set(obj.h_code_list,'value',1:length(str));
            end
        end
        
        function option=get_option(obj)
            option=get_option@CLW_generic(obj);
            str=get(obj.h_code_list,'String');
            str_value=get(obj.h_code_list,'value');
            option.event_labels=str(str_value);
            option.x_start=str2num(get(obj.h_x_start_edit,'string'));
            option.x_duration=str2num(get(obj.h_x_duration_edit,'string'));
        end
        
        function set_option(obj,option)
            set_option@CLW_generic(obj,option);
            event_labels=cellstr(option.event_labels);
            set(obj.h_code_list,'String',event_labels);
            set(obj.h_code_list,'value',1:length(event_labels));
            set(obj.h_x_start_edit,'string',num2str(option.x_start));
            set(obj.h_x_duration_edit,'string',num2str(option.x_duration));
        end
        
        function str=get_Script(obj)
            option=get_option(obj);
            frag_code=[];
            frag_code=[frag_code,'''event_labels'',{{'];
            for k=1:length(option.event_labels)
                frag_code=[frag_code,'''',option.event_labels{k},''''];
                if k~=length(option.event_labels)
                    frag_code=[frag_code,','];
                end
            end
            frag_code=[frag_code,'}},'];
            frag_code=[frag_code,'''x_start'',',num2str(option.x_start),','];
            frag_code=[frag_code,'''x_duration'',',num2str(option.x_duration),','];
            
            str=get_Script@CLW_generic(obj,frag_code,option);
        end
        
        function GUI_update(obj,batch_pre)
            lwdataset=batch_pre.lwdataset;
            str=get(obj.h_code_list,'String');
            str_value=get(obj.h_code_list,'value');
            str_selected=str(str_value);
            st=sort(unique({lwdataset(1).header.events.code}));
            for dataset_pos=2:length(lwdataset)
                st= intersect(st,{lwdataset(dataset_pos).header.events.code});
            end
            if isempty(st)
                error('***No common event code in the datasets.***')
            end
            %             st={};
            %             for dataset_pos=1:length(lwdataset)
            %                 events=lwdataset(dataset_pos).header.events;
            %                 if ~isempty(events)
            %                     st=[st,events.code];
            %                 end
            %             end
            %             st=unique(st);
            %             st=sort(st);
            set(obj.h_code_list,'String',st);
            [~,idx] = intersect(st,str_selected,'stable');
            set(obj.h_code_list,'value',idx);
            if isempty(idx)&& ~isempty(st)
                set(obj.h_code_list,'value',1);
            end
            obj.virtual_filelist=batch_pre.virtual_filelist;
            set(obj.h_txt_cmt,'String',{obj.h_title_str,obj.h_help_str},'ForegroundColor','black');
        end
                
    end
    
    methods (Static = true)
        function header_out= get_header(header_in,option)
            events_in=header_in.events;
            if isempty(events_in)
                error(['***No events in dataset ',header_in.name,'***']);
            end
            event_idx=[];
            for event_labels_pos=1:length(option.event_labels)
                event_idx=[event_idx,find(strcmp({events_in.code},...
                    option.event_labels{event_labels_pos}))];
            end
            latency=[events_in(event_idx).latency];
            event_idx=event_idx(latency+option.x_start>=header_in.xstart...
                &latency+option.x_start+option.x_duration<=...
                header_in.xstart+header_in.xstep*header_in.datasize(6));
            
            if isempty(event_idx);
                error(['***event code ''',...
                    strjoin(option.event_labels,''', '''), ...
                    ''' can not found in dataset ',header_in.name,'***']);
            end
            dxsize=fix((option.x_duration)/header_in.xstep);
            
            tic;
            latency_event=[events_in(event_idx).latency];
            latency_all=[events_in.latency];
            latency_1=latency_event+option.x_start;
            latency_2=latency_event+option.x_start+(dxsize-1)*header_in.xstep;
            epoch_event=[events_in(event_idx).epoch];
            epoch_all=[events_in.epoch];
            A=find((ones(length(dx1),1)*latency_all>=latency_1'*ones(1,length(latency_all)))...
                & (ones(length(dx1),1)*latency_all<=latency_2'*ones(1,length(latency_all)))...
                & (ones(length(dx1),1)*epoch_all==epoch_event'*ones(1,length(latency_all))));
            [I,J] = ind2sub([length(dx1),length(latency_all)],A);
            code={events_in(J).code};
            epoch=num2cell(I)';
            latency=num2cell(latency_all(J)-latency_event(I));
            events_out=struct('code',code,'latency',latency,'epoch',epoch);
            toc;
            
            header_out=header_in;
            header_out.datasize(1)=length(events_out);
            header_out.datasize(6)=dxsize;
            header_out.xstart=option.x_start;
            header_out.events=events_out;
            if ~isempty(option.affix)
                header_out.name=[option.affix,' ',header_out.name];
            end
            option.function='FLW_segmentation';
            header_out.history(end+1).option=option;            
        end
        
        function lwdata_out= get_lwdata(lwdata_in,varargin)
            option.event_labels=[];
            option.x_start=0;
            option.x_duration=1;
            option.affix='ep';
            option.is_save=0;
            option=CLW_check_input(option,{'event_labels','x_start','x_duration','affix','is_save'},varargin);
            
            if isempty(option.event_labels)
                error('***No event codes selected!***');
            end
            option.event_labels=cellstr(option.event_labels);
            
            header= FLW_segmentation.get_header(lwdata_in.header,option);
            data=zeros(header.datasize);
            if header.datasize(1)==0
                disp(['event code ''',strjoin(option.event_labels,''', '''), ''' can not found in dataset ',lwdata_in.header.name]);
            else
                events_in=lwdata_in.header.events;
                event_idx=[];
                for event_labels_pos=1:length(option.event_labels)
                    event_idx=[event_idx,find(strcmp({events_in.code},option.event_labels{event_labels_pos}))];
                end
                dxsize=fix((option.x_duration)/lwdata_in.header.xstep);
                epoch_pos=0;
                for k=event_idx
                    dx1=fix((((events_in(k).latency+option.x_start)-lwdata_in.header.xstart)/lwdata_in.header.xstep))+1;
                    dx2=(dx1+dxsize)-1;
                    if dx1<1 || dx2>lwdata_in.header.datasize(6)
                        continue;
                    end
                    epoch_pos=epoch_pos+1;
                    data(epoch_pos,:,:,:,:,:)=lwdata_in.data(events_in(k).epoch,:,:,:,:,dx1:dx2);
                end
            end
            lwdata_out.header=header;
            lwdata_out.data=data;
            if option.is_save
                CLW_save(lwdata_out);
            end
        end
    end
end