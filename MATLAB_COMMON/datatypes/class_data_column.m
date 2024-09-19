classdef class_data_column
    % CLASS_DATA_COLUMN
    
    properties
        header_cell_str = {''};     % cell array of header data, one row in output file per entry
        format_str  = '%s';         % printf format string
        eval_str    = 'char(32)';   % string to be evaluated and printed in output file
        verbose     = 0;            % verbosity level, 0 = always output, higher numbers control output level as in REVS.verbose
    end
    
    methods
        
        function obj = class_data_column( header_cell_str, format_str, eval_str, verbose)
            obj.header_cell_str = header_cell_str;
            obj.format_str = format_str;
            obj.eval_str = eval_str;
            
            if (nargin == 4)
                obj.verbose = verbose;
            end
            
            if isempty(format_str)
                error('format_str cannot be empty!');
            end
            
            if isempty(eval_str)
                error('eval_str cannot be empty!');
            end
            
        end
    end
    
end

