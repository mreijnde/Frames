classdef alignTest < matlab.unittest.TestCase
    
    properties

    end
    
    methods(Test)
        function basicTest(t)
            df1 = frames.DataFrame([10 50 100 150]',[1 5 10 15]).setIndexType('sorted');
            df2 = frames.DataFrame([20 50 90 150]',[2 5 9 15]).setIndexType('sorted');
            [df1a,df2a] = frames.align(df1,df2);
            t.verifyEqual(df1a.data,[10 NaN 50 NaN 100 150]');
            t.verifyEqual(df1a.index,[1 2 5 9 10 15]');
            t.verifyEqual(df2a.data,[NaN 20 50 90 NaN 150]');
            t.verifyEqual(df2a.index,[1 2 5 9 10 15]');
            
            df1aSingleOutput = frames.align(df1,df2,df1,df1,df2);
            t.verifyEqual(df1a,df1aSingleOutput);
        end
        
    end
end