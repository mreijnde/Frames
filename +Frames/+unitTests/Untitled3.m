[frames.DataFrame([4 2;1 1],frames.SortedIndex([1 2]), [23 3]);frames.DataFrame([4 2;1 1],frames.SortedIndex([3 4]), [3 44])]

[frames.DataFrame([4 2;1 1],[1 2], [23 3]),frames.DataFrame([4 2;1 1],[1 3], [4 2])]

frames.DataFrame([4 2;1 NaN;NaN 4],[1 2 4], [23 3]).setIndexType("sorted").resample([2 5],firstValueFilling='ffillFromInterval')

frames.DataFrame([1 2 3; 2 5 3]', frames.TimeIndex([1 3 65]), [4 1]).sortBy(1)

frames.DataFrame([1 2 3; 2 5 3]', frames.UniqueIndex([6 2 1]), [4 1]).sortIndex()

df=frames.DataFrame([1 2 3; 2 5 3;5 0 1]', [6 2 1], [4 1 3])
df.split({[4,3],1},["d","e"]).apply(@(x) x)
ceiler.d = {2.5,4.5};
ceiler.e = {2.6};
df.split({[4,3],1},["d","e"]).apply(@(x) x.clip(ceiler.(x.name){:}))
s.d = [4 3]; s.e = 1;
df.split(s,["d","e"]).apply(@(x) x.clip(ceiler.(x.name){:}))
g = frames.Groups([1 3 4], s)
df.split(g,["d","e"]).apply(@(x) x.clip(ceiler.(x.name){:}))
% 
% mat = [NaN 1 NaN; NaN 2 3; NaN NaN 4];
% idx = findColumnStart(mat);
% getElementIDShift(idx,size(mat,1),size(mat,2),-1);

% data = [ 1 2 3 4 NaN 6;NaN NaN NaN NaN NaN NaN ; NaN NaN 33 44 55 66]'
% replaceStartBy(data,0)
% emptyStart(data,2)

df = frames.DataFrame([ NaN 2 3 4 NaN 6;NaN NaN NaN 1 NaN 1 ; NaN NaN 33 44 55 66]');
df.firstCommonIndex()
df.firstValidIndex()

df=frames.DataFrame([1 2 3; 2 5 3;5 1 1]', [6 2 1], [4 1 3])
df.relChg('log').compoundChange('log',[1 2 5])
df.relChg().compoundChange('simple',[1 2 5])

df' * df
df + df
df + df.data
1 + df
df.data' * df
df' \ df

a = datetime(1:10,'ConvertFrom','datenum')
b=timerange('02.01.0000','03.01.0000')
frames.TimeIndex(a).positionOf(a(3:end))
frames.TimeIndex(a).positionOf('02-Jan-0000:03-Jan-0000:dd-MMM-uuuu')

df.std(2)
df.sum()
df.maxOf(3)
df.maxOf(df+1)
df.max(2).min()

tf=frames.TimeFrame(1,1:10,[])
tf('02.01.0000:04.01.0000:dd.MM.uuuu')


frames.TimeFrame().index
frames.DataFrame.empty("datetime").index

frames.TimeFrame(1,frames.TimeIndex(string(2010:2015),format='yyyy')).toFile('y')
frames.TimeFrame.fromFile('y',timeFormat='yyyy')

df.corr()
df.cov()

df.rolling(2).sum()


df=frames.DataFrame([1 2 3 3 2 1; 2 5 NaN 1 3 2;5 0 1 1 3 2]')
df.rolling(6).covariance(df.data(:,[2,3]))
cov(df.data(:,[2,3]),'partialrows')
df.rolling(6).covarianceM(df.data(:,2),df.data(:,[1,3]))

df.rolling(6).correlationM(df.data(:,2),df.data(:,[1,3]))
df.rolling(6).correlation(df.data(:,[2,3]))
corrcoef(df.data(:,[2,3]),Rows='pairwise')

df.dropMissing(how='any')

cov(df.dropMissing(how='any').data(:,[2,3]),'partialrows') ./var(df.dropMissing(how='any').data(:,[2,3]))
df.rolling(6).betaXY_M(df.data(:,2),df.data(:,[1,3]))
df.rolling(6).betaXY_M(df.data(:,3),df.data(:,[1,2]))