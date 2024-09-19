function print_pdf_usletter_landscape( varargin) 

fig = gcf;
set(fig, 'PaperType', 'usletter');
set(fig, 'PaperOrientation','landscape');
%set(fig, 'PaperPosition',[0.25 0.25 10.5 8.0]);
set(fig, 'PaperPosition',[0 0 11 8.5]);
set(fig, 'PaperPosition',[0 0 11 8.5]);

if ~isempty(varargin)
    fname = varargin{1};
else
    ax = gca;
    fname = ax.Title.String;
end

print('-dpdf',fname)