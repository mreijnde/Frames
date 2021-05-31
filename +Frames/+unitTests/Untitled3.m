[frames.DataFrame([4 2;1 1],frames.OrderedIndex([1 2]), [23 3]);frames.DataFrame([4 2;1 1],frames.OrderedIndex([3 4]), [3 44])]

[frames.DataFrame([4 2;1 1],[1 2], [23 3]),frames.DataFrame([4 2;1 1],[1 3], [4 2])]

frames.DataFrame([4 2;1 NaN;NaN 4],[1 2 4], [23 3]).resample([2 5],firstValueFilling='ffillFromInterval')

frames.DataFrame([1 2 3; 2 5 3]', frames.TimeIndex([1 3 65]), [4 1]).sortBy(1)

frames.DataFrame([1 2 3; 2 5 3]', frames.UniqueIndex([6 2 1]), [4 1]).sortByIndex()

df=frames.DataFrame([1 2 3; 2 5 3;5 0 1]', [6 2 1], [4 1 3])
df.split({[4,3],1},["d","e"]).apply(@(x) x)
ceiler.d = {2.5,4.5};
ceiler.e = {2.6};
df.split({[4,3],1},["d","e"]).apply(@(x) x.clip(ceiler.(x.name){:}))
s.d = [4 3]; s.e = 1;
df.split(s,["d","e"]).apply(@(x) x.clip(ceiler.(x.name){:}))
g = frames.Groups([1 3 4], s)
df.split(g,["d","e"]).apply(@(x) x.clip(ceiler.(x.name){:}))