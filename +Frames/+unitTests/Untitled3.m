[frames.DataFrame([4 2;1 1],frames.OrderedIndex([1 2]), [23 3]);frames.DataFrame([4 2;1 1],frames.OrderedIndex([3 4]), [3 44])]

[frames.DataFrame([4 2;1 1],[1 2], [23 3]),frames.DataFrame([4 2;1 1],[1 3], [4 2])]

frames.DataFrame([4 2;1 NaN;NaN 4],[1 2 4], [23 3]).resample([2 5],firstValueFilling='ffillFromInterval')

frames.DataFrame([1 2 3; 2 5 3]', frames.TimeIndex([1 3 65]), [4 1]).sortBy(1)

frames.DataFrame([1 2 3; 2 5 3]', frames.UniqueIndex([6 2 1]), [4 1]).sortByIndex()

df.split({4,1},["d","e"]).apply(@(x) x)
splitapply b exampl