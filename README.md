# Frames
[![View Frames on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://ch.mathworks.com/matlabcentral/fileexchange/95258-frames)

## Purpose of the package
**Frames** is a package that introduces a new kind of data type for Matlab, the **DataFrame**. Demo: [html/framesDemo.html](https://htmlpreview.github.io/?https://github.com/benjamingaudin/Frames/blob/main/html/framesDemo.html) 

This data type (or _class_) helps when working with homogeneous data that are referenced by column and index identifiers (like time series which have variable and observation names).

Matlab already has several data types available, but none is well suited for homogeneous, labeled data.

Below are the fundamental data types provided by Matlab together with the new _Frame_.

![fundamental_classes](https://user-images.githubusercontent.com/57812158/124361682-8ef69e00-dc30-11eb-8fa3-1b4e81f24140.png)

When one works with data with names for index and columns, one can use a `table`.

However this class does not allow simple operations like addition (`table1+table2` is not supported) or operation on data (like `abs(table)`) is not directly available.

If one works directly with the numeric type, one loses the information of the index and column names, risking adding apples to pears.

**_Frame_ aims at being both a matrix and a table**, allowing intuitive operations on and between Frames, while forbidding operations when the Frames are not aligned.
For example, `frame1+frame2` is possible, and will fail if indices or columns are misaligned.

We provide two types of Frames: **`DataFrame`** and **`TimeFrame`**, in relation with Matlab's `table` and `timetable`.
A `DataFrame` accepts any kind of index (numeric, string, etc.) while `TimeFrame` is specifically built to work with a chronological time index (ideal for time series).

The package is compatible with **Matlab R2021a** and later versions. No other toolbox is required.

## Demo and documentation
A demo is available in [html/framesDemo.html](https://htmlpreview.github.io/?https://github.com/benjamingaudin/Frames/blob/main/html/framesDemo.html) and can be also found in the live script format [framesDemo.mlx](framesDemo.mlx).

The documentation is available using Matlab's command
```Matlab
doc frames.DataFrame
doc frames.TimeFrame
```
<p><img src="img/docIntro.png"></p>
<p><img src="img/docMethodsDescr.png"></p>
<p><img src="img/docProps.png"></p>
<p><img src="img/docMethodsSummary1.png"></p>
<p><img src="img/docMethodsSummary2.png"></p>

## Contact
Please send questions, feedback, suggestions, bug reports to <frames.matlab@gmail.com> or open an issue on the [github project](https://github.com/benjamingaudin/Frames/issues). 

## License
Copyright 2021-2022 Benjamin Gaudin

Frames is free software made available under the MIT License. For details see the LICENSE file.
