classdef seriesTest < AbstractFramesTests
    
    properties
        df = frames.DataFrame([1 2;3 4]);
        colseries = frames.DataFrame([1;3],ColSeries=true);
        noSeries = frames.DataFrame([1;3]);
        rowseries = frames.DataFrame([1 2],RowSeries=true);
        useries = frames.DataFrame(1,RowSeries=true,ColSeries=true);
    end
    
    methods(Test)
        function propertyTest(t)
            t.verifyTrue(t.colseries.colseries)
            t.verifyFalse(t.colseries.rowseries)
            t.verifyTrue(t.colseries.getColumnsObj().singleton)
            t.verifyFalse(t.noSeries.colseries)
            t.verifyTrue(t.rowseries.rowseries)
            t.verifyFalse(t.rowseries.getColumnsObj().singleton)
            t.verifyTrue(t.useries.rowseries)
            t.verifyTrue(t.useries.getRowsObj().singleton)
            t.verifyTrue(t.useries.getColumnsObj().singleton)
        end
        function operationTest(t)
            plusV = t.df + t.colseries;
            t.verifyEqual(plusV.data,[2 3;6 7])
            t.verifyError(@() t.df+t.noSeries,'frames:elementWiseHandler:differentColumns')
            plusH = t.df + t.rowseries;
            t.verifyEqual(plusH.data,[2 4;4 6])
            plusU = t.df + t.useries;
            t.verifyEqual(plusU.data,[2 3;4 5])
        end
        function locTest(t)
            t.verifyFalse(t.df(1,:).rowseries)
            t.verifyFalse(t.df{:,2}.colseries)
            t.verifyFalse(t.df{:,:}.rowseries)
            t.verifyFalse(t.df{:,:}.colseries)
        end
        
        function indexTest(t)
            idx1 = frames.Index([1,2,3],UniqueSorted=true);
            idx2 = frames.Index(NaN,Unique=true,Singleton=true);
            
            t.verifyError(@notUnique,'frames:Index:setSingleton')
            function notUnique(), idx1.singleton=true; end
            t.verifyFalse(idx2.union(idx1).singleton)
            
            idx3 = frames.Index(4,Unique=true);
            idx3.singleton = true;
            t.verifyTrue(idx3.singleton)
        end
        function assignTest(t)
            t.verifyError(@frameFailProp,'frames:Index:setSingleton')
            function frameFailProp(), t.df.colseries = true; end
            t.verifyError(@frameFailFun,'frames:Index:setSingleton')
            function frameFailFun(), t.df.asColSeries(); end
            t.verifyEqual(t.df.asColSeries(false).colseries,false)
            t.verifyEqual(t.colseries.asColSeries(false).colseries,false)
            t.noSeries = frames.DataFrame([1;3]);
            t.verifyEqual(t.noSeries.asColSeries(true).colseries,true)
            
            % limit case empty
            t.verifyEqual(frames.DataFrame([],[],1).asColSeries().columns,NaN)
            t.verifyError(@() frames.DataFrame([],[],1).asRowSeries(),'frames:Index:setSingleton')
        end
        
        function testOperation(t)
            t.verifyEqual(t.df-t.df.iloc(1).asRowSeries(),frames.DataFrame([0 0;2 2]))
            t.verifyError(@() t.df-t.df.iloc(1),'frames:elementWiseHandler:differentRows')
        end
    end
end
