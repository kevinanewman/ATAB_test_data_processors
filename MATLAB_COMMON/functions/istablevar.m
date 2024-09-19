function tf = istablevar( tbl, varstr)

tf = ismember(varstr,tbl.Properties.VariableNames);

end