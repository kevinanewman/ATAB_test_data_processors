function [] = write_column_row( fid, columns, varargin)
%WRITE_COLUMNS outputs a formatted text column using the
% vector of class_data_columns, columns

delimiter        = parse_varargs(varargin, 'delimiter', ',', 'string');
write_header     = parse_varargs(varargin, 'header', false, 'toggle');
write_data       = parse_varargs(varargin, 'data', false, 'toggle');
verbose          = parse_varargs(varargin, 'verbose', Inf, 'numeric');
insert_blank_row = parse_varargs(varargin, 'insert_blank_row', false, 'logical');

if write_header
    if insert_blank_row
        fprintf(fid, '\n');
    end
    
    max_header_length = 0;
    for c = 1:length(columns)
        if verbose >= columns(c).verbose
            % find max header length of valid columns
            max_header_length = max(max_header_length, length(columns(c).header_cell_str));
        end
    end
    
    if max_header_length == 0
        % no valid columns found, apparently
        error('No data to write, check verbosity level!')
        fclose(fid);
    end
    
    for h = 1:max_header_length
        for c = 1:length(columns)
            if verbose >= columns(c).verbose
                % print header
                header_length = length(columns(c).header_cell_str);                
                % insert blank header rows if needed (align header bottoms)
                if ( h <= max_header_length - header_length )
                    fprintf(fid, '%s', delimiter);
                else
                    fprintf(fid, '%s%s', columns(c).header_cell_str{h - max_header_length + header_length}, delimiter);
                end
            end
        end
        fprintf(fid, '\n');
    end
end

if write_data
    if insert_blank_row
        fprintf(fid, '\n');
    end
    
    for c = 1:length(columns)        
        if verbose >= columns(c).verbose
            try
                out_str = sprintf(columns(c).format_str,evalin('caller',columns(c).eval_str));

%                 % matrix renames for new exemplar classes...
%                 out_str = strrep(out_str,'small_car',       'LPW_LRL');
%                 out_str = strrep(out_str,'standard_car',    'MPW_LRL');
%                 out_str = strrep(out_str,'full_size_car',   'HPW');
%                 out_str = strrep(out_str,'small_MPV',       'LPW_HRL');
%                 out_str = strrep(out_str,'large_MPV',       'MPW_HRL');
%                 out_str = strrep(out_str,'light_duty_truck','Truck');
                
                fprintf(fid, '%s%s', out_str, delimiter);
            catch
                fprintf(fid, '#CATCH# %s', delimiter);
            end
        end
    end
    fprintf(fid, '\n');
end

end
