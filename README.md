# Frames

**Frames** is a package that introduces a new kind of data type for Matlab.

This data type can help when working with homogeneous data that are referenced by column and index identifiers (like time series which have variable and observation names).

Matlab already has several data types available, but none is well suited for homogeneous, labeled data.

Below are the fundamental data types provided by Matlab together with the new _Frame_.

![fundamental_classes](https://user-images.githubusercontent.com/57812158/124361682-8ef69e00-dc30-11eb-8fa3-1b4e81f24140.png)

When one works with data with names for index and columns, one can use _table_.

However this class does not allow simple operations like addition (table1+table2 is not supported) or operation on data (abs(table) is not available).

One can work directly with the numeric type, but one loses the information of the index and column names, risking adding apples to pears.

**_Frame_ aims at being both a matrix and a table**, allowing intuitive operations on and between Frames, forbidding operations when the Frames are not aligned.
For example, frame1 + frame2 is possible, and will fail if indices or columns are misaligned.

There are two types of Frames: DataFrame and TimeFrame, in relation with Matlab's table and timetable.
A DataFrame accepts any kind of index (numeric, string, etc.) while TimeFrame is specifically built to work with a chronological time index (ideal for time series).

A demo is available in [html/framesDemo.html](html/framesDemo.html) and can be also found in the live script format [framesDemo.mlx](framesDemo.mlx).

The documentation is available using Matlab's command
```Matlab
doc frames.DataFrame
% or frames.TimeFrame
```

Compatible with Matlab R2021a and later versions. No other toolbox are required.

<p align="center"><img width=12.5% src="img/docIntro.png"></p>
