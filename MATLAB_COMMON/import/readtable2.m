function [ out, opts ] = readtable2( file, varargin)
%READTABLE2 
% An improved function for reading data into a table, exposing all the available input parameters and converting easily discernable text columns

if  mod(numel(varargin),2) ~= 0
	error('Additional arguments must be name value pairs.');
end

args = reshape(varargin,2,numel(varargin)/2);

convert_text = parse_varargs( varargin,'ConvertText',false,'bool');
raw_in_description = parse_varargs( varargin,'RawNameDescription',false,'bool');

detect_opts = {};

detect_opts_args = upper({ 'FileType','TextType', 'DatetimeType','NumVariables','NumHeaderLines','Sheet','Range','Delimiter','Whitespace','LineEnding','Encoding','CommentStyle'});
read_opts_ss_args = upper({'DataRange','VariableNamesRange','RowNamesRange','VariableUnitsRange','VariableDescriptionsRange','VariableNames','VariableTypes','VariableOptions','ImportErrorRule','MissingRule'});
read_opts_txt_args = upper({'DataLine','VariableNamesLine','RowNamesColumn','VariableUnitsLine','VariableDescriptionsLine','VariableNames','VariableTypes','VariableOptions','ImportErrorRule','MissingRule','ExtraColumnsRule','ConsecutiveDelimitersRule','LeadingDelimitersRule','EmptyLineRule','LineEnding','CommentStyle'});




for a = 1:size(args,2)
	if ismember( upper(args{1,a}), detect_opts_args )
		detect_opts{end+1} = args{1,a};
		detect_opts{end+1} = args{2,a};
	end
end

[~,~,file_ext] = fileparts( file);
[has_file_type, file_type_loc] = ismember( 'FileType' , args(1,:));
[has_data_line, data_line_loc] = ismember( 'DataLine' , args(1,:));
[has_data_range, data_range_loc] = ismember( 'DataRange' , args(1,:));

if has_file_type
	file_type = args{2,file_type_loc};
end

% Get Data Locations 
if has_data_line
	data_location = args{2,data_line_loc};
elseif has_data_range
	data_location = args{2,data_range_loc};
else
	data_location = [];
end
	
	
if any( ismember({'RANGE','NUMHEADERLINES'}, upper(detect_opts))) || isempty(data_location)
	% Range or num header lines specified - nothing to do
	
elseif has_file_type && strcmpi(file_type,'text') 
		detect_opts{end+1} = 'NumHeaderLines';
		detect_opts{end+1} = data_location - 1;
elseif has_file_type && strcmpi(file_type,'spreadsheet') 
% 		detect_opts{end+1} = 'Range';
% 		detect_opts{end+1} = data_location;
elseif 	ismember( lower(file_ext),{'.txt', '.dat', '.csv'})
		detect_opts{end+1} = 'NumHeaderLines';
		detect_opts{end+1} = data_location-1;
elseif 	ismember( lower(file_ext),{'.xls', '.xlsb', '.xlsm', '.xlsx', '.xltm', '.xltx', '.ods'})	
% 		detect_opts{end+1} = 'Range';
% 		detect_opts{end+1} = data_location;
end

opts = detectImportOptions(file, detect_opts{:});

if isa(opts,'matlab.io.text.DelimitedTextImportOptions')
	for a = 1:size(args,2)
		if ismember( upper(args{1,a}), read_opts_txt_args )
			opts.( args{1,a}) =  args{2,a};
		end
		
		if raw_in_description
			opts.VariableDescriptionsLine = opts.VariableNamesLine;
		end
		
	end
else
	for a = 1:size(args,2)
		if ismember( upper(args{1,a}), read_opts_ss_args )
			opts.( args{1,a}) =  args{2,a};
 		elseif strcmpi( args{1,a},'VariableNamesLine' )
			opts.VariableNamesRange =  args{2,a};
		elseif strcmpi( args{1,a},'VariableUnitsLine' )
			opts.VariableUnitsRange = args{2,a};	
		elseif strcmpi( args{1,a},'VariableDescriptionsLine' )
			opts.VariableDescriptionsRange = args{2,a};				
		elseif strcmpi( args{1,a},'DataLine' )
			opts.DataRange = args{2,a};
		end
		
		if raw_in_description
			opts.VariableDescriptionsRange = opts.VariableNamesRange;
		end
		
	end
end


out = readtable(file, opts,'ReadVariableNames',true);

if convert_text
for v = 1:width(out)
	if iscellstr(out.(v)) && all( ismember( upper(out.(v)),{'Y','YES','N','NO','NA','N/A','T','F','TRUE','FALSE',''} ))

		% default to NaN
		temp = nan(size(out.(v)));

		temp(regexpcmp(out.(v),'^Y(es)?$','ignorecase')) = 1;
		temp(regexpcmp(out.(v),'^T(rue)?$','ignorecase')) = 1;
		temp(regexpcmp(out.(v),'^N(o)?$','ignorecase')) = 0;
		temp(regexpcmp(out.(v),'^F(alse)?$','ignorecase')) = 0;
		
		out.(v) = temp;
		
	elseif iscellstr(out{:,v}) && all( regexpcmp(out{:,v},'^(-)?[0-9\.]*[eg]?(-)?[0-9\.]*$'))	
		
		% is this ever used?
		out.(v) = str2double(out.(v));
	
	end
	
end
	
end



end



