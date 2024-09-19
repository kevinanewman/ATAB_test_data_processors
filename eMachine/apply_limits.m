function [data, data_edits] = apply_limits(data, data_format)

data_edits = table({''},{''},{''},{''},{''},{''},'VariableNames',{'File','TestNumber','ModeNumber','Signal','Action','Comment'});
data_edits = data_edits([],:);

has_limit = ~isnan( [data_format.min_limit]) | ~isnan([data_format.max_limit]);

stat_formats = data_format( data_format.is_cont_calc,: );
stat_lim_formats = data_format(has_limit & [data_format.is_cont_calc]);
sig_lim_formats = data_format(has_limit & ~[data_format.is_cont_calc]);


for f = 1:numel(stat_lim_formats)
	format = stat_lim_formats(f,:);	
	stat_name_search = make_wildcard_search_str( format.working_name );
	match_vars = find(regexpcmp(data.Properties.VariableNames, stat_name_search));	
	for v = match_vars
	
		out_of_range = data.(v) < format.min_limit | data.(v) > format.max_limit;
		
		if any(out_of_range)
			var = data.Properties.VariableNames{v};
			base_var = regexprep( var, stat_name_search, make_wildcard_replacement(format.stat_working_name) );
			data.(base_var)(out_of_range) = nan;
			
			
			
			edit_tests = unique(data(out_of_range,{'source_file','test_number','test_mode'}));
			comment_str = sprintf( 'Out of range data for %s, removing %d datapoints for %s and any statistics', var, sum(out_of_range), base_var);
			
			
			warning('Out of range data for %s, removing %s', var, base_var);
			
		end

	end
	
	
end

% Limits on regular inputs
for f = 1:numel(sig_lim_formats)
	format = sig_lim_formats(f,:);
	working_name_search = make_wildcard_search_str( format.working_name );
	match_vars = find(regexpcmp(data.Properties.VariableNames, working_name_search));
	for v = match_vars	
		out_of_range = data.(v) < format.min_limit | data.(v) > format.max_limit;
		
		if any(out_of_range)
			var = data.Properties.VariableNames{v};
			
			% TODO: Add warning!
			data.(v)(out_of_range) = nan;
			
			edit_tests = unique(data(out_of_range,{'source_file','test_number','test_mode'}));
% 			comment_str = sprintf( 'Out of range data for %s, removing %s', var, base_var);
% 			comment_str = sprintf( 'Out of range data for %s, removing % datapoints for %s and any statistics', var, base_var);
			
			
%  			add_data_edits = { edit_tests.source_file, num2str(edit_tests.test_number), num2str(edit_tests.test_mode),
			
			
			
			warning( 'Out of range data for %s, removing %d datapoints and any statistics', var, sum(out_of_range));
			
		end

	end
	
	
end


% If base value was nan - remove statistical values
for f = 1:numel(stat_formats)
	format = stat_formats(f,:);
	base_name_search = make_wildcard_search_str( format.stat_working_name );
	match_vars = find(regexpcmp(data.Properties.VariableNames,base_name_search));
	for v = match_vars	
		nan_idx = isnan(data.(v));
		if any( nan_idx)
			base_var = data.Properties.VariableNames{v};
			stat_var = regexprep( base_var, base_name_search, make_wildcard_replacement(format.working_name) );
			data.(stat_var)(nan_idx) = nan;
		end
	end
end



end