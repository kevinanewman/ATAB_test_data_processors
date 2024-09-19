function add_plot_date( fig )
%ADD_PLOT_DATE Summary of this function goes here
%   Detailed explanation goes here

if nargin < 1 
	fig = gcf;
end

ver_string = sprintf( 'Version: %s', char(datetime(date,'Format','MM-dd-yy')));
annotation(fig, 'textbox', [0.77, 0.87, 0.20, 0.10], 'String',ver_string,'backgroundcolor','none','FitBoxToText','on','LineStyle','none', 'HorizontalAlignment','Right');

%  
end

