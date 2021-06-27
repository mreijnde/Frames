classdef seriesTest < matlab.unittest.TestCase
    
    properties
        df = frames.DataFrame([1 2;3 4]);
        series = frames.DataFrame([1;3],Series=true);
        noSeries = frames.DataFrame([1;3]);
        hseries = frames.DataFrame([1 2],Series=true);
        useries = frames.DataFrame(1,Series=true);
    end
    
    methods(Test)
        function propertyTest(t)
            t.verifyTrue(t.series.series)
            t.verifyTrue(t.series.getColumns_().singleton)
            t.verifyFalse(t.noSeries.series)
            t.verifyTrue(t.hseries.series)
            t.verifyFalse(t.hseries.getColumns_().singleton)
            t.verifyTrue(t.useries.series)
            t.verifyTrue(t.useries.getIndex_().singleton)
            t.verifyTrue(t.useries.getColumns_().singleton)
        end
        function operationTest(t)
            plusV = t.df + t.series;
            t.verifyEqual(plusV.data,[2 3;6 7])
            t.verifyError(@() t.df+t.noSeries,'frames:elementWiseHandler:differentColumns')
            plusH = t.df + t.hseries;
            t.verifyEqual(plusH.data,[2 4;4 6])
            plusU = t.df + t.useries;
            t.verifyEqual(plusU.data,[2 3;4 5])
        end
        function locTest(t)
            t.verifyTrue(t.df(1,:).series)
            t.verifyTrue(t.df{:,2}.series)
            t.verifyFalse(t.df{:,:}.series)
        end
        
        function indexTest(t)
            idx1 = frames.SortedIndex([1,2,3]);
            idx2 = frames.UniqueIndex(4,Singleton=true);
            
            t.verifyError(@notUnique,'frames:Index:setSingleton')
            function notUnique(), idx1.singleton=true; end
            t.verifyFalse(idx2.union(idx1).singleton)
            
            idx3 = frames.UniqueIndex(4);
            idx3.singleton = true;
            t.verifyTrue(idx3.singleton)
        end
    end
end