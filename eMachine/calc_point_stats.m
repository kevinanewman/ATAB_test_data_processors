function out_data = calc_point_stats( data, data_format)

stat_format = find( [data_format.is_point_calc]);

% Remove non-numeric data
numeric_data = data(:,vartype('numeric')) ;

%Make same height table for output
out_data = data;

% 
stat_code = {	'COV',	'STD',	'MIN', 'MAX',	'AVG',	'SUM', 'MEDIAN'};
stat_func = {@coefvar,	@std,	@min,	@max,	@mean,	@sum,	@median};
stat_funcs = containers.Map( stat_code, stat_func);

% Loop through formats requiring wildcard processing
for f = stat_format
	
	format = data_format(f);
	
	stat_in_name_search = make_wildcard_search_str( format.stat_working_name);
	stat = stat_funcs( format.stat_calc );
	
	sel_idx = regexpcmp( numeric_data.Properties.VariableNames, stat_in_name_search );
	
	if any( sel_idx )

		stat_data = rowfun(stat, numeric_data(:,sel_idx),'SeparateInputs',false,'OutputVariableNames',format.working_name);
		% 	out_data = [out_data, stat_data];
		
		out_data.(format.working_name) = stat_data{:,:};

	end

end



end