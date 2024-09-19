function eMachine_data_packet_builder( format_file , show_figs)
%ENGINE_DATA_PACKET_BUILDER Summary of this function goes here
%   Detailed explanation goes here


if nargin < 2
	show_figs = 'off';
end

if nargin < 1 || isempty(format_file)
    [format_file, format_path] = uigetfile( {  '*.xlsx;*.xls','Excel Spreadsheet (*.xls, *.xlsx)';'*.*', 'All files (*.*)'},  'Select a format file');
    format_file = [format_path,format_file];
end

if format_file == 0
	return;
end


if ~exist( format_file, 'file' )
	if isdeployed
		errordlg( 'Unable to locate template input file.','eMachine Data Packet Builder Error');
		return;
	else
 		error( 'Unable to locate template input file.');
	end
	
end


[format_path] = fileparts(format_file);

if ~isempty(format_path)
	cd(format_path);
end

out_fldr = 'Output\';
diary off

try
	if exist( out_fldr,'dir')
		rmdir(out_fldr,'s');
	end
	
	mkdir( out_fldr );
	
catch
	if isdeployed
		errordlg( 'Unable to make clean output directory. Verify no files are in use.', 'eMachine Data Packet Builder Error' );
		return;
	else
 		error( 'Unable to make clean output directory.');
	end
end





if ~isdeployed
	eMachine_data_packet_builder_core( format_file, show_figs )
	
else
	
	% Capture Console Output
	diary([out_fldr,'processor_log.txt']);
	
	try
		eMachine_data_packet_builder_core( format_file, show_figs );
	catch err
		errordlg( getReport(err,'extended','hyperlinks','off'),'eMachine Data Packet Builder Error');
		fprintf('--------------- ERROR -----------------\n%s\n',getReport(err));
		
		h = waitbar(0);
		delete(h);
	end
	
end

diary off

end



function eMachine_data_packet_builder_core( format_file, show_figs )

% Disable warnign backtrace
prev_warn = warning('off','backtrace');

%% Create Waitbar - always on top - can be closed
waitbar_hand = waitbar(0,'','Name','eMachine Test Data Processor' );
warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
waitbar_jf = get(handle(waitbar_hand),'JavaFrame');
waitbar_jfw = waitbar_jf.fHG2Client.getWindow;
waitbar_jfw.setAlwaysOnTop(1);

%% Open template file via 
[format_path, format_name, format_ext] = fileparts(format_file);
out_fldr = 'Output\';

if ~isempty( format_path )
	format_path = [format_path,'\'];
end

format_xls = xlseditor(format_file);
format_sheets = format_xls.get_sheets;

%% Verify File has required tabs
if ~ismember( 'eMachine Spec', format_sheets)
	error('Invalid Template File - Missing "eMachine Spec" Tab');
elseif ~ismember( 'Data Format', format_sheets)
	error('Invalid Template File - Missing "Data Format" Tab');
elseif ~ismember( 'Input Files', format_sheets)
	error('Invalid Template File - Missing "Input Files" Tab');
end	
	
%% Output Types - Core & Full
template_labels = {'core','full'};
out_file_labels = {'Test','Full'};

%% Read Basic eMachine Information
fprintf('Reading eMachine Specifications\n');
waitbar(0, waitbar_hand, 'Parsing Template - eMachine Spec');
eMachine = read_eMachine_spec(format_xls);

%% Set Output Folder & Clean it out
out_name = [eMachine.name,' eMachine '];

%% Set location of processor folder (for pdftk & template file)
if isdeployed
	processor_folder = '';
else
	processor_folder = [fileparts(which(mfilename)),'\'];
end

%% Read Info on data naming
fprintf('Reading Data Naming & Formatting\n');

waitbar(0.2, waitbar_hand, 'Parsing Template - Data Format');

format_xls.change_sheet('Data Format')
read_txt = format_xls.read;

% [~,~, read_txt] = xlsread(format_file, 'Data Format');
headers = read_txt(1,:);
replace = cellfun(@isnumeric, headers);
headers(replace) = {''};


parse_format = cell2struct({  
	'Working Name',					'working_name',				'text',		true;
	'Input Units',					'input_units',				'text',		false;
	'Calibration Uncertainty',		'calibration_uncertainty',	'numeric',	false;
	'Operation Uncertainty',		'operation_uncertainty',	'numeric',	false;
	'Stat Type',					'stat_type',				'text',		false;
	'Stat Calc',					'stat_calc',				'text',		false;
	'Stat Working Name',			'stat_working_name',		'text',		false;
	'Stable Threshold',				'stable_threshold',			'numeric',	false;
	'Min Limit',					'min_limit',				'numeric',	false;
	'Max Limit',					'max_limit',				'numeric',	false;
	'Output Name',					'output_name',				'text',		true;
	'Output Units',					'output_units',				'text',		true;
	'Description',					'description',				'text',		false;
	'MEASUREMENT TYPE & STATUS',	'calibration_status',		'text',		false;
	'Display Precision',			'display_precision',		'numeric',	false;
	'Core Data',					'core_data',				'bool',		true;
	'Full Data',					'full_data',				'bool',		true;
	'Core Contour',					'core_contour',				'bool',		true;
	'Full Contour',					'full_contour',				'bool',		true;
	'Contour Levels',				'contour_levels',			'text',		false;
	'Continuous Plot',				'continuous_plot',			'text',		false;
	'Continuous Color',				'continuous_color',			'text',		false;
	'Scatter Plot',					'scatter_plot',				'bool',		false;
	'Plot Min'						'plot_axis_min',			'numeric',	false;
	'Plot Max',						'plot_axis_max',			'numeric',	false}, ...
	{'header',						'out_var',					'type',		'required'}, 2);
	

measurement_types = {	'Sensor Calibrated to a Standard', 'Sensor Verified to a Standard', 'Calculated Value',	'Reference Only - Uncalibrated Sensor',	'Reference Only - Voltage Measurement',	'Reference Only - Digital Measurement',	'Reference Only - CAN Data', 'Reference Only - OBD Data', 'Reference Only - System Generated'};

data_format = template_parser(parse_format, read_txt, 'Data Format');

input_name_fields_idx = regexpcmp(headers, 'INPUT NAME.*','ignorecase');
bad_format = false( length(data_format), 1);

for f = 1:length(	data_format)
	
	% Clean up working name
	data_format(f).working_name = strtrim( data_format(f).working_name);
	
	input_names = read_txt(f+1,input_name_fields_idx);
	
	input_names_txt = cellfun( @ischar, input_names);
	
	input_names_num = cellfun( @isnumeric, input_names);
 	input_names_num(input_names_num) = ~cellfun( @isnan, input_names(input_names_num));	
	
	input_names(input_names_num) = strcat('COLUMN_', cellfun( @num2str, input_names(input_names_num),'UNiformOutput',false));
	
	input_names_keep = input_names_txt | input_names_num;
		
    input_names =  strtrim(input_names(input_names_keep));
	has_input_name = ~isempty( input_names );
	data_format(f).input_names = input_names;
	
	if ~isempty( data_format(f).working_name )
		if ~isvarname( strrep(data_format(f).working_name,'*','_'))
			error('Invalid working name "%s" in template data format row %d ', data_format(f).working_name, data_format(f).idx + 1);
		elseif any( strcmp( data_format(f).working_name, {data_format(1:f-1).working_name} ))
			error('Multiple template entries with identical working name: %s', data_format(f).working_name);
		end
	elseif ~isempty(data_format(f).stat_type)
		data_format(f).working_name = strcat(data_format(f).stat_working_name, '_', data_format(f).stat_calc );
	elseif has_input_name
		data_format(f).working_name = strcat('z_',regexprep( data_format(f).input_names{1} , '[^A-Za-z0-9_*]','_'));
	elseif ~isempty( data_format(f).output_name )
		warning('Omitting template data format row %d, it has output name %s, but no connection to input data' , data_format(f).idx + 1, data_format(f).output_name);
		bad_format(f) = true;
		continue;
	else	
		bad_format(f) = true;
		continue;
	end
	
	data_format(f).calibration_status = strrep( data_format(f).calibration_status, char(150), char(45) );	
	if ~ismember( data_format(f).calibration_status, measurement_types )
		warning('Non-standard measurement type "%s" for output signal %s, in data format row %d, ', data_format(f).calibration_status, data_format(f).output_name, data_format(f).idx + 1 );
	end
	
	data_format(f).is_catch_all = any(strcmpi( data_format(f).input_names,'*'));
	data_format(f).is_cont_calc = strcmpi(data_format(f).stat_type,'CONT');
	data_format(f).is_point_calc = strcmpi(data_format(f).stat_type,'TEST');
	data_format(f).is_wildcard =	contains( data_format(f).working_name ,'*') || contains( data_format(f).output_name ,'*') || any(contains( input_names ,'*')) ;
		
	data_format(f).load_avg = has_input_name;
	data_format(f).load_cont = has_input_name & ~(data_format(f).is_cont_calc);
		
end


data_format(bad_format) = [];

% Clean up any bad working names
working_names = {data_format.working_name};
working_names = regexprep( working_names, '[^A-Za-z0-9_*]','_');
working_name_empty = cellfun(@isempty, working_names);

% Clean up any autofills that may have collided
working_names = matlab.lang.makeUniqueStrings(working_names, working_name_empty ,63);

if any( regexpcmp(working_names,'injector.*_pulse.*_duration_ms'))  && ( any( regexpcmp(working_names,'pfi.*_pulse.*_duration_ms')) || any( regexpcmp(working_names,'gdi.*_pulse.*_duration_ms')) )
	error('Invalid template, injector data should contain prefix "injector" or "gdi" and/or "pfi".');
end

[data_format.working_name] = working_names{:};


%% Load List of Files
fprintf('Reading Input Data Files List\n');

waitbar(0.6, waitbar_hand, 'Parsing Template - Input File List');

format_xls.change_sheet('Input Files')
read_txt = format_xls.read;

parse_files = cell2struct({  
	'File',				'file',					'text',		true;
	'Data Type',		'data_type',			'text',		true;
	'Sheet',			'sheet',				'text',		false;
	'Delimiter',		'delimiter',			'text',		false;
	'Variable Line',	'variable_line',		'numeric',	false;
	'Unit Line',		'unit_line',			'numeric',	false;
	'Data Line',		'data_line',			'numeric',	false;
	'Average Duration',	'average_duration',		'numeric',	false;
	'Export',			'export',				'bool',		false}, ...
	{'header',			'out_var',				'type',		'required'}, 2);


data_files = template_parser(parse_files, read_txt, 'Input Files');


%% Expand Directory Entries
d = 1;
while d  <= numel(data_files)
    
	if isempty( data_files(d).file )
		 data_files(d) = [];
		 continue;
	end
	
	data_files(d).file = strtrim( data_files(d).file);
	
    % prepend path to format file
    if ~regexpcmp( data_files(d).file, '^[A-Z]:\') && ~isempty(format_path)
        data_files(d).file = strcat( format_path, data_files(d).file);
    end
       
	data_files(d).data_type = strtrim(upper(data_files(d).data_type));
	if ~ismember( data_files(d).data_type, {'SS CONT','SS CONT TXMN','SS AVG','SS AVG TXMN','HL', 'HLI','HLF', 'MAX', 'MIN'})
		error('File type specified for %s is invalid, it should be SS CONT, SS AVG, HL, MAX or MIN', data_files(d).file ) ;		
	elseif isempty( data_files(d).file )		
		data_files(d) = [];
	elseif isdir(data_files(d).file) || contains(data_files(d).file,'*')
		sub_file_list = dir(data_files(d).file);
		new_file_entries = repmat(data_files(d),numel(sub_file_list)-2,1);
		
		for i = 1:length(new_file_entries)
			new_file_entries(i).file = [data_files(d).file,'/',sub_file_list(i+2).name];
		end
		
		data_files(d) = [];
		data_files = vertcat( data_files, new_file_entries);		
	else
		d = d+1;		
	end
	
end

%% Load Data Quality Notes
if ~ ismember('Data Quality Notes', format_xls.get_sheets)
	
	data_edits = struct('file',{},'test_number',{},'mode_number',{}, 'signal',{}, 'action',{}, 'comment',{});
	fprintf('No Data Quality Notes Tab - Skipping\n');
	
else
	fprintf('Reading Data Quality Notes\n');
	waitbar(0.7, waitbar_hand, 'Parsing Template - Data Quality Notes');
	
	format_xls.change_sheet('Data Quality Notes')
	read_txt = format_xls.read;
	
	parse_notes = cell2struct({  
	'File',				'file',					'text',		true;
	'Test Number',		'test_number',			'text',		true;
	'Mode Number',		'mode_number',			'text',		true;
	'Signal',			'signal',				'text',		true;
	'Action',			'action',				'text',		true;
	'Comment',			'comment',				'text',		true}, ...
	{'header',			'out_var',				'type',		'required'}, 2);


	data_edits = template_parser(parse_notes, read_txt, 'Data Quality Notes');

end

%% Read Custom Calculations

if ~ ismember('Custom Calculations', format_xls.get_sheets)
	
	custom_calcs = struct('output_signal',{},'expression',{});
	fprintf('No Custom Calculations Tab - Skipping\n');
	
else
	fprintf('Reading Custom Calculations\n');	
	waitbar(0.8, waitbar_hand, 'Parsing Template - Custom Calculations');
	
	format_xls.change_sheet('Custom Calculations')
	read_txt = format_xls.read;
	
	parse_calcs = cell2struct({  
	'Output Signal',			'output_signal',		'text',		true;
	'Calculation Expression',	'expression',			'text',		true}, ...
	{'header',					'out_var',				'type',		'required'}, 2);


	custom_calcs = template_parser(parse_calcs, read_txt, 'Custom Calculations');

end

%% Close template file
format_xls.close;

waitbar(1.0, waitbar_hand, 'Parsing Template - Complete');


%% Create destination for all the data
merged_data = table({''},0,0,'VariableNames',{'data_type','speed_rpm','torque_Nm'});
merged_data = merged_data([],:);


%% Process Steady State Averaged Data	

waitbar(0.0, waitbar_hand, 'Loading Steady State Data');

ss_avg_files = find(ismember({data_files.data_type}, {'SS AVG', 'SS AVG TXMN'} ));
count = 0;

for d = ss_avg_files
	
	[data,applied_edits] = load_data_file( data_files(d), data_format, data_edits, true );
	[data,applied_edits2] = apply_limits( data, data_format);
	
	if ~isempty( data)
	
		if istablevar( data, 'exhaust_lambda') && any( data.exhaust_lambda < 0.96 )
			rich_pts = data.exhaust_lambda < 0.96;
			rich_tests = sprintf('\t- Test Number: %4.0f Test Mode: %4.0f Exhaust Lambda: %f\n',[data.test_number(rich_pts),data.test_mode(rich_pts),data.exhaust_lambda(rich_pts)]');
			fprintf(' - Steady State Data file contains rich exhaust measurements (lambda < 0.96)\n%s', rich_tests)
		end
						
		data(:,'data_type') = upper({data_files(d).data_type});	
 		merged_data = outerjoin(merged_data, data,'MergeKeys',true);
%		merged_data = concatenate_data(merged_data, data);
	
	end
	
	count = count + 1;
	waitbar(count / length(ss_avg_files), waitbar_hand);
	
end    

%% Process Steady State Continuous Data

% TODO:
ss_cont_files = find(strcmpi({data_files.data_type}, 'SS CONT' ));

%% Process Max Torque 
max_files = find(strcmpi({data_files.data_type}, 'MAX' ));

% Default to no data
max_torque_data = []; 
max_torque_pdf = '';
max_torque_emf = '';

if numel(max_files) > 1
	error('eMachine data packet builder can only handle a single maximum torque sweep test');
end
	
if ~isempty( max_files)	
	waitbar(0.0, waitbar_hand, 'Process Maximum Torque Data');
		
	d = max_files;
		
	[raw_data ,applied_raw_edits] = load_data_file( data_files(max_files), data_format, data_edits, false );
	[raw_data, applied_raw_edits]= apply_limits( raw_data, data_format);

	waitbar(0.3, waitbar_hand);
	
	raw_data = add_injector_flow( raw_data, inj_cal, eMachine );
	raw_data = add_continuous_calcs( raw_data, eMachine);

	[raw_data, data] = process_max_torque( raw_data, data_format, data_files(max_files).file, eMachine, show_figs );

	waitbar(0.5, waitbar_hand);
	
	if ~isempty( data )
			
		[data,applied_edits] = apply_limits( data, data_format);
		
		raw_data(:,'data_type') = {'MAX-raw'};
		
		max_torque_data = data;
		data(:,'data_type') = {'MAX'};
		
		merged_data = outerjoin(merged_data, raw_data,'MergeKeys',true);
		merged_data = outerjoin(merged_data, data,'MergeKeys',true);
				
		max_torque_emf = [out_fldr, 'Max Torque Sweep.emf'];
		print_emf( max_torque_emf );
		waitbar(0.7, waitbar_hand);
		
		max_torque_pdf = [out_fldr, 'max_torque_temp.pdf'];
		print_pdf_usletter_landscape(max_torque_pdf );
		waitbar(0.9, waitbar_hand);
		
		close(gcf);
		
	end
	
	waitbar(1.0, waitbar_hand);	
end

%% Process Min Torque 
min_files = find(strcmpi({data_files.data_type}, 'MIN' ));
	
% Defaul tot no data
min_torque_data = []; 
min_torque_pdf = '';
min_torque_emf = '';

if numel(min_files) > 1
	error('eMachine data packet builder can only handle a single minimum torque sweep test');
end

if ~isempty( min_files )
	waitbar(0.0, waitbar_hand, 'Process Minimum Torque Data');
	
	[raw_data ,applied_raw_edits] = load_data_file( data_files(min_files), data_format, data_edits, false );
	[raw_data, applied_raw_edits]= apply_limits( raw_data, data_format);
	
	waitbar(0.3, waitbar_hand);
	
	raw_data = add_injector_flow( raw_data, inj_cal, eMachine );
	raw_data = add_continuous_calcs( raw_data, eMachine);
	
	[raw_data, data] = process_min_torque( raw_data, data_format, data_files(min_files).file, eMachine, show_figs );
	
	waitbar(0.5, waitbar_hand);
	
	if ~isempty( data )
		[data, applied_edits] = apply_limits( data, data_format);
		
		raw_data(:,'data_type') = {'MIN-raw'};
		
		min_torque_data = data;
		data(:,'data_type') = {'MIN'};
		
		merged_data = outerjoin(merged_data, raw_data,'MergeKeys',true);
		merged_data = outerjoin(merged_data, data,'MergeKeys',true);
				
		min_torque_emf = [out_fldr, 'Min Torque Sweep.emf'];
		print_emf( min_torque_emf );
		waitbar(0.7, waitbar_hand);
		
		min_torque_pdf = [out_fldr, 'min_torque_temp.pdf'];
		print_pdf_usletter_landscape(min_torque_pdf );
		waitbar(0.9, waitbar_hand);
		
		close(gcf);
		
	end
	
	waitbar(1.0, waitbar_hand);
end


%% Process High Load Files
hl_files = find(ismember({data_files.data_type}, {'HL','HLI','HLF'} ));

if ~isempty(hl_files)
	waitbar(0.0, waitbar_hand, 'Process High Load Data');
	
	if isempty( inj_cal )
		error('Cannot process high load test files without an injector calibration.');
	end
	
	count = 0;
	
	if isnan(eMachine.max_fuel_press ) && istablevar( merged_data, 'fuel_rail_press')
		eMachine.max_fuel_press = max( merged_data.fuel_rail_press) * 1.15 ;
	end

	
	for d = hl_files
		
		[raw_data,applied_raw_edits2] = load_data_file( data_files(d), data_format, data_edits, false );		
		[raw_data,applied_raw_edits2] = apply_limits( raw_data, data_format);
		
		if isempty( raw_data ) 
			continue;
		end
		
		raw_data = add_injector_flow( raw_data, inj_cal, eMachine );
		raw_data = add_continuous_calcs( raw_data, eMachine);
		raw_data = calc_point_stats(raw_data, data_format);	

		data = process_high_load(raw_data, data_format, data_files(d).file, data_files(d).data_type, eMachine, show_figs ) ;
		
		[data,applied_edits2] = apply_limits( data, data_format);
		
		if data_files(d).export
			[in_path, in_file, in_ext] = fileparts( data_files(d).file );
			out_file = [out_fldr,in_file,'.mat'];
			save(out_file,'data','raw_data');
		end
			
		if ~isempty( data )
			merged_data = outerjoin(merged_data, data,'MergeKeys',true);
			add_plot_date
			
			test_spd = 50* round(data.speed_rpm(1)/50);
			test_trq = round( data.torque_Nm(1));
			
			print_pdf_usletter_portrait( sprintf('%shigh_load_temp_%04d_%03d.pdf',out_fldr,test_spd, test_trq));
			close(gcf);
		end
		
		count = count + 1;
		waitbar(0.95 * count / length(hl_files), waitbar_hand);
		
	end
	
	pdf_merge_command = sprintf('"%spdftk" "%shigh_load_temp_*.pdf" output "%s%s - High Load Transient.pdf"',processor_folder,out_fldr,out_fldr, out_name);
	system(pdf_merge_command);
	delete( sprintf('%shigh_load_temp_*.pdf',out_fldr));
	
	waitbar(1.0, waitbar_hand);
end

%% Add Calculated Channels & merge formatting info
waitbar(0.0, waitbar_hand, 'Adding Calculated Channels');

merged_data = add_base_calcs(merged_data, data_format);
waitbar(0.3, waitbar_hand);

merged_data = calc_point_stats( merged_data, data_format);
waitbar(0.5, waitbar_hand);


merged_data = add_custom_calcs( merged_data, custom_calcs);
waitbar(0.7, waitbar_hand);

% Apply Data Formatting
merged_data = format_data_columns( merged_data, data_format);


%% Adjust plot boundaries (scalars) based on data set as well
plot_bound.min_speed_rpm = 0 * min(merged_data.speed_rpm);
plot_bound.max_speed_rpm = 1.05* max( max( merged_data.speed_rpm), eMachine.max_speed_rpm);
plot_bound.max_torque_Nm = 1.05 * max( max(merged_data.torque_Nm), eMachine.max_torque_Nm);
plot_bound.min_torque_Nm = 1.05 * min(0,min(merged_data.torque_Nm));

waitbar(1.0, waitbar_hand);

%%	Write Core and Full Spreadsheets
for l = 1:length(template_labels)
    
	template_label = template_labels{l};
    out_file_label = out_file_labels{l};
    out_filename = [out_fldr,out_name,' - ', out_file_label, ' Data.xlsx',];    
	
	fprintf('Creating %s Data File (%s)\n',template_label, out_filename);
	   
	waitbar(0.0, waitbar_hand, ['Writing ', out_file_label, ' Data Spreadsheet']);
	
	% Open Excel 
    out_xls = xlseditor(out_filename);
    
	if strcmpi( show_figs, 'on')
		out_xls.show_excel;
	end
		
    select_vars = [merged_data.Properties.UserData.([template_label,'_data'])] > 0 ;    
	select_data = merged_data(:,select_vars);
	select_data.Properties.UserData = select_data.Properties.UserData(select_vars);
	
	total_tests = height( merged_data);
	proc_tests = 0;
    
	sel_tests = ismember( merged_data.data_type, {'SS AVG', 'SS CONT'} );
	if any(sel_tests)
		fprintf(' - Writing Steady State Averaged Data\n');
		sel_data = sort_data_rows( select_data(sel_tests,:) );
		sel_data = remove_blank_columns( sel_data );
		write_data_tab( out_xls, 'Steady State', sel_data, eMachine, out_file_label);
	end
	
	proc_test = proc_tests + sum(sel_tests);
	waitbar(0.9*proc_test/total_tests , waitbar_hand);
	
	sel_tests = ismember( merged_data.data_type, {'SS AVG TXMN', 'SS CONT TXMN'} );
	if any(sel_tests)
		fprintf(' - Writing Steady State With Transmission Averaged Data\n');
		sel_data = sort_data_rows( select_data(sel_tests,:) );
		sel_data = remove_blank_columns( sel_data );
		write_data_tab( out_xls, 'Steady State with Transmission', sel_data, eMachine, out_file_label);
	end
	
	proc_test = proc_tests + sum(sel_tests);
	waitbar(0.9*proc_test/total_tests , waitbar_hand);
	
	sel_tests = strcmpi( merged_data.data_type,'HL-initial');
	if any(sel_tests)
		fprintf(' - Writing High Load Transient Initial Data\n');
		sel_data = sort_data_rows(select_data(sel_tests,:));
		sel_data = remove_blank_columns( sel_data );
		write_data_tab( out_xls, 'High Load Initial', sel_data, eMachine, out_file_label);
	end
	
	proc_test = proc_tests + sum(sel_tests);
	waitbar(0.9*proc_test/total_tests , waitbar_hand);
	
	sel_tests = strcmpi( merged_data.data_type,'HL-final');
	if any(sel_tests)
		fprintf(' - Writing High Load Transient Final Data\n');
		sel_data = sort_data_rows(select_data(sel_tests,:));
		sel_data = remove_blank_columns( sel_data );
		write_data_tab( out_xls, 'High Load Final', sel_data, eMachine, out_file_label);
	end
	
	proc_test = proc_tests + sum(sel_tests);
	waitbar(0.9*proc_test/total_tests , waitbar_hand);
	
	sel_tests = strcmpi( merged_data.data_type,'MAX');
	if any(sel_tests)
		fprintf(' - Writing Maximum Torque Sweep Data\n');	
		sel_vars = ismember(select_data.Properties.VariableNames, {'speed_rpm','torque_Nm','bmep_bar','meter_fuel_flow_gps','injector_fuel_flow_gps'} );
		sel_data = sort_data_rows(select_data(sel_tests,sel_vars));
		write_data_tab( out_xls, 'Max Torque Sweep', sel_data, eMachine, out_file_label);
	end

	proc_test = proc_tests + sum(sel_tests);
	waitbar(0.9*proc_test/total_tests , waitbar_hand);
	
	sel_tests = strcmpi( merged_data.data_type,'MAX-raw');
	if any(sel_tests) && strcmpi( template_label, 'FULL' ) 
		fprintf(' - Writing Maximum Torque Sweep Raw Data\n');		
		sel_data = sort_data_rows(select_data(sel_tests,:));
		sel_data = remove_blank_columns( sel_data );
		write_data_tab( out_xls, 'Max Torque Sweep - Raw', sel_data, eMachine, out_file_label);
	end
	
	proc_test = proc_tests + sum(sel_tests);
	waitbar(0.9*proc_test/total_tests , waitbar_hand);
	
	sel_tests = strcmpi( merged_data.data_type,'MIN');
	if any(sel_tests)
		fprintf(' - Writing Minimum Torque Sweep Data\n');	
		sel_vars = ismember(select_data.Properties.VariableNames, {'speed_rpm','torque_Nm','bmep_bar','meter_fuel_flow_gps','injector_fuel_flow_gps'} );
		sel_data = sort_data_rows(select_data(sel_tests,sel_vars));
		write_data_tab( out_xls, 'Min Torque Sweep', sel_data, eMachine, out_file_label);
	end
	
	proc_test = proc_tests + sum(sel_tests);
	waitbar(0.9*proc_test/total_tests , waitbar_hand);

	sel_tests = strcmpi( merged_data.data_type,'MIN-raw');
	if any(sel_tests) && strcmpi( template_label, 'FULL' ) 
		fprintf(' - Writing Minimum Torque Sweep Raw Data\n');		
		sel_data = sort_data_rows(select_data(sel_tests,:));
		sel_data = remove_blank_columns( sel_data );
		write_data_tab( out_xls, 'Min Torque Sweep - Raw', sel_data, eMachine, out_file_label);
	end
	
	waitbar(0.9, waitbar_hand);
	
    % Generate parameter list tab with variable descriptions
	fprintf(' - Writing Parameter List & Details\n');	
    write_param_tab( out_xls, 'Test Parameter List', select_data, eMachine, out_file_label)
	
	% Remove Sheet1
	out_xls.delete_sheet('Sheet1');	
    out_xls.close(1);
    
	waitbar(1.0, waitbar_hand);
	
end



%% Create Contour Plot Sets

waitbar(0.0, waitbar_hand, ['Creating Contour Plots']);

contour_sets = [];
ss_data_types = {'SS AVG','SS CONT','SS AVG TXMN'};

if any( strcmpi( merged_data.data_type, 'HL-initial'))
	contour_sets(end+1).data_select(1).variable = 'data_type';
    contour_sets(end).data_select(1).values = {ss_data_types{:},'HL-initial'};
    contour_sets(end).label = 'Steady State and High Load Initial';
end

if any( strcmpi( merged_data.data_type, 'HL-final'))
	contour_sets(end+1).data_select(1).variable = 'data_type';
    contour_sets(end).data_select(1).values = {ss_data_types{:},'HL-final'};
    contour_sets(end).label = 'Steady State and High Load Final';
end

if isempty( contour_sets)
	contour_sets(1).data_select(1).variable = 'data_type';
    contour_sets(1).data_select(1).values = ss_data_types;
    contour_sets(1).label = 'Steady State';
end

% if all(ismember( {'HL-final','HL-initial'},  merged_data.data_type ) )
%     contour_sets(1).data_select(1).variable = 'data_type';
%     contour_sets(1).data_select(1).values = {'SS AVG','SS CONT','SS AVG TXMN','HL-initial'};
%     contour_sets(1).label = 'Steady State and High Load Initial';
% 	
% 	contour_sets(2).data_select(1).variable = 'data_type';
%     contour_sets(2).data_select(1).values = {'SS AVG','SS CONT','SS AVG TXMN','HL-final'};
%     contour_sets(2).label = 'Steady State and High Load Final';
% else   
%     contour_sets(1).data_select(1).variable = 'data_type';
%     contour_sets(1).data_select(1).values = {'SS AVG','SS CONT','SS AVG TXMN','HL-final'};
%     contour_sets(1).label = 'Steady State';
% end


if istablevar( merged_data,'cylinder_deac_bool')
    %Duplicate to make with and without deac
    deac_sets = contour_sets;
    non_deac_sets = contour_sets;  
    
	for c = 1:length(contour_sets)        
        deac_sets(c).data_select(end+1).variable = 'cylinder_deac_bool';
        deac_sets(c).data_select(end).values = 1;
        deac_sets(c).label = sprintf('%s - Cylinder Deactivation Enabled', contour_sets(c).label );
        
        non_deac_sets(c).data_select(end+1).variable = 'cylinder_deac_bool';
        non_deac_sets(c).data_select(end).values = 0;
        non_deac_sets(c).label = sprintf('%s - Cylinder Deactivation Disabled', contour_sets(c).label );      
    end
    
    contour_sets =  [ non_deac_sets, deac_sets];    
end

select_vars = all(cellfun(@isnumeric, table2cell(merged_data)),1) & ( [merged_data.Properties.UserData.core_contour] | [merged_data.Properties.UserData.full_contour]) ;
plot_data = merged_data(:,select_vars);
plot_data.Properties.UserData = plot_data.Properties.UserData(select_vars);

contour_pdfs = {};

cont_fldr = [out_fldr,'Contour Plots\'];
mkdir( cont_fldr );

for c = 1:length(contour_sets)
    
    contour_set = contour_sets(c);
    
    sel_points = true(height(plot_data), 1);
    for s = 1:numel( contour_set.data_select)
		sel_points = sel_points & ismember(merged_data.(contour_set.data_select(s).variable),contour_set.data_select(s).values);
    end
    
	if ~any(sel_points)
		continue;
	end
    	
    nice_label = regexprep( contour_set.label, '\s*',' ');
    fprintf('Creating %s Contour Plot Set\n',nice_label);
    waitbar(0.0, waitbar_hand, ['Creating ', nice_label, ' Contour Plots']);
	
    % Make contour plots
	out_pdf = create_contour_plots(merged_data.speed_rpm(sel_points), merged_data.torque_Nm(sel_points), merged_data.data_type(sel_points), plot_data(sel_points,:), plot_bound, cont_fldr, eMachine, max_torque_data, min_torque_data, contour_set.label, show_figs);
    contour_pdfs = [contour_pdfs; out_pdf'];
	
end


%% Merge to appropriate contour pdfs
waitbar(0.0, waitbar_hand, 'Merging Contour Plot Sets');

for l = 1:length(out_file_labels)
	
	template_label = template_labels{l};
	out_file_label = out_file_labels{l};
	out_file = [ out_file_label, '_contour_temp.pdf'];
	
	fprintf('Merging %s Contour Plots \n', out_file_label);
		
	% Select which files to merge
	keep_idxs = [plot_data.Properties.UserData.([template_label,'_contour'])];
	keep_files = contour_pdfs(:,keep_idxs);
	keep_files = keep_files(:);
	
	merge_pdfs( keep_files, out_fldr, out_file, processor_folder );
	waitbar(l/length(out_file_labels), waitbar_hand);
	
end


%% Make plots of test data points & test number & mode number

	waitbar(0.0, waitbar_hand, 'Plotting Test Points & Numbers');

	data_types = setdiff(unique(merged_data.data_type), {'MAX-raw','MIN-raw'});	
	sel_pts = ismember( merged_data.data_type, data_types);
	ax = plot_data_points(merged_data.data_type(sel_pts),  merged_data.speed_rpm(sel_pts), merged_data.torque_Nm(sel_pts), eMachine, plot_bound, show_figs  );
	
	add_plot_date
	grid on

	% Save as EMF
% 	print_emf( [out_fldr,'Test Points.emf'] , [6,4.5]);

	% Save as PDF
	print_pdf_usletter_landscape( [out_fldr,'Test_points_temp.pdf']);
		
	waitbar(0.25, waitbar_hand);
	
	% Label Test Number
	label_pts = sel_pts &  ~isnan(merged_data.test_number);	
	label_str = strsplit( sprintf('%d$',merged_data.test_number(label_pts)),'$');		
	label_hand = text(  merged_data.speed_rpm(label_pts), merged_data.torque_Nm(label_pts),  label_str(1:end-1) , 'HorizontalAlignment','Left','VerticalAlignment','Bottom');
	title(ax,sprintf('%s\nTest Numbers\n',eMachine.plot_title),'interpreter','none','FontSize',12);
	
	% Save as EMF
% 	print_emf( [out_fldr,'Test Number.emf'] , [6,4.5]);

	% Save as PDF
	print_pdf_usletter_landscape( [out_fldr,'test_number_temp.pdf']);
	
	waitbar(0.5, waitbar_hand);
	
	% Remove Label
	delete(label_hand);
	
	% Label Test Mode
	label_pts = sel_pts &  ~isnan(merged_data.test_mode);	
	label_str = strsplit( sprintf('%d$',merged_data.test_mode(label_pts)),'$');		
	label_hand = text(  merged_data.speed_rpm(label_pts), merged_data.torque_Nm(label_pts),  label_str(1:end-1) , 'HorizontalAlignment','Left','VerticalAlignment','Bottom');
	title(ax, sprintf('%s\nTest Mode Numbers\n',eMachine.plot_title),'interpreter','none','FontSize',12);
	
	% Save as EMF
% 	print_emf( [out_fldr,'Test Mode Number.emf'] , [6,4.5]);

	% Save as PDF
	print_pdf_usletter_landscape( [out_fldr,'test_mode_temp.pdf']);
	
	close(gcf);
	waitbar(0.75, waitbar_hand);

	% Plot All Data Points (For Full)
	ax = plot_data_points(merged_data.data_type,  merged_data.speed_rpm, merged_data.torque_Nm, eMachine, plot_bound, show_figs  );
	
	add_plot_date
	grid on

	% Save as EMF
% 	print_emf( [out_fldr,'Full Points.emf'] , [6,4.5]);

	% Save as PDF
	print_pdf_usletter_landscape( [out_fldr,'Full_points_temp.pdf']);
	
	close(gcf);	
	waitbar(1.0, waitbar_hand);
	

%% Setup Title / Legend Page & Other PDFS for Merging

waitbar(0.0, waitbar_hand, 'Merge PDF Output Files');

for l = 1:length(out_file_labels)
	
	out_file_label = out_file_labels{l};
	out_file = sprintf( '%s - %s Data Plots.pdf', out_name, out_file_label);
	
	fprintf('Merging %s Data Plot Set (%s)\n', out_file_label, out_file);

	legend_pdf = [out_fldr,'legend_temp.pdf'];
	contour_pdf = [out_fldr, out_file_label, '_contour_temp.pdf'];
	test_pts_pdf = [out_fldr,out_file_label,'_points_temp.pdf'];
	test_number_pdf = [out_fldr,'test_number_temp.pdf'];
	test_mode_pdf = [out_fldr,'test_mode_temp.pdf'];
	
	if strcmpi( out_file_label, 'Full')
		pdf_list = {legend_pdf, test_pts_pdf, test_number_pdf, test_mode_pdf, contour_pdf, max_torque_pdf, min_torque_pdf}';
		legend_data_types = unique(merged_data.data_type);	
	else
		pdf_list = {legend_pdf, test_pts_pdf, contour_pdf}';
		legend_data_types = setdiff(unique(merged_data.data_type), {'MAX-raw','MIN-raw'});	
	end
	
	% Create Legend
	create_legend_page(eMachine, legend_data_types,  format_path ,legend_pdf,  true, out_file_label, show_figs );	
		
	% Merge all the files
	merge_pdfs( pdf_list, out_fldr, out_file, processor_folder );
	waitbar(l/length(out_file_labels), waitbar_hand);
	
end

% Clear temporary files
pause(0.5);
delete( sprintf('%s*.pdf',cont_fldr));
delete( sprintf('%scontour_merge_*.pdf',out_fldr));

%% Zip all EMF files into one package
waitbar(0.0, waitbar_hand, 'Zip EMF Output Files');

out_file = sprintf( '%s%s - Plot EMFs.zip',out_fldr, out_name);

fprintf('Zipping Plot Image EMFs (%s)\n',out_file);
zip(out_file,{'*.emf';'Contour Plots\*.emf'},out_fldr);

waitbar(1.0, waitbar_hand);

%% Clean Up

delete([out_fldr, '*_temp.pdf' ]);
delete([out_fldr,'*.emf']);
delete([out_fldr,'*.fig']);
rmdir([out_fldr,'Contour Plots'],'s');

%% Restore previous warning state
warning(prev_warn);

waitbar(1.0, waitbar_hand, 'Complete!');
pause(0.5);

end

function merge_pdfs( in_pdfs, out_fldr, out_pdf, processor_folder )

in_pdfs( cellfun(@isempty, in_pdfs)) = [];

if numel(in_pdfs) > 60
	
	contour_merge_pdfs ={};
	
	% Merge Files into groups of 50 to avoid command line length limits
	for chunk_start = 1:50:numel(in_pdfs)
		chunk_end = min(chunk_start + 49, numel(in_pdfs));
		chunk_pdfs = sprintf(' "%s"', in_pdfs{chunk_start:chunk_end});
		contour_merge_pdfs{end+1} = sprintf( '%scontour_merge_%03d.pdf',out_fldr, chunk_start);
		
		pdf_merge_command = sprintf( '"%spdftk" %s output "%s"',processor_folder, chunk_pdfs, contour_merge_pdfs{end} );
		[s,m] = system(pdf_merge_command);
		if s
			warning('PDF merge error %s',m);
		end
	end
	
else
	contour_merge_pdfs = in_pdfs;
end

% Add quotes
contour_merge_pdfs = sprintf(' "%s"', contour_merge_pdfs{:});


% Merge all the files
pdf_merge_command = sprintf( '"%spdftk" %s output "%s%s"',processor_folder, contour_merge_pdfs ,out_fldr,out_pdf );
[s,m] = system(pdf_merge_command);

if s
	warning('PDF merge error %s',m);
end

end


function e = read_eMachine_spec(format_xls)


format_xls.change_sheet('eMachine Spec');

% [~,~, read_txt] = xlsread(format_file, );

read_txt = format_xls.read;
read_txt = read_txt(:,1:2)';

parse_format = cell2struct({  
	'Model Year'					'model_year',				'text'			true
	'Manufacturer'					'manufacturer'				'text'			true
	'Model / Family'                'model'                     'text'          true
    'Number of Pole Pairs'			'pole_pairs'			    'numeric'		false
	'Max Power [kW]'				'max_power_kW'				'numeric'		false
	'Max Torque [Nm]'				'max_torque_Nm'				'numeric'		true
	'Max Speed [RPM]'		        'max_speed_rpm'		        'numeric'		true
    'Base Speed [RPM]'		        'base_speed_rpm'	        'numeric'		false
	'Source Data Citation'			'source_citation'			'text'			false
	'Message'						'message'					'text'			false }, ...
	{'header',						'out_var',				'type',		'required'}, 2);

e = template_parser(parse_format, read_txt, 'eMachine Spec');



%% map input table data to eMachine struct

e.name = sprintf( '%s %s %s', e.model_year, e.manufacturer, e.model);

e.citation = ['SUGGESTED CITATION: ' e.name ' - Test Data Package. Version ' char(datetime(date,'Format','y-MM')) '. Ann Arbor, MI: US EPA, National Vehicle and Fuel Emissions Laboratory, Advanced Technology Assessment Branch, ' char(datetime(date,'Format','y')), '.'];
e.plot_title = [e.name ' - Test Data Plots'];


%get wot
if ismember('Published WOT',format_xls.get_sheets)

	format_xls.change_sheet('Published WOT');
	read_txt = format_xls.read;
	
	parse_format = cell2struct({  
	'Speed (rpm)'		'speed_rpm',	'numeric'		true
	'Torque (Nm)'		'torque_Nm'		'numeric'		true }, ...
	{'header',			'out_var',		'type',		'required'}, 2);

	wot = template_parser(parse_format, read_txt, 'Published WOT');

    e.published_wot_speed_rpm = [wot.speed_rpm]';
    e.published_wot_torque_Nm = [wot.torque_Nm]';
	power_kW = (e.published_wot_speed_rpm .* convert.rpm2radps .* e.published_wot_torque_Nm )/1000;
	
	if isempty( e.max_power_kW ) || isnan( e.max_power_kW)
		[e.max_power_kW, idx] = max(power_kW );
		e.max_power_speed_rpm = e.published_wot_speed_rpm(idx);
	end
	
	if isempty( e.max_torque_Nm ) || isnan( e.max_torque_Nm)
		[e.max_torque_Nm, idx] = max(e.published_wot_torque_Nm);
		e.max_power_speed_rpm = e.published_wot_speed_rpm(idx);
	end
	
else
	e.published_wot_speed_rpm = [];
    e.published_wot_torque_Nm = [];
	
end

end


function data = sort_data_rows( data)

data_sort = data(:,{'speed_rpm','torque_Nm'});
data_sort.speed_rpm = 100* round(data.speed_rpm / 100);

[~, sort_idx] = sortrows( [ 100* round(data.speed_rpm / 100), data.torque_Nm ] );
data = data(sort_idx,:);

end


function data = remove_blank_columns( data )

	empty_vars = varfun( @isblankvar, data);
	empty_vars = empty_vars.Variables;
	data = data(:,~empty_vars);
	data.Properties.UserData = data.Properties.UserData(~empty_vars);

	function tf = isblankvar(v)	
			if isnumeric(v)
				tf = all( isempty(v) | isnan(v) );
			else
				tf = all(isempty(v));
			end		
	end
	
end

