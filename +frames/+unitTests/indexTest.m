classdef indexTest < matlab.unittest.TestCase
    
    methods(Test)
        function constructorTest(t)
            t.verifyWarning(@duplicate,'frames:Index:notUnique')
            function duplicate(), frames.Index([2 2]); end
            
            t.verifyError(@badsorted,'frames:SortedIndex:valueCheckFail')
            function badsorted(), frames.SortedIndex([3 2]); end
            
            t.verifyError(@duplicateError,'frames:UniqueIndex:valueCheckFail')
            function duplicateError(), frames.UniqueIndex([2 2]); end
            
            timeindex = frames.TimeIndex("24*06*2021",Format="dd*MM*yyyy");
            t.verifyEqual(timeindex.getValue_(),738331)
            t.verifyEqual(timeindex.name,"Time")

        end
        
        function indexGetterTest(t)
            timeindex = frames.TimeIndex("24*06*2021",Format="dd*MM*yyyy");
            t.verifyEqual(timeindex.value,datetime("24*06*2021",Format="dd*MM*yyyy"))
        end
        
        function positionOfTest(t)
            warning('off','frames:Index:notUnique')
            index = frames.Index([30 10 20 30]);
            uniqueindex = frames.UniqueIndex([30 10 20]);
            
            t.verifyEqual(index.positionOf([30,20]),[1 4 3]')
            t.verifyEqual(uniqueindex.positionOf([20,30]),[3 1]')
            warning('off','frames:Index:notUnique')
        end
        
        function positionInTest(t)
            warning('off','frames:Index:notUnique')
            index = frames.Index([30 10 20 30]);
            uniqueindex = frames.UniqueIndex([30 10 20]);
            sortedindex = frames.SortedIndex([10 20 30]);
            
            t.verifyError(@indexNotWhole,'frames:assertFoundIn')
            function indexNotWhole(), index.positionIn([40,30,20]); end
            
            t.verifyEqual(index.positionIn([40,50,30,20,10]),[3 5 4 3]')
            t.verifyEqual(uniqueindex.positionIn([40,50,30,20,10]),[3 5 4]')
            t.verifyEqual(sortedindex.positionIn([40,50,30,20,10]),[false false true true true]')
            warning('on','frames:Index:notUnique')
        end
        
        function unionTest(t)
            index = frames.Index([30 10 20]);
            uniqueindex = frames.UniqueIndex([30 10 20]);
            sortedindex = frames.SortedIndex([10 20 30]);
            timeindex = frames.TimeIndex([10 20 30]);
            
            t.verifyWarning(@duplicate,'frames:Index:notUnique')
            function duplicate(), index.union([2 2 30]); end
            warning('off','frames:Index:notUnique')
            t.verifyEqual(index.union([2 2 30]).value,[30 10 20 2 2 30]')
            warning('on','frames:Index:notUnique')
            t.verifyEqual(uniqueindex.union([2 2 30]).value,[30 10 20 2]')
            t.verifyEqual(sortedindex.union([2 2 30]).value,[2 10 20 30]')
            t.verifyEqual(timeindex.union([2 2 30]).getValue_(),[2 10 20 30]')
  
        end
        
    end
end