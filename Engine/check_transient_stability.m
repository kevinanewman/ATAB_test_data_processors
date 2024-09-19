function stable_flag = check_transient_stability( data, data_format)

stable_flag = data(:,{'timestamp','elapsed_time_sec'});
check_format = find( ~isnan([data_format.stable_threshold]));


for f = check_format
	
	WorkingNameSearch = make_wildcard_search_str( data_format(f).working_name);
	vars = regexpcmp( data.Properties.VariableNames, WorkingNameSearch );
	stable_fun = @(x) (stable_check(x, data{:,'elapsed_time_sec'}, data_format(f).stable_threshold));
	var_stable = varfun( stable_fun, data(:,vars) );
	
	% REvert to original variable names - don't use prepended
	var_stable.Properties.VariableNames = data(:,vars).Properties.VariableNames;
	
	stable_flag = [stable_flag, var_stable];
	
end

end