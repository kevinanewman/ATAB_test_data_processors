function [ out_data ] = concatenate_data( data1, data2 )

data2_only = setdiff(data2.Properties.VariableNames, data1.Properties.VariableNames);
data1_only = setdiff(data1.Properties.VariableNames, data2.Properties.VariableNames);

data1_add = data2([], data2_only);
data1_add = fill_missing_vars(data1_add, height(data1) );

data2_add = data1([], data1_only);
data2_add = fill_missing_vars(data2_add, height(data2) );

out_data = [[data1, data1_add];[data2, data2_add]];

end


function t_out = fill_missing_vars( t_in, len)

c_out = cell( 1, width(t_in));
c_out(:) = {nan(len, 1)};

make_cellstr = varfun( @iscellstr, t_in, 'Output','Uniform');
c_out(:,make_cellstr) = {repelem({''},len,1)};

make_nat  = varfun( @isdatetime, t_in, 'Output','Uniform');
c_out(:,make_nat) = {NaT(len, 1)};

t_out = table( c_out{:}, 'VariableNames', t_in.Properties.VariableNames);

end