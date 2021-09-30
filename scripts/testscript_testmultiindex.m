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


%% Align and expand multiIndex

% sorted example
mindexA = frames.MultiIndex({ [1 2 2 2 3 3 4 4 4 4 5 5 6 ], ...
                              [1 1 2 3 1 2 1 2 3 4 1 2 1 ]}, name=["x","y"]);

                          
mindexB = frames.MultiIndex({ [ 1   1   2   3   4   4   4   5   6   6], ...
                              ["a" "b" "c" "e" "f" "g" "h" "i" "j" "k" ]}, name=["x","k"]);

                          
                          
                          
[mindexnew, row_ind1, row_ind2] = mindexA.alignIndex(mindexB)


% non-sorted example
                          
mindexA_mixed = frames.MultiIndex({ [4 3 1 2 2 2 3 4 5 4 4 5 6 ], ...
                                    [3 1 1 1 2 3 2 1 2 2 4 1 1 ]}, name=["x","y"])
                          
                          
                          

mindexB_mixed = frames.MultiIndex({ [5   6    6   1   2   1   4   3    4   4 ], ...
                                    ["i" "k" "j" "f" "c" "a" "f" "e"  "g" "h"]}, name=["x","k"])
                          
                          

[mindexnew, row_ind1, row_ind2] = mindexA_mixed.alignIndex(mindexB_mixed)


