function write_data_tab( xls, sheet, data, emachine, select)

num_cols = size(data,2);
num_rows = size(data,1);

% Convert boolean columns to Y/N
boolvars = find(regexpcmp(data.Properties.VariableUnits,'Y\s*/\s*N'));

for b = boolvars
    temp = cell(size(data(:,b)));
    temp(data{:,b} == 1) = {'Y'};
    temp(data{:,b} == 0) = {'N'};
    data.(b) = temp;
end

xls.add_sheet(sheet);

% Header Block
xls.format(xlsrange( 'A', 1, num_cols,5),'Color',[0.8,0.8,0.8],'HorizAlign','Center','VertAlign','Center','WrapText',true,'ColWidth',12);

% Write data
xls.write_table(data,'A4','VariableNames','description','VariableUnits','line');

col_width = max(9, 60/width(data));
xls.format('all','HorizAlign','Center','ColWidth',col_width,'RowHeight',18);

xls.format('A1', 'RowHeight', 22 );
xls.format('A2', 'RowHeight', 0 );
xls.format('A3', 'RowHeight', 36 );
xls.format('A4', 'RowHeight', 44 );
xls.format( 'A6', 'FreezePane' );

% precision_digits = floor(data.Properties.UserData.Precision);

AddProps = data.Properties.UserData;

for c = 1:width(data)
    col_range = xlscol(c);
    col_range = strcat( col_range,':',col_range);
    
    % Set display Precision
    if isinf(AddProps(c).precision) || isnan(AddProps(c).precision)
        %Nothin to do...
    elseif AddProps(c).precision < 1
        xls.format(col_range,'NumberFormat','0');
    else
        xls.format(col_range,'NumberFormat',['0.',repmat('0',1,AddProps(c).precision)]);
    end
end

% BOrders
xls.format( xlsrange('A',4,num_cols,num_rows+2), 'LineStyle','Continuous');
xls.format( xlsrange('A',1,num_cols-1,3), 'LineStyle','Continuous');
xls.format( xlsrange(num_cols,1,1,3), 'OuterLineStyle','Continuous');

% Version
xls.write({'Version:'}, xlsrange(num_cols, 1))
xls.write({char(datetime(date,'Format','MM-dd-yy'))},xlsrange(num_cols, 3))
xls.format(xlsrange(num_cols, 3), 'NumberFormat', 'MM-dd-yy');

% Title Block
xls.write({[emachine.name, ' - ', select, ' Data']},'A1')
xls.format(xlsrange( 'A', 1, num_cols-1), 'MergeCells',true,'FontSize',16,'FontBold',true);

% Citation Block
xls.write({emachine.citation},'A3')
xls.format( 'A3', 'RowHeight', 45 );
xls.format( xlsrange('A', 3, num_cols-1), 'MergeCells',true,'WrapText',true);




end
