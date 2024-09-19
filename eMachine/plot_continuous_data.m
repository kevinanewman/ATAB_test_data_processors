function [ax_hand, line_hand] = plot_continuous_data( data, data_stable, data_format )

	% Select the applicable data formats
	select_format = data_format(~cellfun(@isempty, {data_format.continuous_plot } ));
		
	plot_axis = strtrim(upper( {select_format.continuous_plot }));
	p = cellfun( @str2num, regexprep({select_format.continuous_plot },'\D',''));
% 	plot_axis_right = ~cellfun( @isempty, regexp({select_format.continuous_plot },'R'));
	num_axes = max(p);
	
	line_hand = gobjects(0);
	line_ax = [];
	
	plot_axis_unique = unique( plot_axis);
	
	% Make the axes
	for p = 1:num_axes	
		position = [.120, 0.9 - (p   - 0.1)*0.85/num_axes, 0.800, 0.9*0.85/num_axes];
		ax_hand(p) = axes('Position',position,'Layer','top', 'YColor','k','XGrid','On','YGrid','on');
		ax_left_units{p} = {};
		ax_left_ymin{p} = nan;
		ax_left_ymax{p} = nan;
		ax_right_units{p} = {};
		ax_right_ymin{p} = nan;
		ax_right_ymax{p} = nan;
		hold on;
	end
	

		for f = 1:length( select_format )
		
			format = select_format(f);

			p = str2double( regexprep(format.continuous_plot,'\D',''));
			axes( ax_hand(p))
			
			if contains( format.continuous_plot, 'R')
				yyaxis(ax_hand(p),'right');
				set(ax_hand(p), 'YColor','k');			
			elseif ~strcmpi( get( ax_hand(p), 'YAxisLocation'), 'left' )
				yyaxis(ax_hand(p),'left');			
			end
			
			WorkingNameSearch = make_wildcard_search_str(format.working_name);
			OutputNameReplace = make_wildcard_replacement(format.output_name);

			sel_idx = regexpcmp( data.Properties.VariableNames, WorkingNameSearch );

			if ~any(sel_idx)
				continue;
			end


			sel_variables = data.Properties.VariableNames(sel_idx);
			sel_legend_name = regexprep( sel_variables, WorkingNameSearch , OutputNameReplace);
			sel_legend_units = regexprep( regexprep( format.output_units ,'^-+$',''), '^(.+)$','($1)');
			sel_legend_str = pad(strcat(sel_legend_name, ' ', sel_legend_units), 30);
			sel_plot_color = format.continuous_color;
			
			sel_axis_units = format.output_units;
			sel_axis_units = regexprep( sel_axis_units ,'^-+$','');				% Replace "-" with blank 
			sel_axis_units = regexprep( sel_axis_units, '^CAD.*$','CAD');		% Remove Modifiers from CAD (BTDC, ATDC, RET, ADV)
			
			if contains( format.continuous_plot, 'R')
				ax_right_units{p}{end+1} =  sel_axis_units;
				ax_right_ymin{p} = min(ax_right_ymin{p}, format.plot_axis_min);
				ax_right_ymax{p} = max(ax_right_ymax{p}, format.plot_axis_max);
			else
				ax_left_units{p}{end+1} =  sel_axis_units;
				ax_left_ymin{p} = min(ax_left_ymin{p}, format.plot_axis_min);
				ax_left_ymax{p} = max(ax_left_ymax{p}, format.plot_axis_max);
			end
			
			

			for v = 1:numel(sel_variables)

				sig_working_name = sel_variables{v};
				sig_value = data.(sig_working_name);

				if istablevar(data_stable, sig_working_name)
					sig_stable =  data_stable.(sig_working_name);
					superplot(data.relative_time_sec, sig_value, 'gy2');
					sig_value(~sig_stable) = nan;
					line_hand(end+1) = superplot(data.relative_time_sec, sig_value, sel_plot_color,'LineWidth',2,'DisplayName',sel_legend_str{v});
					line_ax(end+1) = p;
				else
					line_hand(end+1) = superplot(data.relative_time_sec, sig_value, sel_plot_color,'LineWidth',2,'DisplayName', sel_legend_str{v});
					line_ax(end+1) = p;
				end

			end
		
	end
				
	% Format Axes & Legend
	for p = 1:num_axes			
		
		axes( ax_hand(p))
		
		% Add legend
		legend_hand(p) = legend(ax_hand(p), line_hand(line_ax == p));
		legend_hand(p).Interpreter = 'none';
		legend_hand(p).Location = 'SouthOutside';
		legend_hand(p).Box = 'off';
		legend_hand(p).Orientation = 'horizontal';		
		
		xlim([data.relative_time_sec(1),data.relative_time_sec(end)]);
		
		if ~isnan( ax_right_ymin{p} )
			ax_hand(p).YAxis(2).Limits(1) = ax_right_ymin{p};
		end
			
		if ~isnan( ax_right_ymax{p} )
			ax_hand(p).YAxis(2).Limits(2) = ax_right_ymax{p};
		end
		
		if ~isempty( ax_right_units{p} )
			ax_hand(p).YAxis(2).Label.String = strjoin( unique(ax_right_units{p}), ' / ');
		end
			
		if ~isnan( ax_left_ymin{p} )
			ax_hand(p).YAxis(1).Limits(1) = ax_left_ymin{p};
		end
			
		if ~isnan( ax_left_ymax{p} )
			ax_hand(p).YAxis(1).Limits(2) = ax_left_ymax{p};
		end		
				
		if ~isempty( ax_left_units{p} )
			ax_hand(p).YAxis(1).Label.String = strjoin( unique(ax_left_units{p}), ' / ');
		end
	
		
	end
	
	
	% Link & Set X lims
	drawnow;
	
	
end

