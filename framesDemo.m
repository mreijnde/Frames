%% *Frames* package
% The *frames* package contains two classes to handle operations on matrices 
% that are referenced by column and index identifiers.
% 
% Matlab currently provide matrices and tables, but they do not work well together:
% 
% - Matlab native matrices are not aware of row and column names; when data 
% represents observations of variables, it is always tricky to make sure the data 
% is not misaligned (i.e. how to make sure that the ith row in matrices A and 
% B represents the same observation).
% 
% - Matlab (time)tables have row and column names, but do not provide simple 
% operations like addition (table1+table2 is not possible). 
% 
% *Frames* aims at being both a table and a matrix, allowing matrix operations 
% while being aware of row and column names.
% 
% The package currently requires a version of *Matlab R2021a* or later.
% 
% Author: Benjamin Gaudin
% 
% Email: frames.matlab@gmail.com
%% Frame classes
% The class *DataFrame* and its child class *TimeFrame* provide a data type 
% suitable when working with data sets that can be written as _matrices_ (i.e. 
% that have a homogoneous type) and that have _column and row names._ They make 
% operations on and between Frames simple and robust. The distinction between 
% the two is similar to that between Matlab native _table_ and _timetable_; basically, 
% the properties and methods are the same, but there are a few additional tools 
% to handle time series in TimeFrame.
% 
% The main properties of these classes are:
%% 
% * data: TxN, data matrix
% * index: Tx1
% * columns: 1xN
% * t: dependent table built on the properties above.
%% 
% The Frames are displayed as a table (DataFrame) and as a timetable (TimeFrame).
% 
% For the documentation, run

doc frames.DataFrame
doc frames.TimeFrame
%% 
% 
%% Constructor
% Construct a Frame as follows:
%%
% 
%  df = frames.DataFrame([data,index,columns,Name=name,RowSeries=logical,ColSeries=logical])
%

% Example:
df = frames.DataFrame([1 2;3 4],[1 2],["col1","col2"])
%% 
% or with a TimeFrame

tf = frames.TimeFrame([1 2;3 4],[738336,738337],["ts1","ts2"])
%% 
% To view the properties of the object, type

details(df)
%% 
% One can see the properties we have just set in the constructor. The other 
% properties (some of which can be set in the constructor with named arguments) 
% are presented further below.
%% Properties Access and Modification
% The properties can be accessed simply by

df.data
df.columns
%% 
% They can also be modified

df.data(1,1) = 10;
df.columns = ["a","b"]
%% 
% Frame will throw an error if the data entered are not coherent, e.g. the size 
% is the matching the rest of the data:

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
% 
%  Select and modify based on index/column names with () or the loc method:
%   * df(indexNames,columnsNames)
%   * df.loc(indexNames,columnsNames)
%   * df(indexNames,columnsNames) = newData
%   * df.loc(indexNames,columnsNames) = newData
%

% Selection
df(1,:)
% same as
df.loc(1,:);
df(1);
df.loc(1);
%%
% Modification
df(1,:) = 10
% Or df.loc(1,:) = 10
%% 
% One can also drop a column/row with the empty assignment

tmp = df;
tmp(:,"b") = []
%%
% 
%  Select and modify based on position with {} or the iloc method:
%   *  df{indexPosition,columnsPosition}
%   *  df.iloc(indexPosition,columnsPosition)
%   *  df{indexPosition,columnsPosition} = newData
%   *  df.iloc(indexPosition,columnsPosition) = newData
%

df{1:end,2}
% same as
df{:,2};
df.iloc(:,2);
%%
df{2,1} = 20
% or df.iloc(2,1) = 20
%%
df.data = [1 2;3 4];  % reset data to original example
%% Operations
% Frames can be used like matrices for operations.
% 
% element-wise operation

df + df
%% 
% Contrast this with Matlab table:

tb = table([1;3],[2;4],'VariableNames',{'a','b'},'RowNames',{'1','2'});
tb;
try
    tb + tb
catch me
    disp(me.message)
end
%% 
% Element-wise operation with a non-Frame 

% df + 1
1 + df
%% 
% transpose and matrix operation

df' * df
%%
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
% For element-wise vector operations, only one dimension is needed to be checked 
% for right or wrong alignement.
% 
% To do so, one needs to set the _series property_ of the vector Frame to true. 
% There are two series properties available, _.rowseries_, and _.colseries_, depending 
% on whether the Frame is a row or column vector.
% 
% If the property is not set, the operation fails:

seriesBad = frames.DataFrame([1;2],[1 2],"seriesColumn");
try
    df .* seriesBad
catch me 
    disp(me.message)
end
%% 
% Make it work by making the Frame a Series

series = seriesBad.asColSeries();
% or series = frames.DataFrame([1;2],[1 2],"seriesColumn",ColSeries=true);
df .* series
%% Concatenation
% One can concatenate different Frames into one with the operator [].
% 
% The concatenation can be horizontal or vertical. The operation will align 
% the Frames by expanding (unifying) their index or columns if they are not equal, 
% inserting missing values in the expansion.

tf1 = frames.TimeFrame(1,["25-Jun-2021","27-Jun-2021","28-Jun-2021"],["ts1","ts2"]);
tf2 = frames.TimeFrame(2,["26-Jun-2021","27-Jun-2021","30-Jun-2021"],"ts3");
[tf1, tf2]
%%
tf3 = frames.TimeFrame(2,frames.TimeIndex(["29.06.2021","30.06.2021"],Format="dd.MM.yyyy"),["ts2","ts3"]);
[tf1; tf3]
%% Index Object
% The _index_ and _columns_ properties can be assigned some properties themselves, 
% namely whether they are required to have unique elements, and whether these 
% are required to be sorted.
% 
% By default, the _columns_ allow duplicates, while the _index_ require unique 
% elements. For TimeFrame, the _index_ also requires sorted elements.
% 
% These can be changed by explicitely using the _Index_ object that underlies 
% the _index_ and _columns_ properties.
% 
% Here is an example of an Index:

frames.Index([1,2])
%% 
% * The _singleton_ property is related to the series property of the DataFrame. 
% If the Frame is set to be a _rowseries_, the Index object underlying the _index_ 
% will be a _singleton_. If the Frame is set to be a _colseries_, then it will 
% be that underlying the _columns_.
% * If _requireUnique_ is set to _true_, then _value_ is required to have unique 
% elements (otherwise it throws an error).
% * If _requireUniqueSorted_ is set to _true_, then _value_ is required to have 
% unique and sorted elements.
%% 
% These properties impact the operations of selection, modification, and alignment/concatenation.

% Selection
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
% Alignment

df1 = frames.DataFrame([1 3]',[1 3],1);
df2 = frames.DataFrame([2 3]',[2 3],2);
unsortedConcatenation = [df1,df2]
df1 = frames.DataFrame([1 3]',frames.Index([1 3],UniqueSorted=true),1);
df2 = frames.DataFrame([2 3]',frames.Index([2 3],UniqueSorted=true),2);
sortedConcatenation = [df1,df2]
%% 
% For TimeFrame, the Index object for _index_ is a *TimeIndex*.
% 
% TimeIndex can read several kinds of arguments: datenum, datetime, and strings/cell 
% together with a Format

frames.TimeIndex(738336)
frames.TimeIndex(datetime(738336,'ConvertFrom','datenum',Format='dd-MMM-yyyy'));
frames.TimeIndex("29-Jun-2021",Format="dd-MMM-yyyy");
%% 
% When used in a Frame (used by default in a TimeFrame), one can select a sub-Frame 
% using a _timerange_

tf = frames.TimeFrame((1:6)',738331:738336)  % the constructor turns 738331:738336 into a TimeIndex
tf(timerange(-inf,datetime(738333,'ConvertFrom','datenum'),'closed'));
% This can also be easily written using a string as follows
% tf("dateStart:dateEnd:dateFormat")
tf("-inf:26*06*2021:dd*MM*yyyy")
% or with curly brackets
% tf({dateStart,dateEnd})
tf({-inf,"26-Jun-2021"});
%% Methods Chaining
% Several methods are available. Again, please refer to the documentation for 
% the full list

doc frames.DataFrame
doc frames.TimeFrame
%% 
% Methods can be chained to apply them one after the other.

% Example: build random correlated data and apply functions to the TimeFrame.
s = rng(2021);
nObs = 1000;
nVar = 3;
[randomRotationMatrix,~] = qr(randn(nVar));
randomEigenValues = rand(1,nVar);
covariance = randomRotationMatrix * diag(randomEigenValues) * randomRotationMatrix';
correlation = diag(diag(covariance).^-0.5) * covariance * diag(diag(covariance).^-0.5)
upper = chol(correlation);
randomData = randn(nObs,nVar)./100 + 1./3000;
correlatedData = randomData*upper;
tf = frames.TimeFrame(correlatedData,738336-nObs+1:738336,1:nVar);
%%
tf.cumsum().plot()  % apply a cumulative sum and then plot the result
%%
tf.corr().heatmap(CellLabelFormat='%.2f')  % compute the correlation matrix and plot it as a heatmap
%% Rolling and Ewm
% Computation on a rolling basis are available with the _.rolling()_ and the 
% _.ewm()_ methods. _.rolling()_ applies computations on a rolling window basis. 
% _.ewm()_ applies computations by weighting observations with exponentially decaying 
% weights.
%%
% 
%  Use:
%   * .rolling(window[,windowNaN]).<method>
%   * .ewm(<DecayType>=value).<method>
%
%% 
% Please refer to the documentation for details on arguments and methods.

doc frames.DataFrame.rolling
% or 
doc frames.internal.Rolling
%%
doc frames.DataFrame.ewm
% or
doc frames.internal.ExponentiallyWeightedMoving
%% 
% Below, we give a few examples on how these methods can be used, using our 
% previous TimeFrame.

price = tf.compoundChange('log');  % assume tf contains log returns and compound them
rollingMean = price.rolling(30).mean();  % 30-day moving average
exponentialMean = price.ewm(Span=30).mean();  % 30-day exponentially moving average
priceSmoothers = [price{:,1}, rollingMean{:,1}, exponentialMean{:,1}];  % group the first series
priceSmoothers.columns = ["original", "rolling", "smooth"];  % assign new column names
priceSmoothers.name = "smoothers";  % assign the name (it appears as the plot title)
priceSmoothers.plot(Log=true)
%%
tf.ewm(Halflife=10).std().plot(Title='ewmstd')  % exponentially weighted moving standard deviation
%% Split Apply
% One can apply a function to groups of columns in a Frame using the method 
% _.split(groups).apply(@<function>)_.
%%
% 
%  The groups of columns can be expressed in different ways.
%   * (cellArrayOfGroupLists,groupNames)
%   * structure: fields are group names and values are elements in each group
%   * frames.Group: Group whose property  are group names and property
%       values are elements in each group. See 'doc frames.Group' for more
%       details.
%

df = frames.DataFrame([1 2 3;2 5 3;5 0 1]',[],["a" "b" "c"])
%%
% simple example with cell
% apply a sum horizontally in each group
x1 = df.split({["a" "c"],"b"},["group1","group2"]).apply(@(x) x.sum(2))
%%
% apply function using group names
% multiply each group by 10 and 1 respectively
multiplier.group1 = 10;
multiplier.group2 = 1;
x2 = df.split({["a" "c"],"b"},["group1","group2"]).apply(@(x) x.*multiplier.(x.name))
%%
% split with a structure
% cap each group at 1.5 and 2.5 respectively
s = struct();
s.group1 = ["a" "c"];
s.group2 = "b";
ceiler.group1 = 1.5;
ceiler.group2 = 2.5;
x3 = df.split(s).apply(@(x) x.clip(ceiler.(x.name)))
%%
% split with a Group
% take the maximum of each groups at each row
g = frames.Groups(df.columns,s);
x4 = df.split(g).apply(@(x) x.max(2))
%% Other Methods
% We list here all the methods available in the DataFrame. We provided a demo 
% above for some of them. 
% 
% Refer to the documentation for detailed information. You can also refer to 
% the unit tests (+frames/+unitTests/) for some examples.

methods('frames.DataFrame')