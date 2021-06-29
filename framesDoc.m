%% frames package
% The frames package contains classes to handle operations on homogeneous 
% data matrices that are referenced by column and index identifiers.
%
% There are currently no tool in Matlab to do that.
% Matlab's (time)tables have row and column names, but do not provide
% simple operations like addition (table1+table2 is not possible).
% Matlab's native matrices are not aware of row and column names. When data
% represents observations of variables, it is always tricky to make sure the
% data is not misaligned.
%
%% Frame classes
%
% The class *frames.DataFrame* and its child class *frames.TimeFrame* aim to 
% give a solution to working with this kind of data (homogeneous and with column and 
% row names), to make operations on and between Frames simple and robust.
%
% Their main properties are:
%
% * data:       TxN,  homogeneous data
% * index:      Tx1
% * columns:    1xN
% * t: dependent table built on the properties above.
%
% _columns_ and _index_ are expected to have unique elements. _columns_
% allows duplicates but issues a warning if it is the case. _index_ does
% not accept duplicates.
% Moreover, for TimeFrame, _index_ is a chronological datetime array.
%
% The Frames are displayed as a table (DataFrame) and as a timetable (TimeFrame).
%
% For the documentation, run
doc frames.DataFrame
doc frames.TimeFrame
%%
%% Constructor
% 
% Construct a Frame as follows:
%
%   df = frames.DataFrame([data,index,columns,Name=name,RowSeries=logical,ColSeries=logical])
df = frames.DataFrame([1 2;3 4],[1 2],["col1","col2"])
%%
% or with a TimeFrame
tf = frames.TimeFrame([1 2;3 4],[737970,737971],["ts1","ts2"])
%%
% To view the properties of the object, type
details(df)
%%
% One can see the properties we have just set in the constructor.
% The other properties (some of which can be set in the constructor with
% named arguments) are presented further below.
%
%% Properties Access and Modification
% The properties can be accessed simply by
df.data
df.columns
%%
% They can also be modified
df.data(1,1) = 10;
df.columns = ["a","b"]
%%
% Frame will throw an error if the data entered are not coherent, e.g. the
% size is the matching the rest of the data:
try
    df.columns = ["a","b","c"]
catch me
    disp(me.message)
end
%%
% Or an example with an attempt to assign a duplicate index:
try
    df.index = [1 1]
catch me
    disp(me.message)
end
%% Sub-Frame Access and Modification

%%
%  Select and modify based on index/column names with () or the loc method:
%   * df(indexNames,columnsNames)
%   * df.loc(indexNames,columnsNames)
%   * df(indexNames,columnsNames) = newData
%   * df.loc(indexNames,columnsNames) = newData
df(1,:)
% same as
df.loc(1,:);
df(1);
df.loc(1);
%%
df(1,:) = 10
% Or df.loc(1,:) = 10
%%
% One can also drop a column/row with the empty assignment
tmp = df;
tmp(:,"b") = []
%%
%  Select and modify based on position with {} or the iloc method:
%   *  df{indexPosition,columnsPosition}
%   *  df.iloc(indexPosition,columnsPosition)
%   *  df{indexPosition,columnsPosition} = newData
%   *  df.iloc(indexPosition,columnsPosition) = newData
df{1:end,2}
% same as
df{:,2};
df.iloc(:,2);
%%
df{2,1} = 20
% or df.iloc(2,1) = 20
df.data = [1 2;3 4];  % reset data to original example
%% Operations
% Frames can be used like matrices for operations.
%%
% element-wise operation
df + df
%%
% element-wise operation with a non-Frame 
1 + df
%%
% transpose and matrix operation
df' * df
vector = frames.DataFrame([1;2],["a","b"],"vectorColumn");
df * vector
%%
% If Frames are not aligned, an element-wise operation will return an error:
df2 = frames.DataFrame(1,[1 2],["noMatch1","noMatch2"]);
try
    df ./ df2
catch me
    disp(me.message)
end
%%
% For element-wise vector operations, only one dimension is needed to be checked for
% right or wrong alignement.
%
% To do so, one needs to set the _series property_ of the vector Frame to
% true. There are two series properties available, _.rowseries_, and
% _.colseries_, depending on whether the Frame is a row or column vector.
%
% If the property is not set, the operation fails:
seriesBad = frames.DataFrame([1;2],[1 2],"seriesColumn");
try
    df .* seriesBad
catch me 
    disp(me.message)
end
%%
series = seriesBad.asColSeries();
% or series = frames.DataFrame([1;2],[1 2],"seriesColumn",ColSeries=true);
details(series)
df .* series
%% Concatenation
% One can concatenate different Frames into one with the operator [].
%
% The concatenation can be horizontal or vertical. The operation will
% align the Frames by expanding (unifying) their index or columns if they 
% are not equal, inserting missing values in the expansion.
tf1 = frames.TimeFrame(1,frames.TimeIndex(["25.06.2021","27.06.2021","28.06.2021"]),["ts1","ts2"]);
tf2 = frames.TimeFrame(2,frames.TimeIndex(["26.06.2021","27.06.2021","30.06.2021"]),"ts3");
[tf1, tf2]
%%
tf3 = frames.TimeFrame(2,frames.TimeIndex(["29.06.2021","30.06.2021"]),["ts2","ts3"]);
[tf1; tf3]
%% Particular use of Index
% The type of _index_ can be specified, as one may have noticed in the
% example above.
%
% By default, in DataFrame, the object underlying the index is a
% _frames.UniqueIndex_, and in TimeFrame, it is a _frames.TimeIndex_.
% The former requires unique elements, while the latter requires chronological
% unique time elements.
%
% TimeFrame only accepts a TimeIndex, while DataFrame accepts UniqueIndex,
% TimeIndex, and SortedIndex (unique and sorted).
%
% The distinction between the different Index impacts the operations of
% selection, modification, and alignment/concatenation.
df.getIndex_()  % gets the underlying Index object
df([2 1])
%%
dfSorted = df.setIndexType("sorted");
dfSorted.getIndex_()
try
    dfSorted([2 1])
catch me
    disp(me.message)
end
%%
% TimeIndex can read several kinds of arguments: datenum, datetime, and
% strings/cell together with a Format
frames.TimeIndex(737971)
frames.TimeIndex(datetime(737970,'ConvertFrom','datenum'))
frames.TimeIndex("28-Jun-2020",Format="dd-MMM-yyyy")

