classdef dataframeTest < matlab.unittest.TestCase
    
    properties
        dfNoMissing = frames.DataFrame([1 2 3; 2 5 3;5 1 1]', [6 2 1], [4 1 3]);
        dfMissing1 = frames.DataFrame([1 2 3 3 2 1; 2 5 NaN 1 3 2;5 0 1 1 3 2]');
        tfMissing1 = frames.TimeFrame([1 2 3 3 2 1; 2 5 NaN 1 3 2;5 0 1 1 3 2]',[],["a","b","c"]);
        dataPath = "+frames\+unitTests\"
        tol = 1e-10;
    end
    
    methods(Test)
        
        function constructorTest(t)
            
            % empty
            emptyTT = frames.TimeFrame();
            t.verifyTrue(isempty(emptyTT.data)&&isempty(emptyTT.index)&&isempty(emptyTT.columns))
            t.verifyTrue(isdatetime(emptyTT.index_.value))
            t.verifyTrue(isa(emptyTT.index_,'frames.TimeIndex'))
            
            emptyDF = frames.DataFrame.empty("datetime");
            t.verifyTrue(isdatetime(emptyDF.index))
            t.verifyTrue(isa(emptyDF.index_,'frames.Index'))
            
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
            pathfile = t.dataPath+"f.txt";
            tf1 = frames.TimeFrame(1,frames.TimeIndex(string(2010:2015),format='yyyy'));
            tf1.toFile(pathfile);
            tf2 = frames.TimeFrame.fromFile(pathfile,timeFormat='yyyy');
            delete(pathfile)
            t.verifyEqual(tf1,tf2)
            
            pathfile = t.dataPath+"g.txt";
            tf1 = frames.TimeFrame(1,738316);
            tf1.toFile(pathfile);
            tf2 = frames.TimeFrame.fromFile(pathfile);
            delete(pathfile)
            t.verifyEqual(tf1,tf2)
            
            pathfile = t.dataPath+"h.txt";
            df1 = frames.DataFrame(1,string(1));
            df1.toFile(pathfile);
            df2 = frames.DataFrame.fromFile(pathfile);
            delete(pathfile)
            t.verifyEqual(df1,df2)
        end
        
        function subsasgnTest(t)
            df=frames.DataFrame([1 2 3 4 5 6; 2 5 NaN 1 3 2]');
            % test removal
            df{:,2} = [];
            df([1 3],:) = [];
            df.iloc(4,:) = [];
            t.verifyEqual(df,frames.DataFrame([2 4 5]',[2 4 5]))
            % test loc iloc
            df.loc([2 5],:) = [22 55]';
            df.iloc(2,:) = 44;
            t.verifyEqual(df.data,[22 44 55]')
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
            
            % empty all keeps the index type
            tf=t.tfMissing1;
            tf{1:length(tf.index),:} = [];
            t.verifyEqual(tf.index,datetime.empty(0,1))
        end
        
        function setIndexTest(t)
            df=frames.DataFrame([1 2 3 3 2 1; 2 5 NaN 1 3 2;5 0 4 1 3 2]');
            df = df.setIndex("Var3");
            expected = frames.DataFrame([1 2 3 3 2 1; 2 5 NaN 1 3 2]',[5 0 4 1 3 2]);
            t.verifyEqual(df,expected)
        end
        
        function horzcatTest(t)
            solUnsorted = [frames.DataFrame([4 2;1 1],[1 3], [23 3]),frames.DataFrame([4 2;NaN 1],[1 2], [4 2])];
            expectedUnsorted = frames.DataFrame([4 2 4 2;1 1 NaN NaN;NaN NaN NaN 1],[1 3 2],[23 3 4 2]);
            t.verifyEqual(solUnsorted,expectedUnsorted)
            solSorted = [frames.DataFrame([4 2;1 1],frames.SortedIndex([1 3]), [23 3]),frames.DataFrame([4 2;NaN 1],[1 2], [4 2])];
            expectedSorted = frames.DataFrame([4 2 4 2;NaN NaN NaN 1;1 1 NaN NaN],frames.SortedIndex([1 2 3]),[23 3 4 2]);
            t.verifyEqual(solSorted,expectedSorted)
        end
        
        function vertcatTest(t)
            sol = [frames.DataFrame([4 2;1 1],frames.SortedIndex([1 2]),[23 3]);frames.DataFrame([4 2;1 1],[3 4],[3 44])];
            expected = frames.DataFrame([4 2 NaN;1 1 NaN;NaN 4 2;NaN 1 1],frames.SortedIndex([1 2 3 4]),[23 3 44]);
            t.verifyEqual(sol,expected)
            t.verifyError(@f,'SortedIndex:valueCheckFail')
            function f()
                [frames.DataFrame([4 2;1 1],frames.SortedIndex([1 2]),[23 3]);frames.DataFrame([4 2;1 1],[4 3],[3 44])]; %#ok<VUNUS>
            end
        end
        
        function resampleTest(t)
            sortedframe = frames.DataFrame([4 1 NaN 3; 2 NaN 4 NaN]',[1 4 10 20]).setIndexType("sorted");
            ffi = sortedframe.resample([2 5],firstValueFilling='ffillFromInterval');
            t.verifyEqual(ffi, frames.DataFrame([4 1; 2 NaN]',[2 5]).setIndexType("sorted"));
            ffi1 = sortedframe.resample([3 11],firstValueFilling={'ffillFromInterval',1});
            t.verifyEqual(ffi1, frames.DataFrame([NaN 1; NaN 4]',[3 11]).setIndexType("sorted"));
            ffla = sortedframe.resample([13 14 15],firstValueFilling='ffillLastAvailable');
            t.verifyEqual(ffla, frames.DataFrame([1 NaN NaN;4 NaN NaN]',[13 14 15]).setIndexType("sorted"));
            noff = sortedframe.resample([13 14 15],firstValueFilling='noFfill');
            t.verifyEqual(noff, frames.DataFrame([NaN NaN NaN;NaN NaN NaN]',[13 14 15]).setIndexType("sorted"));
            noff2 = sortedframe.resample([4 14 15],firstValueFilling='noFfill');
            t.verifyEqual(noff2, frames.DataFrame([1 NaN NaN;NaN 4 NaN]',[4 14 15]).setIndexType("sorted"));
        end
        
        function sortByTest(t)
            frames.DataFrame([1 2 3; 2 5 3]', frames.TimeIndex([1 3 65]), [4 1]).sortBy(1)
            
        end
        
        function sortIndexTest(t)
            frames.DataFrame([1 2 3; 2 5 3]', frames.UniqueIndex([6 2 1]), [4 1]).sortIndex()
            
        end
        
        function splitapplyTest(t)
            df=frames.DataFrame([1 2 3; 2 5 3;5 0 1]', [6 2 1], [4 1 3])
            df.split({[4,3],1},["d","e"]).apply(@(x) x)
            ceiler.d = {2.5,4.5};
            ceiler.e = {2.6};
            df.split({[4,3],1},["d","e"]).apply(@(x) x.clip(ceiler.(x.name){:}))
            s.d = [4 3]; s.e = 1;
            df.split(s,["d","e"]).apply(@(x) x.clip(ceiler.(x.name){:}))
            g = frames.Groups([1 3 4], s)
            df.split(g,["d","e"]).apply(@(x) x.clip(ceiler.(x.name){:}))
        end
        
        function firstIndexTest(t)
            df = frames.DataFrame([ NaN 2 3 4 NaN 6;NaN NaN NaN 1 NaN 1 ; NaN NaN 33 44 55 66]');
            df.firstCommonIndex()
            df.firstValidIndex()
        end
        
        function relChangeTest(t)
            df=frames.DataFrame([1 2 3; 2 5 3;5 1 1]', [6 2 1], [4 1 3])
            df.relChg('log').compoundChange('log',[1 2 5])
            df.relChg().compoundChange('simple',[1 2 5])
        end
        
        function mathOperationsTest(t)
            df = t.dfNoMissing;
            df' * df
            df + df
            df + df.data
            1 + df
            df.data' * df
            df' \ df
        end
        
        function selectFromTimeRangeTest(t)
            a = datetime(1:10,'ConvertFrom','datenum')
            b=timerange('02.01.0000','03.01.0000')
            frames.TimeIndex(a).positionOf(a(3:end))
            frames.TimeIndex(a).positionOf('02-Jan-0000:03-Jan-0000:dd-MMM-uuuu')
            
            tf=frames.TimeFrame(1,1:10,[])
            tf('02.01.0000:04.01.0000:dd.MM.uuuu')
            
        end
        
        function matrix2seriesTest(t)
            df = t.dfNoMissing;
            df.std(2)
            df.sum()
            
        end
        
        function maxminTest(t)
            df = t.dfNoMissing;
            df.maxOf(3)
            df.maxOf(df+1)
            df.max(2).min()
        end
        
        function covcorrTest(t)
            df = t.dfNoMissing;
            df.corr()
            df.cov()
        end
        
        function dropMissingTest(t)
            t.dfMissing1.dropMissing(How='any')
            
        end
        
        function rollingEwmTest(t)
            
            df=frames.DataFrame([1 2 3 3 2 1; 2 5 NaN 1 3 2;5 0 1 1 3 2]')
            df.rolling(2).sum()
            
            df{:,[1,2]}.rolling(6).cov(df{:,3})
            cov(df.data(:,[2,3]),'partialrows')
            
            df{:,[1,3]}.rolling(6).corr(df{:,2})
            corrcoef(df.data(:,[2,3]),Rows='pairwise')
            
            cov(df.dropMissing(How='any').data(:,[2,3]),'partialrows') ./ var(df.dropMissing(How='any').data(:,[2,3]))
            df{:,2}.rolling(6).betaXY(df{:,[1,3]})
            df{:,3}.rolling(6).betaXY(df{:,[1,2]})
            df{:,[1,2]}.rolling(6).betaXY(df{:,3})
            
            df.rolling(6).cov(df{:,2})
            df.rolling(6).corr(df{:,2})
            
            df.rolling(6).betaXY(df{:,3})
            df.rolling(6).betaXY(df{:,3})
            df{:,3}.rolling(6).betaXY(df)
            
            df.ewm(Alpha=0.3).var()
            df.ewm(Alpha=0.3).mean()
            df.ewm(Window=2/0.3-1).mean()
        end
        
    end
end