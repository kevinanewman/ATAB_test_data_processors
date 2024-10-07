function [data, data_edits] = load_data_file( file_info, data_format, user_data_edits , avg_data)

%Make table for storing edited points
data_edits = struct('file','','test_number','','mode_number','','signal','','action','','comment','');
data_edits = data_edits([]);

% 
% table({''},{''},{''},{''},{''},{''},'VariableNames',{'file','test_number','mode_number','signal','action','comment'});
% data_edits = data_edits([],:);

fprintf('\nLoading Data: %s\n', file_info.file);

% Use 98 kPa as default barometric pressure adjustment
baro = [];

% Set import options
[~,filename,ext] = fileparts(file_info.file);
filename = [filename,ext];

if ismember( ext,{'.xls', '.xlsb', '.xlsm', '.xlsx', '.xltm', '.xltx', '.ods'})
	import_opts = {'FileType';'spreadsheet'};
	spreadsheet_file = true;
else
	import_opts = {'FileType';'text'};
	spreadsheet_file = false;
end


if spreadsheet_file  && ~isempty(file_info.sheet)
	import_opts{end+1} = 'Sheet';
	import_opts{end+1} = file_info.sheet;
end

if ~spreadsheet_file && ~isempty(file_info.delimiter) 
	import_opts{end+1} = 'Delimiter';
	import_opts{end+1} = replace( file_info.delimiter,{ 'TAB','SPACE','COMMA'},{'\t',' ',','});
end

if  ~isnan(file_info.variable_line)
	import_opts{end+1} =  'VariableNamesLine';
	import_opts{end+1} = file_info.variable_line;
end

if  ~isnan(file_info.unit_line)
	import_opts{end+1} = 'VariableUnitsLine';
	import_opts{end+1} = file_info.unit_line;
end

if  ~isnan(file_info.data_line)
	import_opts{end+1} = 'DataLine';
	import_opts{end+1} = file_info.data_line;
end

%         data = readtable2( file_info.file, import_opts{:},'ConvertText',1,'RawNameDescription',1 );
raw_data = readtable2( file_info.file, import_opts{:},'RawNameDescription',1 );

if height(raw_data) <= 0
	warning('No data found in file "%s"', file_info.file);
	raw_data = table; %return empty table
	return;
end


% Clean actual imported names (stored in VariableDescription) and replace any missing with
% the column number allowing the column to be selected by number
import_names = strtrim(regexprep( raw_data.Properties.VariableDescriptions, '\s*',' '));
untitled_cols = cellfun( @isempty, import_names);
import_names(untitled_cols) = strcat('COLUMN_',strtrim(cellstr(int2str(find(untitled_cols)'))));
raw_data.Properties.VariableDescriptions = import_names;


matched_vars = false(size(import_names));

data = table;

if avg_data 
	load_format = data_format( [data_format.load_avg]);
else
	load_format = data_format( [data_format.load_cont]);
end


%% Apply Working Names, Units & Limits
for f = 1:numel(load_format)
	
	format = load_format(f);
	
	% Don't worry about working variables
	if  isempty( format.input_names )
		continue;
	end
	
	warn_input_names = strjoin( strcat('"',format.input_names,'"'),', ');
	match = false;
	
	input_idx = 0;
    input_names = format.input_names;
	while input_idx < length( input_names ) && ~any(match)
		input_idx = input_idx + 1;
		InputNameSearch = make_wildcard_search_str(input_names{input_idx});
		match = regexpcmp(import_names, InputNameSearch );
	end
	
	
	% Handle cases if nothing
	if ~any(match)
		fprintf(' ! No matching data found for data format %d, input names  %s\n', format.idx, warn_input_names);
		continue;
	end
	
	% If generic wildcard only pick columns that have not been touched otherwise
	if format.is_catch_all % strcmpi(input_names{input_idx},'*')
		match = match & ~matched_vars;
	end
	
	matched_vars = matched_vars | match;
	
	
	% Celect matching columns (variables)
	sel_data = raw_data(:,match);
	
	
	% Switch to working names
	WorkingNameReplace = make_wildcard_replacement(format.working_name);
	WorkingName = regexprep( sel_data.Properties.VariableDescriptions , InputNameSearch , WorkingNameReplace);
	sel_data.Properties.VariableNames = matlab.lang.makeUniqueStrings(matlab.lang.makeValidName(WorkingName),{},63);
	
	% Apply Unit Conversion & Range Limits
	out_units = format.output_units;
	
	if ~isempty(out_units)
		for var = 1:width(sel_data)
			in_var_name = sel_data.Properties.VariableDescriptions{var};
			
			if isnumeric(sel_data.(var))
				
				if ~isempty( format.input_units )
					in_units = format.input_units;
				elseif ~isempty( sel_data.Properties.VariableUnits)
					in_units = sel_data.Properties.VariableUnits{var};
				else
					in_units = '';
				end
						
				sel_data.(var) = convert_units( sel_data.(var), in_units, out_units, sprintf('%s (data format %d)', in_var_name, format.idx) , baro );
								
			end
			
			sel_data.Properties.VariableUnits{var} = out_units;
			
		end

    end
	
	
	% Grab ambient pressure to update future pressure measurements
	if 	strcmpi(format.working_name, 'ambient_press' )
		baro = sel_data.(var) * parse_units(out_units);
	end
		
	data = [data, sel_data];
		
end

if ~istablevar( data,'test_number')
	fprintf(' ! Test number variable not found in data file. Unable to apply data quality edits for specific test numbers.\n');
	data.test_number = nan(height(data),1);
end

if ~istablevar( data,'test_mode')
	fprintf(' ! Test mode variable not found in data file. Unable to apply data quality edits for specific test modes.\n');
	data.test_mode = nan(height(data),1);
end


data(:,'source_file') = {filename};
data.questionable_data = false(height(data),1);



for q = 1:numel( user_data_edits )
	
	entry =user_data_edits(q);
	
	% Reload name if previous loop edited columns
	in_var_names = data.Properties.VariableDescriptions;
	work_var_names = data.Properties.VariableNames;
	
	if ~wildcardcmp(filename, entry.file)
		continue;
	end
	
	if strcmpi(entry.test_number,'*')
		match_test_num = true( height(data),1);
	else
		match_test_num = ismember( data.test_number, eval(entry.test_number ));
	end
	
	if strcmpi(entry.mode_number,'*')
		match_mode_num = true( height(data),1);
	else
		match_mode_num = ismember( data.test_mode, eval(entry.mode_number ));
	end
	
	match_row = match_test_num & match_mode_num ;
	
	% Setup generic data edit
	data_edit = struct('file',file_info.file,'test_number',unique(data.test_number(match_test_num)),'mode_number',unique(data.test_mode(match_mode_num)),'signal','','action','REMOVE','comment',entry.comment);

	
	if ~any(match_row)
		%Nothing to do...
	elseif strcmpi( entry.action,'remove') && strcmpi( entry.signal, '*')	
		% Remove whole row
		data(match_row,:) = [];	
		fprintf(' - Removing %d entries for all variables as specified in the template - "%s"\n', sum(match_row), entry.comment);
	
		data_edit.signal = '*';
		data_edits(end+1) = data_edit;
		
	elseif strcmpi( entry.action,'remove') 	
		
		match_var_search  = make_wildcard_search_str(entry.signal); 	
		match_var = find(regexpcmp( in_var_names, match_var_search) | regexpcmp( work_var_names, match_var_search));

		num_rows = conditional( all( match_row), 'all', int2str(sum(match_row)) );
				
		data_edit = struct('file',file_info.file,'test_number',unique(data.test_number(match_test_num)),'mode_number',unique(data.test_mode(match_mode_num)),'signal','*','action','REMOVE','comment',entry.comment);
			
		
		for i = length(match_var):-1:1
			
			var = match_var(i);
			
			fprintf(' - Removing %s entries for input signal %s as specified in the template - "%s"\n', num_rows, in_var_names{var},  entry.comment);

			data_edit.signal = in_var_names{var};
			data_edits(end+1) = data_edit;
			
			if all(match_row)				
				data(:,var) = [];		% Remove whole column			
			elseif iscellstr( data.(var))
				data.(var)(match_row) = {''};
			elseif isdatetime( data.(var))
				data.(var)(match_row) = NaT;
			else
				data.(var)(match_row) = NaN;
			end
			
		end
		
	elseif 	strcmpi( entry.action,'mark')
		
		data.questionable_data(match_row) = true;
		
		data_edit.signal = '*';
		data_edit.action = 'MARK';
		data_edits(end+1) = data_edit;
		
% 		warning('Data quality entry %d is set to mark specific signals, which is not valid. Entire test point marked questionable');		
	end
end


% Fix timestamp formats
if isempty(data) 
	% No data left, bail
	return;
end
	
if isempty( data ) || ~istablevar(data,'timestamp') 
	%No Timestamp
elseif isnumeric(data.timestamp)
	data.timestamp = datetime(data.timestamp,'ConvertFrom','posixtime');
elseif iscellstr( data.timestamp) && regexpcmp(data.timestamp{1}, '^\d+_\d+_\d+_\d+:\d+:\d+\.?\d*$')
	data.timestamp = datetime(data.timestamp,'InputFormat','yy_MM_dd_HH:mm:ss.SSS');
elseif iscellstr( data.timestamp) && regexpcmp(data.timestamp{1}, '^\d+:\d+:\d+\.?\d*$')
	data.timestamp = datetime(data.timestamp,'InputFormat','HH:mm:ss.SSS');
else
	try
		data.timestamp = datetime(data.timestamp);
	catch
		error('Unable to parse timestamp in file %s, provided data was %s', file_info.file, data.timestamp{1});
	end
	
end

if avg_data && ~istablevar( data, 'record_duration' )
	data.record_duration =  file_info.average_duration * ones( height(data), 1);
end	


end





