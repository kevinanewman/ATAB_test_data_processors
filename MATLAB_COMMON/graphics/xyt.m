function xyt(plot_x_label, plot_y_label, varargin)

    if ~isempty(plot_x_label) || ~isempty(plot_y_label)
        xlabel_h = xlabel(plot_x_label);
        ylabel_h = ylabel(plot_y_label);
        if (size(varargin,2) > 0) 
            plot_title = varargin{1};
            varargin = varargin(2:end);
        else
            plot_title = [plot_y_label ' v. ' plot_x_label];
        end

        no_date = parse_varargs(varargin, 'no_date', true, 'toggle');

        varargin = varargin(find(~strcmp(varargin,'no_date')));

        if no_date
            title_h = title(plot_title, varargin{:});
        else
            title_h = title([plot_title ' plotted on ' date],varargin{:});
        end

        set(xlabel_h,'Interpreter','none');
        set(ylabel_h,'Interpreter','none');
        set(title_h,'Interpreter','none');
    else
        xlabel('');
        ylabel('');
        title('');        
    end
    
end