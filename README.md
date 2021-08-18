# Frames

**Power of matrices, robustness of tables.**

[![View Frames on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://ch.mathworks.com/matlabcentral/fileexchange/95258-frames)

## Purpose of the package
**Frames** is a package that introduces a new kind of data type for Matlab, the **DataFrame**. Demo: [html/framesDemo.html](https://htmlpreview.github.io/?https://github.com/benjamingaudin/Frames/blob/main/html/framesDemo.html) 

This data type (or _class_) helps when working with data matrices that are referenced by column and index identifiers (e.g. time series which have variable and observation names).

Matlab currently provide matrices and tables, but they do not work well together:
   - Matlab native matrices are not aware of row and column names; when data represents observations of variables, it is always tricky to make sure the data is not misaligned (i.e. how to make sure that the ith row in matrices A and B represents the same observation).
   - Matlab (time)tables have row and column names, but do not provide simple operations like addition (`table1+table2` is not possible). 

**_Frame_ aims at being both a matrix and a table**, allowing intuitive operations on and between Frames, while applying sanity checks on index and columns.
For example, `frame1+frame2` is possible, and it will give an error if the index or columns are misaligned.

There are many more operations and tools to discover in the package. 

Below are the fundamental data types provided by Matlab together with the new _Frame_.

![fundamental_classes](https://user-images.githubusercontent.com/57812158/124361682-8ef69e00-dc30-11eb-8fa3-1b4e81f24140.png)

We provide two types of Frames: **`DataFrame`** and **`TimeFrame`**. 
The distinction between the two is similar to that between Matlab native `table` and `timetable`; basically, the properties and methods are the same, but there are a few additional tools to handle time series in TimeFrame.

The package is compatible with **Matlab R2021a** and later versions. No other toolbox is required.

## Demo and documentation
A demo is available in [html/framesDemo.html](https://htmlpreview.github.io/?https://github.com/benjamingaudin/Frames/blob/main/html/framesDemo.html) and can be also found in the live script format [framesDemo.mlx](framesDemo.mlx).

The documentation is available using Matlab's command
```Matlab
doc frames.DataFrame
doc frames.TimeFrame
```

## Contact
Please send questions, feedback, suggestions, bug reports to <frames.matlab@gmail.com> or open an issue on the [github project](https://github.com/benjamingaudin/Frames/issues). 

## License
Copyright 2021-2022 Benjamin Gaudin

Frames is free software made available under the MIT License. For details see the LICENSE file.
