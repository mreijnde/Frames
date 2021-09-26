% script with some basic examples/tests for MultiIndex
%
% (work in progress)

clear

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


                         
                         
%% Concatenate multi index                         
mindex2 = frames.MultiIndex({[3 3 3 4 4], [5 6 7 5 6], ["a" "a" "b" "b" "a"]},name=["x","y","z"])
mindex_new = [mindex; mindex2]


%% Align and expand multiIndex

% NOT YET WORKING, WRONG RESULT

%mindexA = frames.MultiIndex({[ 1 1 1 1 1 1 2 2 2 2 2 2], [1 2 3 1 2 3 1 2 3 1 2 3], [ 1 1 1 2 2 2  1 1 1 2 2 2]}, name=["k", "x","y"])
%mindexA = frames.MultiIndex({ [1 2 3 1 2 3 ], [1 1 1 2 2 2]}, name=["x","y"])
%mindexB = frames.MultiIndex({ [2 2 2 1 1 1 1 1 1], [1 3 2 1 2 3 1 2 3], ["a" "b" "c" "d" "e" "f", "g", "h","i"]}, name=["y","x","z"])

%[mindexnew, row_ind1, row_ind2] = mindexA.alignIndex(mindexB)


