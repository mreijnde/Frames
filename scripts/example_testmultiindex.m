% script with some basic examples/tests for MultiIndex
clear all
clc

warning('off', 'frames:MultiIndex:notUnique');

frames.DataFrame.setDefaultSetting("alignMethod", "full");


%% EXAMPLE 1: aggregation and math operations on multiIndex DataFrame

% dataset with group variables and measure data
N =  25;
vars  = gallery('integerdata', 3   ,[N,3],0);       
dat   = gallery('integerdata', 100 ,[N,4],0);

% create MultiIndex DataFrame
df0 = frames.DataFrame([vars dat],{},{["x","y","z","m1","m2","m3","m4"]}).setRowsType("duplicate")

% set group variables on MultiIndex
df1 = df0.setRows(["x","y","z"])

% aggregate duplicate measurement points
df2 = df1.groupDuplicate(@mean)

% get sub-selection
df2sub = df2({1,':',3}, ["m1","m2"])

% manipulations
df3 = df2.sum("x")                     % aggregate over (sub)dimension
df4 = df3 - df3({':',1},["m2","m4"])   % select, math with expansion
df5 = df4 ./ df4.max("z")              % aggregate, math with expansion
df6 = df5.std("columns")               % column wise aggregation

% get ND matrix
[dat, dimnames] = df2.dataND()




%% EXAMPLE 2: enable MultiIndex syntax
frames.DataFrame.setDefaultSetting("forceMultiIndex", false);

% with forceMultiIndex enabled DataFrame constructor requires correct orientation of rows/colums input
% as rows(Nrow_items, Ndim) and columns(Ndim,Ncolumn_items)

df1  = frames.DataFrame(magic(3), [1 2 3]', ["a","b","c"]) 

df2a = frames.DataFrame(magic(3), [1 1; 2 1; 3 2],   ["a","b","c" ; "A","A","B" ])     % 2d array
df2b = frames.DataFrame(magic(3), {[1;2;3],[1;1;2]}, {["a";"b";"c"],["A";"A";"B"] })   % cell with array per dim
df2c = frames.DataFrame(magic(3), {1 1; 2 1; 3 2}, {"a","b","c" ; "A","A","B" })       % 2d cell            
df2d = frames.DataFrame(magic(3), {{1,1},{2,1},{3,2}}, {{"a","A"},{"b","A"},{"c","B"}})% nested cell    

%%

ind1 = frames.MultiIndex(["a";"b";"c"])                    % 1d array (limited to single dim)
ind1 = frames.MultiIndex(["a","A";"b","A";"c","B"])        % 2d array
ind2 = frames.MultiIndex({["a";"b";"c"],["A";"A";"B"] })   % cell with array per dim
ind3 = frames.MultiIndex( {"a","b","c" ; "A","A","B"})     % 2d cell            
ind4 = frames.MultiIndex({{"a","A"},{"b","A"},{"c","B"}})  % nested cell   


%% restore defaults
frames.DataFrame.restoreDefaultSettings();
warning('on', 'frames:MultiIndex:notUnique');



