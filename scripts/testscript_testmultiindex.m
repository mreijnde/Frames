% script with some basic examples/tests for MultiIndex
%
% (work in progress)

clear all
clc
warning('off','frames:Index:notUnique');
%% MultiIndex DataFrame with selection optins


% define some multi-index
mindex = frames.MultiIndex({ [1    1   1   2   2   1   1   1   2   2], ...
                             [1    2   3   1   3   5   6   7   5   6], ...
                             ["a" "a" "b" "b" "a" "a" "a" "b" "b" "a"]},  ...
                           name=["x","y","z"])

% create DataFrame with random data
data = rand(length(mindex),2);
df = frames.DataFrame( data , mindex, ["col1","col2"])

% selections
df1 = df(:,"col1")
df2 = df([true false true false], "col2")
df3 = df({':',[2 3 5],"a"})
df4 = df({':',[2 3 5]}    ,:)
df5 = df([true false true false], "col1")

df6 = df({ {1,3,"b"}, {2,5,"b"}, {2,6,"a"} })

df7 = df({ {':',3,"b"}, {':',[2 5 7],':'} })

df8 = df{[3 4],1}

mask = df.col("col1")<0.3;
df9 = df( mask )
df10 = df( mask.data)


mask_error = mask;
mask_error.index_.value_(2).value(3) = 22;
try 
df( mask_error )
catch
    disp("OK, mask_error catched");
end

% assign
dfA = df;
dfA({ {1,3,"b"}, {2,5,"b"}, {2,6,"a"} },"col2") = 55
dfA([true false true false], "col1") = [77 88]
dfA(mask) = 99

mask2D = df<0.4;
dfA(mask2D) = 11
dfA(mask2D.data) = 12


                         
%% Concatenate multi index                         
mindex2 = frames.MultiIndex({[3 3 3 4 4], [5 6 7 5 6], ["a" "a" "b" "b" "a"]},name=["x","y","z"])
mindex_new = [mindex; mindex2]


%% Test align and expand multiIndex

mA_base = frames.MultiIndex({ [1 2 2 2 3 3 4 4 4 4 5 5 6 ], ...
                              [1 1 2 3 1 2 1 2 3 4 1 2 1 ]}, name=["x","y"]);                         

mA_less = frames.MultiIndex({ [2 2 2 3 3 4 4 5 5 6 ], ...
                              [1 2 3 1 2 2 3 1 2 1 ]}, name=["x","y"]);                          

mA_more = frames.MultiIndex({ [1 2 2 7 2 3 2 3 4 4 9 9 4 4 5 5 6 ], ...
                              [1 1 2 4 3 1 5 2 1 2 1 2 3 4 1 2 1 ]}, name=["x","y"]);                         

mA_moreless = frames.MultiIndex({ [1 2 2 7 2 3 2 3 9 9 5 5 6 ], ...
                                  [1 1 2 4 3 1 5 2 1 2 1 2 1 ]}, name=["x","y"]);            
                                                                             
mB_base = frames.MultiIndex({ [5   6    6   1   2   1   4   3    4   4 ], ...
                             ["i" "k" "j" "f" "c" "a" "f" "e"  "g" "h"]}, name=["x","k"]);                                                                   

mB_moreless = frames.MultiIndex({ [5    6    9   6   9   1   2   9   9   1   4   3   10  10   4   4 ], ...
                              ["i"  "k" "a" "j" "b" "f" "c" "c" "d" "a" "f" "e"  "a" "b" "g" "h"]}, name=["x","k"]);
                                        
mC_base = frames.MultiIndex({ [4 7 3 7 1 8 2 8 8 2 2 3 4 5 4 4 5 6 ], ...
                              [3 2 1 1 1 1 1 2 3 2 3 2 1 2 2 4 1 1 ],...
                              [1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 4 5 6]...                                            
                             }, name=["x","y","k"]);                                                    

mC_less = frames.MultiIndex({ [4 7 7 1 8 2 8 8 2 2 4 5 4 5 6 ], ...
                              [3 2 1 1 1 1 2 3 2 3 1 2 4 1 1 ],...
                              [1 2 1 2 3 1 2 3 1 2 1 2 4 5 6]...                                            
                             }, name=["x","y","k"]);
                                                                 
% example (1 common dimension, no extra dim)                         
[mindexnew, row_ind1, row_ind2] = mA_base.alignIndex(mA_more, "full")
[mindexnew, row_ind1, row_ind2] = mA_moreless.alignIndex(mA_base, "full")

% example (1 common dimension, extra dim)                         
[mindexnew, row_ind1, row_ind2] = mA_base.alignIndex(mB_base)
[mindexnew, row_ind1, row_ind2] = mA_base.alignIndex(mB_moreless)
[mindexnew, row_ind1, row_ind2] = mA_base.alignIndex(mB_moreless, 'keep')

% example (2 common dimensions, extra dim obj1)
[mindexnew, row_ind1, row_ind2] = mC_base.alignIndex(mA_base, "full")
[mindexnew, row_ind1, row_ind2] = mC_base.alignIndex(mA_more, "subset")

% example (2 common dimensions, extra dim obj2)
[mindexnew, row_ind1, row_ind2] = mA_base.alignIndex(mC_base , "full")
[mindexnew, row_ind1, row_ind2] = mA_base.alignIndex(mC_less , "subset")

% example (1 common dimensions with missing (gives error), extra dim obj1 & obj2)
try
   [mindexnew, row_ind1, row_ind2] = mA_less.alignIndex(mB_base , "full")
catch err    
    disp(err)
end


%% Examples of arithmetic with MultiIndex DataFrames

% linear axes
x = 1:4;
y = 1:3;
z = 1:3;

% dataframes
rng('default');
dfX = frames.DataFrame( randi(10,length(x),2), frames.MultiIndex({x},name="x"), ["A","B"]);
dfY = frames.DataFrame( randi(20,length(y),2), frames.MultiIndex({y},name="y"), ["A","B"]);
dfZ = frames.DataFrame( randi(20,length(z),2), frames.MultiIndex({z},name="z"), ["A","B"]);

dfXsubset = dfX{1:end-1};
dfXs = frames.DataFrame( dfX.data, frames.Index(x,name="x"), ["A","B"]);
dfYs = frames.DataFrame( dfY.data, frames.Index(y,name="y"), ["A","B"]);
dfXY = dfX + dfY;

% perform operations
df1 = dfXY + dfX
df2 = dfXY + dfXs
df3 = dfX - dfY
df4 = dfXY .* dfXsubset
df5 = (dfX+dfY).*dfZ + dfXY
df6 = (dfX+dfYs).*dfZ + dfXY



%% DataFrame with both rows as columns MultiIndex

dfsm = frames.DataFrame( magic(4), frames.Index(1:4,name="x"), ...
                                  frames.MultiIndex({[1 1 2 2],["a" "b" "a" "b"]},name=["A", "B"]))

dfmm1 = frames.DataFrame( magic(4), frames.MultiIndex({1:4},name="x"), ...
                                  frames.MultiIndex({[1 1 2 2],["a" "b" "a" "b"]},name=["A", "B"]))
                              
dfmm2 = frames.DataFrame( magic(4), frames.MultiIndex({11:14},name="y"), ...
                                  frames.MultiIndex({[1 1 2 2],["a" "b" "a" "b"]},name=["A", "B"]))

dfmm3 = frames.DataFrame( magic(2), frames.MultiIndex({11:12},name="y"), ...
                                  frames.MultiIndex({[2 2],["a" "b"]},name=["A", "B"]))
                                                          
dfsm + dfmm1
dfmm1 + dfmm3
dfmm2 + dfmm3*1000


% sub selection
df = dfmm1+dfmm2
df( {':',11} , {':',"b"})

