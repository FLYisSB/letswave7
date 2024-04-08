classdef FLW_merge_by_tag<CLW_generic
    % Basic properties
    properties
        FLW_TYPE = 4;
        h_tag_list;
    end

    % GUI methods
    methods
        function obj = FLW_merge_by_tag(batch_handle)
            obj@CLW_generic( ...
                batch_handle, ...
                'merge', 'Merge',...
                'Merge multiple data files by tag into multi data file.');
            set(obj.h_is_save_chx, ...
                'enable', 'off');

            obj.h_tag_list=uicontrol( ...
                'style', 'listbox', ...
                'string', {}, ...
                'value', [], ...
                'max', 2, ...
                'position', [5,190,200,300],...
                'parent', obj.h_panel);
        end

        function option = get_option(obj)
            option = get_option@CLW_generic(obj);
            tag_string = get(obj.h_tag_list, 'String');
            tag_value = get(obj.h_tag_list, 'value');
            option.tag = tag_string(tag_value);
        end

        function str = get_Script(obj)
            option = get_option(obj);
            frag_code = [];
            frag_code = [frag_code, '''tag'', {{'];
            for i = 1:size(option.tag, 1)
                frag_code = [frag_code, '''', option.tag{i}, ''''];
                if i ~= size(option.tag, 1)
                    frag_code = [frag_code, ','];
                end
            end
            frag_code = [frag_code, '}}, '];
            str = get_Script@CLW_generic(obj, frag_code, option);
        end

        function GUI_update(obj, batch_pre)
            lwdataset = batch_pre.lwdataset;

            tag_string = get(obj.h_tag_list, 'String');
            tag_value = get(obj.h_tag_list, 'value');
            tag_selected = tag_string(tag_value);

            tag = textscan(lwdataset(1).header.name, '%s');
            tag = tag{:, 1};
            for i = 1:size(lwdataset, 2)
                new_tag = textscan(lwdataset(i).header.name, '%s');
                new_tag = new_tag{:, 1};
                tag = union(tag, new_tag);
            end
            assignin('base', 'tag', tag);
            set(obj.h_tag_list, "String", tag);
            [~, idx] = intersect(tag, tag_selected, 'stable');
            set(obj.h_tag_list, 'value', idx);

        end

    end

    % Functional methods
    methods (Static = true)
        function header_out = get_header()

        end

        function lwdataset_out = get_lwdataset(lwdataset_in, varargin)
            disp('test!');
            assignin('base', 'lwdataset_in', lwdataset_in);

            option.tag = [];
            option.is_save = 1;
            option.suffix = 'merger';
            option = CLW_check_input(option, {'tag', 'suffix', 'is_save'}, varargin);
            assignin('base', 'option', option);
        
            lwdata_counts = 1;
            for i = 1:size(option.tag, 2)
                tag_str = option.tag{i};
                file_name_list = {};
                temp_counts = 1;

                for j = 1:size(lwdataset_in, 2)
                    file_name = lwdataset_in(j).header.name;
                    if contains(file_name, tag_str)
                        file_name_list = [file_name_list, file_name];
                        temp_lwdataset(temp_counts) = lwdataset_in(j);
                        temp_counts = temp_counts + 1;
                    end
                end
                assignin('base', 'temp_lwdataset', temp_lwdataset);

                new_suffix = [option.suffix, '_', char(tag_str)];
                temp_option=struct( ...
                    'type', 'epoch', ...
                    'suffix', new_suffix, ...
                    'is_save', 1);
                merged_lwdata = FLW_merge.get_lwdata(temp_lwdataset, temp_option);
                lwdataset_out(lwdata_counts) = merged_lwdata;
                lwdata_counts = lwdata_counts + 1;
                disp(file_name_list);
            end
            assignin('base', 'lwdataset_out', lwdataset_out);
        end
    end
end