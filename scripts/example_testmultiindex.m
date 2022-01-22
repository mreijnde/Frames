% script with some basic examples/tests for MultiIndex
clear all
clc

warning('off','frames:Index:notUnique');
warning('off', 'frames:MultiIndex:notUnique');
warning('off', 'frames:Index:subsagnNotUnique');

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

% manipulations
df3 = df2.sum("x")                     % aggregate over (sub)dimension
df4 = df3 - df3({':',1},["m2","m4"])   % select, math with expansion
df5 = df4 ./ df4.max("z")              % aggregate, math with expansion
df6 = df5.std("columns")               % column wise aggregation

