function create_legend_page(emachine, data_types, image_path, out_file, include_x, title_append, show_figs )
%creates a .pdf page within the current directory
%if there is a legend_image.*** image file, it will be inserted

sugg_citation = emachine.citation;

figure('Visible',show_figs,'Renderer','Painters');

t_margin = 0.1;
t_width = 1-2*t_margin;

% fprintf('Looking for legend image at %s\n', image_path);
legend_img = dir( [image_path,'legend_image.*'] );


%% Figure
if ~isempty( legend_img)
	%Insert image
	img_ax = axes('Position',[t_margin, 0.05 t_width 0.43]); %create an axes in order to set location of image
	
	img_file = [image_path,legend_img(1).name];
	img = imread(img_file);
	img_h = imshow(img);
	

	
	offset = 0.0;
else
	offset = -0.1;
end



%% Title
t = annotation('textbox');
t.String = sprintf('%s %s - %s Data Plots', emachine.name, title_append);
% t.String = 'Legend & Notes';
t.Position = [t_margin, 0.90, t_width, 0.05];
t.FontSize = 20;
t.LineStyle = 'none';


t = annotation('line');
t.X = [t_margin/2,1-t_margin/2];
t.Y = [0.90,0.90];
t.Color = [0.25,0.44,0.75];
t.LineWidth = 1;

%% Citation

t = annotation('textbox');
t.String = sugg_citation;
t.Position = [t_margin, 0.83, t_width, 0.07];
t.LineStyle = 'none';


%% Legend
ax2 = axes('Position',[1.5 0.7  0 0],'Visible','off');
hold on

% Published / Manufacturer Max Torque Curve or Max Torque and Power points 
if ~isempty(emachine.published_wot_speed_rpm)		
	plot_hand = superplot(1,1,'k--2','DisplayName','Dashed line indicates the maximum torque curve from published data');
else	
	plot_hand = superplot(1,1,'kkd7','DisplayName','Black diamonds indicate rated torque & power points advertised by the manufacturer');
end


if ismember( 'SS AVG', data_types) || ismember( 'SS CONT', data_types)
	plot_hand(end+1) = superplot( 1,1,'k.5','DisplayName','Black dots indicate speed/load points at which steady state data was acquired');
end

if ismember( 'SS AVG TXMN', data_types) || ismember( 'SS CONT TXMN', data_types)
	plot_hand(end+1) = superplot( 1,1,'or.5','DisplayName','Orange dots indicate speed/load points at which steady state data was acquired coupled to a transmission');
end

if ismember( 'HL-initial', data_types)
	plot_hand(end+1) = superplot( 1,1,'lb^','DisplayName','Blue triangles indicate speed/load points at which initial data from the transient high load method was acquired');
end

if ismember( 'HL-final', data_types)
	plot_hand(end+1) = superplot( 1,1,'lglg^','DisplayName','Green triangles indicate speed/load points at which final data from the transient high load method was acquired');
end

if ismember( 'MAX', data_types) || ismember( 'MIN', data_types)
	plot_hand(end+1) = superplot( 1,1,'lb--2','DisplayName','Light Blue dashed line indicates speed/load points selected to represent maximum or minimum engine torque');
end

if ismember( 'MAX-raw', data_types) || ismember( 'MIN-raw', data_types)
	plot_hand(end+1) = superplot( 1,1,'y.3','DisplayName','Yellow dots indicate speed/load points of raw maximum or minimum torque sweep data');
end

if include_x
	plot_hand(end+1) = superplot( 1,1,'rx8','DisplayName','Red Xs indicate speed/load points where data was not collected or did not meet quality standards');
end

% Create Legend and Place Over Plot
leg = legend(plot_hand);
leg.FontSize = 11;
leg.Position = [t_margin, .64 + offset, t_width, 0.19];
leg.EdgeColor = 'none';

%% WOT citation
if ~isempty( emachine.source_citation )
	t = annotation('textbox');
	t.String = sprintf('Published maximum torque data from:\n%s',emachine.source_citation);
	t.Position = [t_margin, 0.48 + 2*offset, t_width, 0.07];
	t.LineStyle = 'none';
	t.Interpreter = 'none';
end


%% Notes

t = annotation('textbox');
t.String = {'Note: In these contour plots, individual data points may be ignored or removed, using our best engineering judgment, to correct irregularities in the visual presentation of the contour lines; additional details are contained in the test report.'};
t.Position = [t_margin, 0.55 + offset, t_width, 0.09];
t.LineStyle = 'none';

%% Add Date
add_plot_date;

%% Print to pdf
drawnow();
print_pdf_usletter_landscape(out_file);
close(gcf);

end
