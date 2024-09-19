function out_data = format_data_columns( in_data, data_format)

% [var_sort_idx] = select_sort_var_names( data.Properties.VariableNames, data_format);
% data = data(:,var_sort_idx);
% 

% Remove Empty Columns

for i = width(in_data):-1:1
	if ismember(in_data.Properties.VariableNames{i},{'test_number','test_mode','speed_rpm','torque_Nm'} )
		% always keep
	elseif isnumeric(in_data{:,i}) && all( isnan( in_data{:,i} ) )
		in_data(:,i) = [];
	elseif iscellstr(in_data{:,i}) && all( cellfun(@isempty, in_data{:,i} ))
		in_data(:,i) = [];
	elseif isdatetime( in_data{:,i}) && all(isnat(in_data{:,i}))
		in_data(:,i) = [];
	end	
end

out_data = table;
out_props = [];

sort_idx = nan(1,width(in_data));

for f = 1:numel(data_format)

	format = data_format(f);
	
	WorkingNameSearch = make_wildcard_search_str(format.working_name);
	OutputNameReplace = make_wildcard_replacement( format.output_name);
	DescriptionReplace = make_wildcard_replacement( format.description);
	
	sel_idx = regexpcmp( in_data.Properties.VariableNames, WorkingNameSearch );
	
	if ~any(sel_idx)
		continue;
	end
	
	if format.is_catch_all
		sel_idx = sel_idx & isnan(sort_idx);
	end
	
	sel_data = in_data(:,sel_idx);
	
	sort_idx(sel_idx) = f;
	
	working_names = sel_data.Properties.VariableNames;
	output_names = regexprep( working_names, WorkingNameSearch, OutputNameReplace);
	sel_data.Properties.VariableDescriptions = output_names;
	
	if ~isempty( format.output_units)	
		sel_data.Properties.VariableUnits(:) = {format.output_units};
	end

	sel_props = struct('output_name', output_names);

	% Descriptions & Units
	descriptions = regexprep(regexprep( working_names, WorkingNameSearch, DescriptionReplace),'\$\d+','*');
	[sel_props.description] = descriptions{:};
	[sel_props.calibration_status] = deal(format.calibration_status);
	[sel_props.units] = sel_data.Properties.VariableUnits{:};
	
	% Spreadsheet Options
	[sel_props.core_data] = deal(format.core_data);
	[sel_props.full_data] = deal(format.full_data);
	[sel_props.precision] = deal(format.display_precision);
		
	% Contour Plot Options
	[sel_props.contour_levels] = deal(format.contour_levels);
	[sel_props.core_contour] = deal(format.core_contour);
	[sel_props.full_contour] = deal(format.full_contour);
		
	out_data = [out_data, sel_data];
	out_props = [out_props, sel_props];
		
end	

unmatch_data = in_data(:,isnan(sort_idx));


unmatch_props = struct('output_name', unmatch_data.Properties.VariableNames);

% Descriptions & Units
[unmatch_props.description] = deal('');
[unmatch_props.calibration_status] = deal('');
[unmatch_props.units] = unmatch_data.Properties.VariableUnits{:};

% Spreadsheet Options
[unmatch_props.core_data] = deal(false);
[unmatch_props.full_data] = deal(false);
[unmatch_props.precision] = deal(nan);

% Contour Plot Options
[unmatch_props.contour_levels] = deal('');
[unmatch_props.core_contour] = deal(false);
[unmatch_props.full_contour] = deal(false);


out_data = [out_data, unmatch_data];
out_props = [out_props, unmatch_props];


out_data.Properties.UserData = out_props;

end


