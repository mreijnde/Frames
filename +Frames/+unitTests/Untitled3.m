[frames.DataFrame([4 2;1 1],frames.OrderedIndex([1 2]), [23 3]);frames.DataFrame([4 2;1 1],frames.OrderedIndex([3 4]), [3 44])]

[frames.DataFrame([4 2;1 1],[1 2], [23 3]),frames.DataFrame([4 2;1 1],[1 3], [4 2])]

frames.DataFrame([4 2;1 NaN;NaN 4],[1 2 4], [23 3]).resample([2 5],firstValueFilling='ffillFromInterval')
