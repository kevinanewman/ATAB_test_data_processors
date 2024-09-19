function out_data = calc_continuous_stats( data, data_format )

% Remove non-numeric data
numeric_data = data(:,vartype('numeric')) ;

% Bail if no data to process
if isempty(numeric_data)
	stat_data = [];
	return;
end

% Average each variable and store with the same name
out_data = varfun(@mean, numeric_data );
out_data.Properties.VariableNames = numeric_data.Properties.VariableNames; 

% Calculate other Statistics
stat_code = {	'COV',	'STD',	'MIN', 'MAX',	'AVG',	'MEDIAN'};
stat_func = {@coefvar,	@std,	@min,	@max,	@mean,	@median};
stat_funcs = containers.Map( stat_code, stat_func);

stat_format = data_format( [data_format.is_cont_calc]);
stat_single_format = stat_format( ~[stat_format.is_wildcard] );
stat_wc_format = stat_format( [stat_format.is_wildcard] );

% Handle Non wildcard stat calcs in bulk
if ~isempty(stat_single_format)
	for s = 1:length(stat_code)
		
		stat_format_sel = strcmpi({stat_single_format.stat_calc},stat_code{s});
% 		stat_format = stat_single_format(stat_format_sel);
				
		stat_data = varfun(stat_func{s}, numeric_data(:,{stat_single_format(stat_format_sel).stat_working_name}));
		stat_data.Properties.VariableNames = {stat_single_format(stat_format_sel).working_name};
		
		out_data = [out_data,stat_data];
	end
end

% Loop through formats requiring wildcard processing
for f = 1:numel(stat_wc_format)
	
	format = table2struct( stat_wc_format(f,:));
	
	stat_in_name_search = make_wildcard_search_str( format.stat_working_name);
	stat_out_name_replace = make_wildcard_replacement( format.working_name);
	stat = stat_funcs( upper(format.StatCalc) );
	
	sel_idx = regexpcmp( numeric_data.Properties.VariableNames, stat_in_name_search );
	sel_vars = numeric_data.Properties.VariableNames(sel_idx);
	
	stat_data = varfun(stat, numeric_data(:,sel_idx));
	stat_data.Properties.VariableNames = regexprep( sel_vars, stat_in_name_search, stat_out_name_replace);
	
	out_data = [out_data,stat_data];
	
end
	


end