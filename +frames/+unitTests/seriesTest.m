classdef seriesTest < matlab.unittest.TestCase
    
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
            t.verifyTrue(t.colseries.getColumns_().singleton)
            t.verifyFalse(t.noSeries.colseries)
            t.verifyTrue(t.rowseries.rowseries)
            t.verifyFalse(t.rowseries.getColumns_().singleton)
            t.verifyTrue(t.useries.rowseries)
            t.verifyTrue(t.useries.getIndex_().singleton)
            t.verifyTrue(t.useries.getColumns_().singleton)
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
            t.verifyTrue(t.df(1,:).rowseries)
            t.verifyTrue(t.df{:,2}.colseries)
            t.verifyFalse(t.df{:,:}.rowseries)
            t.verifyFalse(t.df{:,:}.colseries)
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