function  [out_pdf, out_emf] = create_contour_plots(xdata, ydata, point_type, indata, plot_bound, out_path, e, max_torque_data, min_torque_data , data_select, show_figs)
%%


% Make array for output file names
out_pdf = cell(width(indata),1);
out_emf = cell(width(indata),1);
out_file = cell(width(indata),1);


% Get normalization factors 
xnorm = plot_bound.max_speed_rpm;
ynorm = plot_bound.max_torque_Nm - plot_bound.min_torque_Nm;


%% Remove rows with bad x or y
rmv = isnan(xdata) | isnan(ydata);
xdata = xdata(~rmv);
ydata = ydata(~rmv);
point_type = point_type(~rmv);
indata = indata(~rmv,:);

%% Find Boundaries of Data and Plot
bound_pts = data_bound(2*xdata/xnorm,ydata/ynorm,0.5);
data_bound_speed_rpm = xdata(bound_pts);
data_bound_torque_Nm = ydata(bound_pts);

%% Start with data point plot
ax = plot_data_points(point_type,  xdata, ydata, e, plot_bound, show_figs );

if ~isempty( max_torque_data )
	superplot( max_torque_data.speed_rpm, max_torque_data.torque_Nm,8, 'lb--2' );
end

if ~isempty( min_torque_data )
	superplot( min_torque_data.speed_rpm, min_torque_data.torque_Nm,8, 'lb--2' );
end

add_plot_date


%% set up grid for interpolation
% Evenly spaced grid with spacing determined in data area

xgrid = linspace(plot_bound.min_speed_rpm, plot_bound.max_speed_rpm, 60);
ygrid = linspace(plot_bound.min_torque_Nm, plot_bound.max_torque_Nm, 40);
xstep =xgrid(2) - xgrid(1);
ystep =ygrid(2) - ygrid(1);

% Remove excess ( outside of data) to speed computation (wont be displayed anyway)
xgrid( xgrid > (max(xdata) + xstep*1.2)) = [];
xgrid( xgrid < (min(xdata) - xstep*1.2)) = [];

ygrid( ygrid > (max(ydata) + ystep*1.2)) = [];
ygrid( ygrid < (min(ydata) - ystep*1.2)) = [];

[xmesh, ymesh] = meshgrid( xgrid,ygrid );

in_data_bound = inpolygon(xmesh, ymesh, data_bound_speed_rpm, data_bound_torque_Nm);

expand_bound = in_data_bound;
expand_bound(1:end,2:end) = expand_bound(1:end,2:end) | expand_bound(1:end,1:end-1);
expand_bound(1:end,1:end-1) = expand_bound(1:end,1:end-1) | expand_bound(1:end,2:end);
expand_bound(2:end,1:end) = expand_bound(2:end,1:end) | expand_bound(1:end-1,1:end);
expand_bound(1:end-1,1:end) = expand_bound(1:end-1,1:end) | expand_bound(2:end,1:end);


%% Find repeats and average them - Needs validation

test_pts = [xdata, ydata];
[sort_pts, orig_idx] = sortrows(test_pts);
repeat = [all(sort_pts(1:end-1,:) == sort_pts(2:end,:),2);false];

if any(repeat)
	warning('Redeated data points detected - replacing with average for contour plotting');
	repeat_pts = unique(test_pts(orig_idx(repeat),:),'rows');
	remove_pts = false(size(xdata));
	for p = 1:size(repeat_pts,1)
		matches = all(test_pts == repeat_pts(p,:), 2);
		remove_pts = remove_pts | matches;
		xdata(end+1) = repeat_pts(p,1);
		ydata(end+1) = repeat_pts(p,2);		
		indata{end+1,:} = mean( indata{matches,:}); 
	end	
	xdata(remove_pts) = [];
	ydata(remove_pts) = [];
	indata(remove_pts,:) = [];
end


%% Loop through variables
for var_idx = 1:width(indata)
    
    %gather signal properties
	zvar = indata.Properties.VariableNames{var_idx};    
    zname = indata.Properties.VariableDescriptions{var_idx};    
    zunit = indata.Properties.VariableUnits{var_idx};
    zcontour_str = indata.Properties.UserData(var_idx).contour_levels;
	zprecision = indata.Properties.UserData(var_idx).precision;
	zdescription = indata.Properties.UserData(var_idx).description;
	zcalibration_status = indata.Properties.UserData(var_idx).calibration_status;
	
	zdata = indata{:,var_idx};
	
	if ~isnumeric(zdata) || ~isvector(zdata)
        warning('Input data not a numeric vector: "%s"',zname);
        continue;
	elseif all(isnan(zdata) | isinf(zdata))
		warning('Input data contains no valid points: "%s"',zname);
        continue;
	end
	
	if contains( zvar, 'bsfc_gpkWhr')
		invar = strrep( zvar, 'bsfc_gpkWhr','fuel_flow_gps');
		zscat = indata.(invar);	
	elseif contains( zvar, 'bte_pct')
		invar = strrep( zvar, 'bte_pct','fuel_flow_gps');
		zscat = indata.(invar);	
	else
		zscat = zdata;
	end
    
    %%

	% Remove missing data points - remove nans
	rmv = isnan(zscat);
    xscat = xdata(~rmv);
    yscat = ydata(~rmv);
	zscat = zscat(~rmv);
	    
	if isempty(zscat)
		warning('Input data contains no valid points: "%s"', zname);
        continue;
	elseif length( zscat ) < 3	
		warning('Input data contains less than 3 valid points: "%s"', zname);
        continue;
	elseif var(zscat) == 0
		warning('Input data is constant: "%s"', zname);
        continue;	
	end
	
	%% Find bounds of avaialble data
	bound_pts = data_bound(2*xscat/xnorm,yscat/ynorm,0.25);
	data_bound_speed_rpm = xscat(bound_pts);
	data_bound_torque_Nm = yscat(bound_pts);
	
	
	%% interpolate data onto a grid
	surfZ = scatter2surf( xscat, yscat, zscat, xgrid, ygrid, 'xscale', xnorm, 'yscale', ynorm, 'method','scatterinterp');
	
	% set points outside data to nan
  	surfZ(~expand_bound) = nan;
    
	%% Plot Contours
    % Calcuate contour_level - linear or non-linear & plot
	if isempty( zcontour_str) 
		% Use Best Linear or Non Linear
		contour_levels = best_contour(surfZ,10,[min(zdata), max(zdata)], false, 10^(-zprecision));
	elseif contains(zcontour_str,'LINEAR')
		% Use Linear
		contour_levels = best_contour(surfZ,10,[min(zdata), max(zdata)], true, 10^(-zprecision));
	else
		contour_levels = eval( zcontour_str);
	end
	
	% Find if contour levels correspond to a plateau in the data
	is_plateau =  arrayfun( @(l) sum(l == surfZ(:)) ./ sum(~isnan(surfZ(:))), contour_levels ) > 0.05;
	
	contour_above_plateau = contour_levels(is_plateau)*(1+eps);
	contour_below_plateau = contour_levels(is_plateau)*(1-eps);
	contour_non_plateau = contour_levels(~is_plateau);
	
	contour_levels = unique( [contour_non_plateau(:); contour_above_plateau(:);  contour_below_plateau(:)]);
		
	
	% Show the zero contour that is sometimes missing
	if any( contour_levels == 0) && min(surfZ(:)) == 0 
		surfZ = surfZ - realmin;
	elseif any( contour_levels == 0) && max(surfZ(:)) == 0 
		surfZ = surfZ + realmin;
	end
	

 	[cont_matrix, cont_hand] = contour(ax, xmesh, ymesh, surfZ,contour_levels);
      
    %% Apply Contour Labels
     clabel(cont_matrix, cont_hand,'labelspacing',180, 'fontsize',13);% 'Rotation',0,'labelspacing',144);
    
    %% Contour Colormap & axis
	if length(contour_levels) > 1
		caxis([contour_levels(1), contour_levels(end)]);
		
		colormap(zeros(1024,3));	% Add more points to help highly non-linear axes
		cmap = jet;
		if contains(zvar,'bsfc_gpkWhr')  % Reverse colormap for BSFC
			cmap = flipud(cmap);
		end
		contour_levels_norm = unique((contour_levels - min(contour_levels)) ./ ( max(contour_levels) - min(contour_levels)));
		cmap_convert = interp1( contour_levels_norm, linspace(0,1,length(contour_levels_norm)), linspace(0,1,size(cmap,1)));
		cmap = interp1( linspace(0,1,size(cmap,1)),cmap, cmap_convert);
		colormap(cmap);
	end

    %% Fill area outside the scattered data
    
	% Fill Area
	fill_hand = fill3(ax,	[plot_bound.min_speed_rpm;	plot_bound.max_speed_rpm;	plot_bound.max_speed_rpm;	plot_bound.min_speed_rpm;	data_bound_speed_rpm;		plot_bound.min_speed_rpm], ...
							[plot_bound.max_torque_Nm;	plot_bound.max_torque_Nm;	plot_bound.min_torque_Nm;	plot_bound.min_torque_Nm;	data_bound_torque_Nm;		plot_bound.min_torque_Nm], ...
							4* ones(size(data_bound_speed_rpm) +[5,0]), [0.98,0.98,0.98],'LineStyle','none');
						
    % Mark Border
	fill_border_hand = line(ax, data_bound_speed_rpm, data_bound_torque_Nm, 5*ones(size(data_bound_speed_rpm)), 'Color',[0.4,0.4,0.4],'LineStyle','-','linewidth',0.75);
    
    
    
	%    Show Missing Data Points Location
 	points_hand = superplot( xdata(rmv), ydata(rmv), 9,'rx8','LineWidth',1.25);
	
	%% Add Title - short title for EMF
	if isempty(zunit) || all( zunit == '-')
		unit_str = '';
	else
		unit_str = sprintf( ' (%s)', zunit);
	end
	
    title(ax,sprintf('%s\n%s\n%s%s',e.plot_title, data_select, zname, unit_str),'interpreter','none','FontSize',13);
	
	%% Make output file name for figures
	file_base = sprintf('%s%s - %s',out_path, zname, data_select);
	
	if any( strcmpi( file_base, out_file))
		file_base = sprintf('%s%s %d - %s',out_path, zname, var_idx, data_select);
	end
	
	out_file{var_idx} = file_base;
	
	
	%% Save as fig
% 	saveas( [out_file{var_idx},'.fig'] );
	
	%% Save EMF
% 	export_emf([out_file{var_idx},'.emf'],[6,4.5]);
	
	%% Plot updates for PDF
	% Heavier Line Width
	set(cont_hand,'linewidth',2);
	
	if strncmpi( zcalibration_status, 'Reference Only',14) 
		%Switch to title & Description
		title(ax,sprintf('%s\n%s\n%s%s - %s*',e.plot_title, data_select, zname, unit_str, zdescription),'interpreter','none');
		footnote_hand = annotation('textbox',[0.05, 0.03, 0.9, 0.03],'String',['* ', zcalibration_status],'Linestyle','none');
	else
		%Switch to title & Description
		title(ax,sprintf('%s\n%s\n%s%s - %s',e.plot_title, data_select, zname, unit_str, zdescription),'interpreter','none');
		footnote_hand = [];		
	end
	
    %% Print pdf
    print_pdf_usletter_landscape( [out_file{var_idx},'.pdf']);
    
	delete(footnote_hand);
	delete(cont_hand);
	delete(fill_hand);
	delete(fill_border_hand);
	delete(points_hand);

    %% Clean up
    lastwarn(''); % flush lastwarn
    
	waitbar( var_idx / width(indata));
	
end

has_file = ~cellfun(@isempty, out_file);

out_pdf(has_file) = strcat( out_file(has_file),'.pdf');
out_emf(has_file) = strcat( out_file(has_file),'.emf');


close(gcf);

end

function export_emf( file )

fig = gcf;

set(fig,'color','none','Inverthardcopy','off');

style = hgexport('factorystyle');

style.Format = 'meta';
style.Width = 6.5  ;
style.Height = 4.9;
style.ScaledFontSize = 100;

hgexport(fig,file,style)

end

