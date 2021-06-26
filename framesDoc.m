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
%% Constructor
%