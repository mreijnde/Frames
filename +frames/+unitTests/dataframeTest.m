classdef dataframeTest < matlab.unittest.TestCase
    
    properties
        dfNoMissing = frames.DataFrame([1 2 3; 2 5 3;5 1 1]', [6 2 1], [4 1 3]);
        dfMissing1 = frames.DataFrame([1 2 3 3 2 1; 2 5 NaN 1 3 2;5 0 1 1 3 2]');
        tfMissing1 = frames.TimeFrame([1 2 3 3 2 1; 2 5 NaN 1 3 2;5 0 1 1 3 2]',[],["a","b","c"]);
        dataPath = string(fileparts(mfilename('fullpath')))
        tol = 1e-10;
    end
    
    methods(Test)
        
        function constructorTest(t)
            
            % empty
            emptyTT = frames.TimeFrame();
            t.verifyTrue(isempty(emptyTT.data)&&isempty(emptyTT.index)&&isempty(emptyTT.columns))
            t.verifyTrue(isdatetime(emptyTT.getIndex_().value))
            t.verifyTrue(isa(emptyTT.getIndex_(),'frames.TimeIndex'))
            
            emptyDF = frames.DataFrame.empty("datetime");
            t.verifyTrue(isdatetime(emptyDF.index))
            t.verifyTrue(isa(emptyDF.getIndex_(),'frames.Index'))
            
            % error index not sorted
            t.verifyError(@() frames.TimeFrame([1;2],[2,1]),'frames:SortedIndex:valueCheckFail');
            
            %from unique data
            t.verifyEqual(frames.DataFrame(1,[1 2]).data,[1;1])
            
            %from empty data
            t.verifyEqual(frames.DataFrame([],[1 2],1).data,[NaN;NaN])
            t.verifyEqual(frames.DataFrame([],[1 2]).data,double.empty(2,0))
            
            %from empty index
            t.verifyEqual(frames.DataFrame([1;2],[]).index,[1;2])
            
            % timeframe index
            t.verifyEqual(frames.TimeFrame(1,738316).index,datetime(2021,6,9))
            t.verifyEqual(frames.TimeFrame(1,"09-Jun-2021").index,datetime(2021,6,9))
            t.verifyEqual(frames.TimeFrame(1,frames.TimeIndex("09.06.2021",Format="dd.MM.yyyy")).index,datetime(2021,6,9))
            
            % from table
            tb = array2table([1 2; 3 4],RowNames=["r1","r2"],VariableNames=["a","b"]);
            t.verifyEqual(frames.DataFrame.fromTable(tb).columns,["a","b"])
            
            % from file
            pathfile = fullfile(t.dataPath,"f.txt");
            tf1 = frames.TimeFrame(1,frames.TimeIndex(string(2010:2015),format='yyyy'));
            tf1.toFile(pathfile);
            tf2 = frames.TimeFrame.fromFile(pathfile,timeFormat='yyyy');
            delete(pathfile)
            t.verifyEqual(tf1,tf2)
            
            pathfile = fullfile(t.dataPath,"g.txt");
            tf1 = frames.TimeFrame(1,738316);
            tf1.toFile(pathfile);
            tf2 = frames.TimeFrame.fromFile(pathfile);
            delete(pathfile)
            t.verifyEqual(tf1,tf2)
            
            pathfile = fullfile(t.dataPath,"h.txt");
            df1 = frames.DataFrame("x","h","H");
            df1.toFile(pathfile);
            df2 = frames.DataFrame.fromFile(pathfile);
            df3 = frames.DataFrame.fromFile(pathfile,'ReadVariableNames',false);
            delete(pathfile)
            t.verifyEqual(df1,df2)
            t.verifyEqual(df3,frames.DataFrame({'H','x'}',["Row","h"]))
            
            t.verifyEqual(frames.DataFrame.fromTable(table(1)),...
                frames.DataFrame(1));
            
            warning('off','frames:Index:notUnique')
            pathfile = fullfile(t.dataPath,"k.txt");
            tf1 = frames.TimeFrame(1,frames.TimeIndex([738316,738316],Unique=false),"a");
            tf1.toFile(pathfile);
            tf2 = frames.TimeFrame.fromFile(pathfile);
            tf3 = frames.TimeFrame.fromFile(pathfile,'ReadVariableNames',false);
            delete(pathfile)
            t.verifyEqual(tf1,tf2)
            t.verifyEqual(tf3,frames.TimeFrame(1,frames.TimeIndex([738316,738316],Unique=false)));
            warning('on','frames:Index:notUnique')
            
        end
        
        function subsasgnTest(t)
            df = frames.DataFrame([1 2 3 4 5 6; 2 5 NaN 1 3 2]');
            % test removal
            df{:,2} = [];
            df([1 3]) = [];
            df.iloc(4,:) = [];
            t.verifyEqual(df,frames.DataFrame([2 4 5]',[2 4 5]))
            % test loc iloc
            df.loc([2 5],:) = [22 55]';
            df.iloc(2,:) = 44;
            t.verifyEqual(df.data,[22 44 55]')
            df.iloc(2) = 43;
            t.verifyEqual(df.data,[22 43 55]')
            df.iloc(:,1) = 100;
            t.verifyEqual(df.data,[100 100 100]')
            % test (), {}
            df(2) = 20;
            t.verifyEqual(df.data,[20 100 100]')
            df{2:end,:} = 80;
            t.verifyEqual(df.data,[20 80 80]')
            df=frames.DataFrame([1 2 3; 2 5 NaN],[1 2], [11,22,33]);
            df(2,[22,33]) = 3.14;
            t.verifyEqual(df.data,[1 2 3; 2 3.14 3.14])
            
            % end in selection
            df=frames.DataFrame([1 2;3 4;5 6]);
            t.verifyEqual(df{end-1:end},df{end-1:end,:})
            t.verifyEqual(df{end-1:end},frames.DataFrame([3 4;5 6],[2 3]))

            % empty all keeps the index type
            tf=t.tfMissing1;
            tf{1:length(tf.index),:} = [];
            t.verifyEqual(tf.index,datetime.empty(0,1))
            
            % repeating columns
            warning('off','frames:Index:notUnique')
            df = frames.DataFrame([1 2 3; 2 5 NaN],[],["a","b","a"]);
            df(:,"a") = 100;
            expected = frames.DataFrame([100 2 100; 100 5 100],[],["a","b","a"]);
            t.verifyEqual(df,expected)
            warning('on','frames:Index:notUnique')
            
            % shuffled identifiers
            df = frames.DataFrame([1 2 3; 2 5 NaN],[1 2],[1 2 3]);
            df([2 1],[3 1 2]) = [1 2 3; 4 5 6];
            expected = frames.DataFrame([5 6 4; 2 3 1],[1 2],[1 2 3]);
            t.verifyEqual(df,expected)
            df{[2 1],[3 1 2]} = [10 20 30; 40 50 60];
            expected = frames.DataFrame([50 60 40; 20 30 10],[1 2],[1 2 3]);
            t.verifyEqual(df,expected)
            df = df.setIndexType('sorted');
            t.verifyError( @() f(df), 'frames:SortedIndex:valueCheckFail' )
            function f(x), x.loc([2 1], 2) = 20; end
            t.verifyError( @() fi(df), 'frames:SortedIndex:valueCheckFail' )
            function fi(x), x.loc{[2 1], 2} = 20; end
            
            % assign []
            df = frames.DataFrame([1 2 3; 2 5 NaN],[1 2],[1 2 3]);
            df1 = df; df2 = df;
            df1(1,:) = [];
            expected = frames.DataFrame([2 5 NaN],2,[1 2 3]);
            t.verifyEqual(df1,expected)
            df2{:,:} = [];
            expected = frames.DataFrame([],[],[1 2 3]);
            t.verifyEqual(df2,expected)
            
        end
        
        function subsasgnWithDFTest(t)
            df = frames.DataFrame([1 2;3 4],frames.Index([1 2]));
            dfbool = frames.DataFrame([false,true;true,false],[1 2]);
            seriesbool = frames.DataFrame([false,true]',[1 2]).asColSeries();
            series = frames.DataFrame([1 2]',[1 2],2).asColSeries(); %#ok<SETNU>
            dfother = frames.DataFrame([false,true;true,false],[2 3]);
            
            df{dfbool} = NaN;
            t.verifyEqual(df,frames.DataFrame([1 NaN;NaN 4],frames.Index([1 2])))
            df.iloc(dfbool) = 33;
            t.verifyEqual(df,frames.DataFrame([1 33;33 4],frames.Index([1 2])))
            
            df{seriesbool} = 10;
            t.verifyEqual(df,frames.DataFrame([1 33;10 10],frames.Index([1 2])))
            
            t.verifyError(@notSeries,'frames:elementWiseHandler:differentColumns')
            function notSeries, df.iloc(seriesbool.asColSeries(false)) = 0; end
            
            t.verifyError(@dfnotSeries,'frames:elementWiseHandler:differentColumns')
            function dfnotSeries, series{seriesbool.asColSeries(false)} = 0; end
            
            t.verifyError(@notAligned,'frames:elementWiseHandler:differentIndex')
            function notAligned, df{dfother} = 0; end
        end
        
        function subsrefTest(t)
            warning('off','frames:Index:notUnique')
            % repeating columns
            df = frames.DataFrame([1 2 3; 2 5 NaN],[],["a","b","a"]);
            sol = df(:,"a");
            expected = frames.DataFrame([1 3; 2 NaN],[],["a","a"]);
            t.verifyEqual(sol,expected)
            
            % simple selection
            sol = df(2,"b");
            expected = frames.DataFrame(5,2,"b");
            t.verifyEqual(sol,expected)
            
            % index only selection
            sol = df(2);
            expected = frames.DataFrame([2 5 NaN],2,["a","b","a"]);
            t.verifyEqual(sol,expected)
            
            % selection while repeating columns exist
            sol = df(1,["b","a"]);
            expected = frames.DataFrame([2 1 3],1,["b","a","a"]);
            t.verifyEqual(sol,expected)
            warning('on','frames:Index:notUnique')
            
            % test empty selection
            df = frames.DataFrame([1 2;3 4],[1,2],["a","b"]);
            t.verifyEqual(df{:,double.empty(1,0)},frames.DataFrame([],[1,2]))
            t.verifyEqual(df(double.empty(0,1),"b"),frames.DataFrame([],[],"b"))
            
            % sorted index
            t.verifyEqual(df(([2 1])),frames.DataFrame([3 4;1 2],[2 1],["a","b"]))
            df = df.setIndexType('sorted');
            t.verifyError(@() df([2 1]),'frames:SortedIndex:valueCheckFail')
            t.verifyError(@() df{[2 1]},'frames:SortedIndex:valueCheckFail')
        end
        
        function setIndexTest(t)
            df = frames.DataFrame([1 2 3 3 2 1; 2 5 NaN 1 3 2;5 0 4 1 3 2]');
            df = df.setIndex("Var3");
            expected = frames.DataFrame([1 2 3 3 2 1; 2 5 NaN 1 3 2]',[5 0 4 1 3 2]);
            t.verifyEqual(df,expected)
        end
        
        function indexSetterTest(t)
            df = frames.DataFrame([1 2; 2 5]);
            df.index = frames.Index([3 5],UniqueSorted=true);
            t.verifyEqual(df.index,[3 5]')
            
            t.verifyError(@idxNotSorted,'frames:SortedIndex:valueCheckFail')
            function idxNotSorted(), df.index=[6 3]; end
            
            t.verifyError(@wrongSize,'frames:indexValidation:wrongSize')
            function wrongSize(), df.index=3; end
            
            t.verifyError(@idxNotSorted2,'frames:Index:asgnNotSorted')
            function idxNotSorted2(), df.index(1)=33; end
            
            df.index = [3 6];
            t.verifyEqual(df.index,[3 6]')   
            
        end
        
        function indexAssignTest(t)
            dfs = frames.DataFrame(1,frames.Index([1 2 3 10 20],UniqueSorted=true));
            dfu = frames.DataFrame(1,frames.Index([1 2 3 10 20],Unique=true));
            warning('off','frames:Index:notUnique')
            dfd = frames.DataFrame(1,frames.Index([1 2 3 10 10],Unique=false));
            warning('on','frames:Index:notUnique')
            
            df1=dfs;
            df1.index([3,1]) = [4,0];
            t.verifyEqual(df1.index,[0 2 4 10 20]')
            t.verifyError(@notSorted,'frames:Index:asgnNotSorted')
            function notSorted, df1.index([1,3]) = [4,0]; end
            t.verifyError(@notSortedAll,'frames:SortedIndex:valueCheckFail')
            function notSortedAll, df1.index = [1 2 3 20 10]; end
            t.verifyError(@notSortedAll2,'frames:Index:asgnNotSorted')
            function notSortedAll2, df1.index(1:end) = [1 2 3 20 10]; end
            
            df2=dfu;
            df2.index([3,1]) = [0,4];
            t.verifyEqual(df2.index,[4 2 0 10 20]')
            t.verifyError(@notUnique,'frames:Index:asgnNotUnique')
            function notUnique, df2.index([3,1]) = [2,0]; end
            t.verifyError(@notUniqueAll,'frames:validators:mustBeDFindex')
            function notUniqueAll, df2.index = [1 2 3 20 20]; end
            t.verifyError(@notUniqueAll2,'frames:Index:asgnNotUnique')
            function notUniqueAll2, df1.index(1:end) = [1 2 3 20 20]; end
            
            df3=dfd;
            df3.index([3,1]) = [0,4];
            t.verifyEqual(df3.index,[4 2 0 10 10]')
            t.verifyWarning(@duplicate1,'frames:Index:asgnNotUnique')
            function duplicate1, df3.index([3,1]) = [2,0]; end
            t.verifyWarning(@duplicate2,'frames:Index:asgnNotUnique')
            function duplicate2, df3.index([3,1]) = [6,6]; end
            
            dfcs = frames.DataFrame(1,[],frames.Index([1 2 3 10 20],UniqueSorted=true));
            df4=dfcs;
            df4.columns([3,1]) = [4,0];
            t.verifyEqual(df4.columns,[0 2 4 10 20])
            t.verifyError(@notSortedCol,'frames:Index:asgnNotSorted')
            function notSortedCol, df4.columns([1,3]) = [4,0]; end
        end
        
        function columnsSetterTest(t)
            df = frames.DataFrame([1 2; 2 5]);
            
            t.verifyWarning(@colsNotUniqueWarning,'frames:Index:notUnique')
            function colsNotUniqueWarning(), df.columns=[6 6]; end
            
            df.columns = frames.Index([3 5],Unique=true);
            t.verifyEqual(df.columns,[3 5])
            
            t.verifyError(@colsNotUnique,'frames:UniqueIndex:valueCheckFail')
            function colsNotUnique(), df.columns=[6 6]; end
            
            t.verifyError(@wrongSize,'frames:columnsValidation:wrongSize')
            function wrongSize(), df.columns=3; end
            
            df.columns = [3 6];
            t.verifyEqual(df.columns,[3 6]) 
        end
        
        function dataSetterTest(t)
            df = frames.DataFrame([1 2; 2 5]);
            t.verifyError(@wrongSize,'frames:dataValidation:wrongSize')
            function wrongSize(), df.data=3; end
            
            df.data = [1 2;3 4];
            t.verifyEqual(df.data,[1 2;3 4]) 
        end
        
        function extendIndexTest(t)
            df = frames.DataFrame([1 1;2 2],[1 2]);
            ext = df.extendIndex([3 2 0]);
            t.verifyEqual(ext.data, [1 1;2 2;NaN NaN;NaN NaN]);
            t.verifyEqual(ext.index, [1 2 3 0]');
            
            df = df.setIndexType('sorted');
            ext = df.extendIndex([3 2 0]);
            t.verifyEqual(ext.data, [NaN NaN;1 1;2 2;NaN NaN]);
            t.verifyEqual(ext.index, [0 1 2 3]');
            
            t.verifyEqual(df.extendIndex([2 1 2]),df);
            
            warning('off','frames:Index:notUnique')
            dupli = frames.DataFrame([1 3 4 5]',frames.Index([1 3 4 5],Unique=false)).extendIndex([1 2 4]);
            warning('on','frames:Index:notUnique')
            t.verifyEqual(dupli.data, [1 3 4 5 NaN]');
            t.verifyEqual(dupli.index, [1 3 4 5 2]');
        end
        
        function dropIndexTest(t)
            df = frames.DataFrame([1 1;2 2;3 3;4 4],[1 2 3 4]);
            t.verifyEqual(df.dropIndex([2 3]).data, [1 1;4 4]);
        end
        
        function extendColumnsTest(t)
            df = frames.DataFrame([1 1;2 2]',[],[1 2]);
            t.verifyEqual(df.extendColumns([3 1]).data, [1 1;2 2;NaN NaN]');
            
            warning('off','frames:Index:notUnique')
            wDuplicates = frames.DataFrame([1 2 3 4 5 6],[],[1 3 1 4 5 4]).extendColumns([1 2 4 2]);
            t.verifyEqual(wDuplicates.data, [1 2 3 4 5 6 NaN NaN]);
            t.verifyEqual(wDuplicates.columns, [1 3 1 4 5 4 2 2]);
            warning('on','frames:Index:notUnique')
            sorted = frames.DataFrame([1 3 4 5],[],frames.Index([1 3 4 5],UniqueSorted=true)).extendColumns([1 2 4]);
            t.verifyEqual(sorted.data, [1 NaN 3 4 5]);
            t.verifyEqual(sorted.columns, [1 2 3 4 5]);
            uniq = frames.DataFrame([1 3 4 5],[],frames.Index([1 3 4 5],Unique=true)).extendColumns([1 2 4]);
            t.verifyEqual(uniq.data, [1 3 4 5 NaN]);
            t.verifyEqual(uniq.columns, [1 3 4 5 2]);
        end
        
        function dropColumnsTest(t)
            warning('off','frames:Index:notUnique')
            df = frames.DataFrame([1 1;2 2;3 3;4 4;5 5]',[],[1 2 4 2 5]);
            t.verifyEqual(df.dropColumns([2 5]).data, [1 1;3 3]');
            warning('on','frames:Index:notUnique')
        end
        
        function shiftTest(t)
            df = frames.DataFrame([1 1 3 1; NaN 1 NaN 1]');
            t.verifyEqual(df.shift().data, [NaN 1 1 3; NaN NaN 1 NaN]');
            t.verifyEqual(df.shift(-2).data, [3 1 NaN NaN; NaN 1 NaN NaN]');
        end
        
        function replaceStartByTest(t)
            df = frames.DataFrame([1 1 3 1; NaN 1 NaN 1;NaN 2 2 4]');
            t.verifyEqual(df.replaceStartBy(10).data, [10 10 3 1; 10 1 NaN 1;10 2 2 4]');
        end
        
        function emptyStart(t)
            df = frames.DataFrame([1 2 3 4; NaN NaN NaN 1;NaN 2 3 4]');
            t.verifyEqual(df.emptyStart(2).data, [NaN NaN 3 4; NaN NaN NaN NaN;NaN NaN NaN 4]');
        end
        
        function cumsumTest(t)
            df = frames.DataFrame([1 2 3 4; NaN 5 NaN 2;NaN NaN NaN NaN]');
            t.verifyEqual(df.cumsum().data, [1 3 6 10; NaN 5 NaN 7;NaN NaN NaN NaN]');
        end
        
        function cumprodTest(t)
            df = frames.DataFrame([1 2 3 4; NaN 5 NaN 2;NaN NaN NaN NaN]');
            t.verifyEqual(df.cumprod().data, [1 2 6 24; NaN 5 NaN 10;NaN NaN NaN NaN]');
        end
        
        function horzcatTest(t)
            solUnsorted = [frames.DataFrame([4 2;1 1],[1 3], [23 3]),frames.DataFrame([4 2;NaN 1],[1 2], [4 2])];
            expectedUnsorted = frames.DataFrame([4 2 4 2;1 1 NaN NaN;NaN NaN NaN 1],[1 3 2],[23 3 4 2]);
            t.verifyEqual(solUnsorted,expectedUnsorted)
            solSorted = [frames.DataFrame([4 2;1 1],frames.Index([1 3],UniqueSorted=true), [23 3]),frames.DataFrame([4 2;NaN 1],[1 2], [4 2])];
            expectedSorted = frames.DataFrame([4 2 4 2;NaN NaN NaN 1;1 1 NaN NaN],frames.Index([1 2 3],UniqueSorted=true),[23 3 4 2]);
            t.verifyEqual(solSorted,expectedSorted)
            
            % repeating
            a = frames.DataFrame(1,1,"a");
            b = frames.DataFrame([11 11;22 22],[1 3],["b1","b2"]);
            warning('off','frames:Index:notUnique')
            expected = frames.DataFrame([1 11 11 1; NaN 22 22 NaN],[1 3],["a","b1","b2","a"]);
            t.verifyEqual([a b a],expected)
            
            % disallow concatenation between different classes like [1,'1']
            c = b;
            c.data = char(c.data);
            t.verifyError(@() [b c],'frames:concat:differentDatatype');
            warning('on','frames:Index:notUnique')
        end
        
        function vertcatTest(t)
            sol = [frames.DataFrame([4 2;1 1],frames.Index([1 2],UniqueSorted=true),[23 3]);frames.DataFrame([4 2;1 1],[3 4],[3 44])];
            expected = frames.DataFrame([4 2 NaN;1 1 NaN;NaN 4 2;NaN 1 1],frames.Index([1 2 3 4],UniqueSorted=true),[23 3 44]);
            t.verifyEqual(sol,expected)
            
            % multiple concat with (un)sorted Frames
            a = frames.TimeFrame(1,1,1);
            b = frames.TimeFrame(2,[2 4],1);
            c = frames.TimeFrame(3,3,2);
            t.verifyEqual([a;c;b],frames.TimeFrame([1 2 NaN 2; NaN NaN 3 NaN]',[1 2 3 4],[1 2]))
            t.verifyError(@() [a;a], 'frames:vertcat:indexNotUnique')
            
            a = frames.DataFrame(1,1,1);
            b = frames.DataFrame(2,[2 4],1);
            c = frames.DataFrame(3,3,2);
            t.verifyEqual([a;c;b],frames.DataFrame([1 NaN 2 2; NaN 3 NaN NaN]',[1 3 2 4],[1 2]))
        end
        
        function vertcatIndexPropsTest(t)
            df = frames.DataFrame([1 2;3 4],[1 2],frames.Index([1 3],UniqueSorted=true));
            df2 = frames.DataFrame([30,20],3,[3 2]);
            
            t.verifyEqual([df;df2],frames.DataFrame([1 NaN 2;3 NaN 4;NaN 20 30],[1 2 3],frames.Index([1 2 3],UniqueSorted=true)))
            
        end
        
        function resampleTest(t)
            sortedframe = frames.DataFrame([4 1 NaN 3; 2 NaN 4 NaN]',[1 4 10 20]).setIndexType("sorted");
            ffi = sortedframe.resample([2 5],FirstValueFilling='ffillFromInterval');
            t.verifyEqual(ffi, frames.DataFrame([4 1; 2 NaN]',[2 5]).setIndexType("sorted"));
            ffi1 = sortedframe.resample([3 11],FirstValueFilling={'ffillFromInterval',1});
            t.verifyEqual(ffi1, frames.DataFrame([NaN 1; NaN 4]',[3 11]).setIndexType("sorted"));
            ffla = sortedframe.resample([13 14 15],FirstValueFilling='ffillLastAvailable');
            t.verifyEqual(ffla, frames.DataFrame([1 NaN NaN;4 NaN NaN]',[13 14 15]).setIndexType("sorted"));
            noff = sortedframe.resample([13 14 15],FirstValueFilling='noFfill');
            t.verifyEqual(noff, frames.DataFrame([NaN NaN NaN;NaN NaN NaN]',[13 14 15]).setIndexType("sorted"));
            noff2 = sortedframe.resample([4 14 15],FirstValueFilling='noFfill');
            t.verifyEqual(noff2, frames.DataFrame([1 NaN NaN;NaN 4 NaN]',[4 14 15]).setIndexType("sorted"));
        end
        
        function sortByTest(t)
            sol = frames.DataFrame([1 2 3; 2 5 3]',[1 3 65],[4 3]).setIndexType("sorted").sortBy(3);
            t.verifyEqual(sol,frames.DataFrame([1 3 2;2 3 5]',[1 65 3],[4 3]))
        end
        
        function sortIndexTest(t)
            sol = frames.DataFrame([1 2 3; 2 5 3]', frames.Index([2 6 1],Unique=true,Name="Row")).sortIndex();
            t.verifyEqual(sol,frames.DataFrame([3 1 2;3 2 5]',[1 2 6]))
        end
        
        function splitapplyTest(t)
            % simple split with cell
            df=frames.DataFrame([1 2 3;2 5 3;5 0 1]', [6 2 1], [4 1 3]);
            x1 = df.split({[4,3],1},["d","e"]).apply(@(x) x);
            t.verifyEqual(x1,frames.DataFrame([1 2 3;5 0 1;2 5 3]',[6 2 1],[4 3 1]))
            % apply function using group names
            ceiler.d = {2.5,4.5};
            ceiler.e = {2.6};
            x2 = df.split({[4,3],1},["d","e"]).apply(@(x) x.clip(ceiler.(x.name){:}));
            % split with structure
            s.d = [4 3]; s.e = 1;
            x3 = df.split(s,["d","e"]).apply(@(x) x.clip(ceiler.(x.name){:}));
            % split with a Group
            g = frames.Groups([1 4 3],s);
            x4 = df.split(g,["d","e"]).apply(@(x) x.clip(ceiler.(x.name){:}));
            expected = frames.DataFrame([2.5 2.5 3;4.5 2.5 2.5;2 2.6 2.6]',[6,2,1],[4 3 1]);
            t.verifyEqual(x2,expected)
            t.verifyEqual(x3,expected)
            t.verifyEqual(x4,expected)
            x5 = df.split(g,["d","e"]).apply(@(x) x.sum(2));
            t.verifyEqual(x5,frames.DataFrame([6 2 4;2 5 3]',[6 2 1],["d","e"]))
        end
        
        function firstIndexTest(t)
            df = frames.DataFrame([ NaN 2 3 4 NaN 6;NaN NaN NaN 1 NaN 1;NaN NaN 33 44 55 66]');
            t.verifyEqual(df.firstCommonIndex(),4)
            t.verifyEqual(df.firstValidIndex(),2)
            noCommon = frames.DataFrame([4 NaN 6;NaN 55 NaN]',string([1 2 3])).firstCommonIndex();
            t.verifyEqual(noCommon,string.empty(0,1));
        end
        
        function relChangeTest(t)
            dfp = frames.DataFrame([1 NaN 3; NaN 2 3;5 1 NaN]');
            exp = frames.DataFrame([NaN 1 3; NaN 2 3;5 1 NaN]');
            t.verifyEqual(dfp.relChg('log').compoundChange('log',[1 2 5]).data,exp.data,'AbsTol',t.tol)
            t.verifyEqual(dfp.relChg().compoundChange('simple',[1 2 5]).data,exp.data,'AbsTol',t.tol)
            df2 = frames.DataFrame([1 2]');
            t.verifyEqual(df2.relChg('log').data,[NaN log(2)]')
            t.verifyEqual(df2.relChg().data,[NaN 1]')
            
            % test other arguments
            tf = frames.TimeFrame([1 1 NaN 2]');
            t.verifyEqual(tf.relChg(),frames.TimeFrame([NaN 0 NaN 1]'));
            t.verifyEqual(tf.relChg('simple',2),frames.TimeFrame([NaN NaN NaN 1]'));
            t.verifyEqual(tf.relChg('simple',2,false),frames.TimeFrame([NaN 1]',[2 4]));
        end
        
        function mathOperationsTest(t)
            mat1 = frames.DataFrame([1 2;3 4]);
            mat2 = frames.DataFrame([10 20;30 40],[],["a","b"]);
            vecV = frames.DataFrame([6 7]',ColSeries=true);
            vecV2 = frames.DataFrame([6 7]',[],"a",ColSeries=true);
            vecH = frames.DataFrame([6 7]',ColSeries=true);
            tf = frames.TimeFrame([738331:738336;1:6]',738331:738336);
            
            tfOp = tf' * tf;
            t.verifyEqual(tfOp,frames.DataFrame(tf.data'*tf.data,tf.columns,tf.columns))
            mtimesM = mat1' * mat2;
            t.verifyEqual(mtimesM,frames.DataFrame([100 140;140 200],mat1.columns,mat2.columns))
            mtimesV = mat1' * vecV2;
            t.verifyEqual(mtimesV,frames.DataFrame([27;40],mat1.columns,vecV2.columns,ColSeries=true))
            times = mat1 .* vecV;
            t.verifyEqual(times,frames.DataFrame([6 12;21 28],mat1.index,mat1.columns))
            plus1 = mat1 + vecH;
            t.verifyEqual(plus1,frames.DataFrame([7 8;10 11],mat1.index,mat1.columns))
            plus2 = vecH + mat1;
            t.verifyEqual(plus2,frames.DataFrame([7 8;10 11],mat1.index,mat1.columns))
            plusSeries = vecV2 + vecV;
            t.verifyEqual(plusSeries,frames.DataFrame([12;14],vecV2.index,vecV2.columns,ColSeries=true))
            t.verifyError(@notAligned,'frames:matrixOpHandler:notAligned')
            function notAligned(), mat1*mat2; end %#ok<VUNUS>
            t.verifyError(@notSameColumns,'frames:elementWiseHandler:differentColumns')
            function notSameColumns(), mat1-mat2; end %#ok<VUNUS>
            
            t.verifyError(@seriesError,'frames:elementWiseHandler:differentIndex')
            function seriesError(), mat1.*mat1(1); end %#ok<VUNUS>
            loc = mat1 .* mat1(1).asRowSeries();
            t.verifyEqual(loc,frames.DataFrame([1 4;3 8],mat1.index,mat1.columns))
            summing = mat1 .* mat1.sum();
            t.verifyEqual(summing,frames.DataFrame([4 12;12 24],mat1.index,mat1.columns))
            iloc = -mat1 - mat1{:,1}.asColSeries();
            t.verifyEqual(iloc,frames.DataFrame([-2 -3;-6 -7],mat1.index,mat1.columns))

            % with arrays
            df = frames.DataFrame([1 2;3 4],["a" "b"],["one" "two"]);
            two = frames.DataFrame(2,ColSeries=true,RowSeries=true);
            t.verifyEqual(df*2,frames.DataFrame(2*[1 2;3 4],["a" "b"],["one" "two"]))
            t.verifyEqual(2*df,df*2)
            t.verifyEqual(2*df,two.*df)
            t.verifyError(@() two*df,'frames:matrixOpHandler:notAligned')
            t.verifyEqual([1 2]*df,frames.DataFrame([7 10],1,df.columns))
            t.verifyEqual(df*[1;2],frames.DataFrame([5;11],df.index))
            
            % element-wise with a 1x1
            oneone = frames.DataFrame(2);
            oneoneSeries = oneone.asRowSeries().asColSeries();
            matr = frames.DataFrame([1 2; 3 4],[],[2 3]);
            t.verifyEqual(oneoneSeries.*matr,matr.*oneoneSeries)
            t.verifyError(@cantMatOp,'frames:matrixOpHandler:notAligned')
            function cantMatOp(), oneoneSeries*matr; end %#ok<VUNUS>
            
            % col mtimes row
            res = frames.DataFrame([1 2 3]',2:4,"u")*frames.DataFrame([1 2 3],"u",["a" "b" "c"]);
            t.verifyEqual(res.index,(2:4)')
            t.verifyEqual(res.columns,["a" "b" "c"])
        end
        
        function mathOperationsMiscellaneousTest(t)
            df = t.dfMissing1;
            t.verifyEqual(df./df,df./df.data)
            div = 1./df;
            t.verifyEqual(div.data,1./df.data)
            t.verifyEqual(df/2,df./2)
            t.verifyEqual(df+1,1+df)
            t.verifyEqual(df-1,-(1-df))
            
            b = df{1,:}';
            expectedData = df.data * b.data;
            expected = frames.DataFrame(expectedData,df.index,b.columns);
            t.verifyEqual(df*b,expected)
        end
        
        function mat2seriesTest(t)
            df = frames.DataFrame([1:6;11:16;21:26]);
            df.data(8) = NaN;
            t.verifyEqual(df.mean(),df.mean(1))
            t.verifyEqual(df.mean().data,mean(df.data,'omitnan'))
            t.verifyEqual(df.mean(2).data,mean(df.data,2,'omitnan'))
            
            t.verifyEqual(df.std(),df.std(1))
            t.verifyEqual(df.std().data,std(df.data,'omitnan'))
            t.verifyEqual(df.std(2).data,std(df.data,[],2,'omitnan'))
        end
        
        function equalsTest(t)
            df=frames.DataFrame([1 2;3 4]);
            df2=frames.DataFrame([1 2;3 4])+0.5;
            t.verifyTrue(df.equals(df2,1))
            t.verifyFalse(df.equals(df2))
        end
        
        function eqTest(t)
            df=frames.DataFrame([1 2;1 2]);
            df2=frames.DataFrame([1 2]);
            series=df2.asRowSeries();
            t.verifyEqual(df==series,frames.DataFrame([true true;true true]))
            t.verifyError(@()df==df2,'frames:elementWiseHandler:differentIndex')
        end
        
        function anyTest(t)
            df=frames.DataFrame([false true; false false]);
            t.verifyEqual(df.any(1),frames.DataFrame([false true],RowSeries=true));
            t.verifyEqual(df.any(1).any(2),true);
            t.verifyEqual(df.all(2),frames.DataFrame([false false]',ColSeries=true));
        end
        
        function selectFromTimeRangeTest(t)
            tf = frames.TimeFrame(1,738318:738318+10); % 11 June 2021 to 21 June 2021
            sel1 = tf("09.06.2021:14.06.2021:dd.MM.yyyy");
            tr = timerange("09-Jun-2021","14-Jun-2021",'closed');
            sel2 = tf(tr);
            sel3 = tf("-inf:14-Jun-2021");
            sel4 = tf({-inf,datetime("14.06.2021",Format='dd.MM.yyyy')});
            sel5 = tf({"11-Jun-2021","14-Jun-2021"}); %#ok<CLARRSTR>
            sel6 = tf(738318:738318+3);
            expected = frames.TimeFrame(1,738318:738318+3);  % 11 June 2021 to 14 June 2021
            t.verifyEqual(sel1,expected)
            t.verifyEqual(sel2,expected)
            t.verifyEqual(sel3,expected)
            t.verifyEqual(sel4,expected)
            t.verifyEqual(sel5,expected)
            t.verifyEqual(sel6,expected)
            
            selSpecific = tf(["11-Jun-2021","14-Jun-2021"]);
            expectedSpecific = frames.TimeFrame(1,[738318,738318+3]);  % 11 June 2021 and 14 June 2021
            t.verifyEqual(selSpecific,expectedSpecific)
            
            % not possible to turn it into a timerange (use [] to get specific observations)
            t.verifyError(@() tf({"11-Jun-2021","12-Jun-2021","14-Jun-2021"}),'MATLAB:datetime:InvalidData') %#ok<CLARRSTR>
        end
        
        function matrix2seriesTest(t)
            tf = t.tfMissing1;
            t.verifyEqual(tf.sum(),frames.DataFrame([12 13 12],[],tf.columns,RowSeries=true))
            t.verifyEqual(tf.sum(2),frames.TimeFrame([8 7 4 5 8 5]',tf.getIndex_(),[],ColSeries=true))
            t.verifyEqual(tf.sum().sum(2),37)
        end
        
        function maxminTest(t)
            df = frames.DataFrame([4 NaN;3 1]);
            t.verifyEqual(df.maxOf(3).data,[4 3;3 3])
            t.verifyEqual(df.maxOf(df+1),df+1)
            t.verifyEqual(df.max().min(2).columns,"Var2")
            t.verifyEqual(df.max(2).min().index,2)
            df2 = df;
            df2.index(end) = 7;
            t.verifyError(@misaligned,'frames:elementWiseHandler:differentIndex')
            function misaligned(), df.maxOf(df2); end
        end
        
        function nansumTest(t)
            df1 = frames.DataFrame([1 NaN;NaN 4]);
            df2 = frames.DataFrame([1 2;NaN 4]);
            df3 = frames.DataFrame([1 2;NaN 4],[2 3]);
            t.verifyEqual(df1.nansum(df1,df1),3.*df1)
            t.verifyEqual(df1.nansum(df2),frames.DataFrame([2 2;NaN 8]))
            t.verifyEqual(df1.nansum(df2.data),frames.DataFrame([2 2;NaN 8]))
            
            t.verifyError(@()df1.nansum(2),'frames:nansum:differentSize')
            t.verifyError(@()df1.nansum(df3),'frames:nansum:notAligned')
        end
        
        function covcorrTest(t)
            df = t.dfMissing1;
            cor = df.corr();
            cov = df.cov();
            t.verifyEqual(cor.index,cov.columns')
        end
        
        function dropMissingTest(t)
            df = frames.DataFrame([NaN NaN; NaN 1],string([1 2]),{'a','b'});
            dany = df.dropMissing(How='any');
            t.verifyEqual(dany,frames.DataFrame(double.empty(0,2),string.empty(0,1),{'a','b'}));
            dall = df.dropMissing(How='all');
            t.verifyEqual(dall,frames.DataFrame([NaN 1],string(2),{'a','b'}));
            dall2 = df.dropMissing(How='all',Axis=2);
            t.verifyEqual(dall2,frames.DataFrame([NaN 1]',string([1 2]),{'b'}));
            dfstring = df;
            dfstring.data = string(df.data);
            dall2string = dfstring.dropMissing(How='all',Axis=2);
            t.verifyEqual(dall2string,frames.DataFrame(string([NaN 1]'),string([1 2]),{'b'}));
        end
        
        function rollingEwmTest(t)
            df = frames.DataFrame([1 2 3 3 2 1;2 5 NaN 1 3 2;5 0 1 1 3 2]');
            t.verifyEqual(df.rolling(4).sum().data,[NaN NaN 6 9 10 9;NaN NaN NaN 8 9 6;NaN NaN 6 7 5 7]');
            
            covdf = df.rolling(6).cov(df{:,3});
            covVal = cov(df.data(:,[2,3]),'partialrows');
            t.verifyEqual(covdf.data(end,2),covVal(1,2),AbsTol=t.tol)
            
            cordf = df.rolling(6).corr(df{:,2});
            corVal = corrcoef(df.data(:,[2,3]),Rows='pairwise');
            t.verifyEqual(cordf.data(end,3),corVal(1,2),AbsTol=t.tol)
            
            beta23 = cov(df.dropMissing(How='any').data(2:end,[2,3]),'partialrows') ./ var(df.dropMissing(How='any').data(2:end,[2,3]));
            beta2y = df{:,2}.rolling(5).betaXY(df);
            beta3y = df{:,3}.rolling(5).betaXY(df);
            betax3 = df.rolling(5).betaXY(df{:,3});
            
            t.verifyEqual(beta2y.data(end,3),beta23(2,1),AbsTol=t.tol)
            t.verifyEqual(beta3y.data(end,2),beta23(1,2),AbsTol=t.tol)
            t.verifyEqual(betax3.data(end,2),beta23(2,1),AbsTol=t.tol)
            
            t.verifyEqual(df.ewm(Alpha=0.3).var().data(1,:),[NaN NaN NaN])
            t.verifyEqual(df.ewm(Alpha=0.3).mean().data,df.ewm(Window=2/0.3-1).mean().data,AbsTol=t.tol)
        end
        
    end
end
