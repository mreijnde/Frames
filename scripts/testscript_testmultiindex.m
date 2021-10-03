% script with some basic examples/tests for MultiIndex
%
% (work in progress)

clear all
clc
%% MultiIndex DataFrame with selection optins
warning('off','frames:Index:notUnique');

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


%%
% linear axes
x = 1:4;
y = 1:3;
z = 1:3;
xl = x(1:end-1); 
yl = y(1:end-1); 
zl = z(1:end-1); 

% Index objects 
sx = frames.Index(x,name="x");
sy = frames.Index(y,name="y");
sz = frames.Index(z,name="z");
mX = frames.MultiIndex({x},name="x");
mY = frames.MultiIndex({y},name="y");
mZ = frames.MultiIndex({z},name="z");
mXl = frames.MultiIndex({xl},name="x");
mYl = frames.MultiIndex({yl},name="y");
mZl = frames.MultiIndex({zl},name="z");


% combined MultiIndex
mXY = mX.alignIndex(mY);
mXZ = mX.alignIndex(mZ);
mXYZ = mXY.alignIndex(mZ);

mXl.alignIndex(mXY,"full");

% dataframes
rng('default');
dfX = frames.DataFrame( randi(10,length(x),2), mX, ["A","B"]);
dfXl = frames.DataFrame( randi(10,length(xl),2), mXl, ["A","B"]);
dfY = frames.DataFrame( randi(20,length(y),2), mY, ["A","B"]);
dfXY = frames.DataFrame( randi(20,length(y)*length(x),2), mXY, ["A","B"]);
dfZ = frames.DataFrame( randi(20,length(z),2), mZ, ["A","B"]);
dfXs = frames.DataFrame( randi(10,length(x),2), sx, ["A","B"]);

% perform operations
df1 = dfXY + dfX
df2 = dfXY + dfXs
df3 = dfX - dfY
df4 = dfXY .* dfXl
df5 = (dfX+dfY).*dfZ
