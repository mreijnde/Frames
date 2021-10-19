classdef multiIndexTest < AbstractFramesTests
    
    methods(Test)
        function constructorTest(t)
            warning('off','frames:Index:notUnique');
            
            t.verifyWarning(@duplicate,'frames:MultiIndex:notUnique')
            function duplicate(), frames.MultiIndex({[1,1],["a","a"]}); end
            
            t.verifyError(@badsorted,'frames:MultiIndex:requireSortedFail')
            function badsorted(), frames.MultiIndex({[1,1],["b","a"],[3,4]},UniqueSorted=true); end
            
            t.verifyError(@duplicateError,'frames:MultiIndex:requireUniqueFail')
            function duplicateError(), frames.MultiIndex({[1,1],["a","a"]},Unique=true); end                        
            
            % specify dimension arrays
            t.verifyEqual( frames.MultiIndex({[1,1],["a","b"]}), ...
                           frames.MultiIndex({frames.Index([1,1]),frames.Index(["a","b"])},name=["dim1","dim2"])); 
            
            % specify multi index rows
            t.verifyEqual( frames.MultiIndex({{1,"a"},{1,"b"}}), ...
                           frames.MultiIndex({frames.Index([1,1]),frames.Index(["a","b"])},name=["dim1","dim2"])); 
                                   
            % specify single dimension array
            t.verifyEqual( frames.MultiIndex([1,2,3,4,5],name="test"), ...
                           frames.MultiIndex(frames.Index(1:5),name="test") );             
                       
            timeindex = frames.TimeIndex(["24*06*2021","25*06*2021"],Format="dd*MM*yyyy");            
            t.verifyEqual(frames.MultiIndex(timeindex), frames.MultiIndex({timeindex}) ) %single index can be without {}
            
            mi = frames.MultiIndex({[2,3],timeindex,["a","b"]});            
            t.verifyEqual(mi.name,["dim1","Time","dim3"])
            t.verifyEqual(mi.getValue_(), ...
                         [frames.Index([2,3],name="dim1"), timeindex, frames.Index(["a","b"],name="dim3") ])            
           
            warning('on','frames:Index:notUnique');
        end
        
         function indexGetterTest(t)
             multiindex = frames.MultiIndex({[1,2],frames.Index([5,6],name="test"),["aa","bb"]});
             t.verifyEqual(multiindex.value,{{1,5,"aa"};{2,6,"bb"}})
             t.verifyEqual(multiindex.name,["dim1","test","dim3"])
             
             multiindex = frames.MultiIndex({[1,2],frames.Index([5,6],name="test"),["aa","bb"]},name=["","B","C"]);
             t.verifyEqual(multiindex.name,["dim1","B","C"])
         end
        
        function positionOfTest(t)
            warning('off','frames:Index:notUnique')
            warning('off','frames:MultiIndex:notUnique')
            index = frames.MultiIndex({[30 10 20 30 30],[1 2 1 2 1]});
            warning('on','frames:MultiIndex:notUnique')
            t.verifyEqual(index.positionOf({[30,20],1}),[1 3 5]')
            t.verifyEqual(index.positionOf({[30,20],[false true true true false]}),[3 4]')
            t.verifyEqual(index.positionOf({[30,20],[false true true]}),3)
            t.verifyEqual(index.positionOf({20,1}),3)
            t.verifyEqual(index.positionOf({[20,30],':'}),[1 3 4 5]')
            t.verifyEqual(index.positionOf({{10,2},{30,2}}),[2 4]') %multiple selector sets
             
            uniqueindex = frames.MultiIndex({[30 10 20],[1 2 1]},Unique=true);
            t.verifyEqual(uniqueindex.positionOf({[20,30],[1 1]}),[1 3]')
            t.verifyError(@nocellselector,'frames:MultiIndex:getSelector:cellselectorrequired');
            function nocellselector(), uniqueindex.positionOf([20,30]); end
            
            t.verifyError(@notallnestedcellselector,'frames:MultiIndex:getSelector:notallnestedcells');
            function notallnestedcellselector(), uniqueindex.positionOf({{10,2},[30,20]}); end        
            
            warning('off','frames:Index:notUnique')                        
        end
%         
%         function positionInTest(t)
%             warning('off','frames:Index:notUnique')
%             index = frames.Index([30 10 20 30]);
%             uniqueindex = frames.Index([30 10 20],Unique=true);
%             sortedindex = frames.Index([10 20 30],UniqueSorted=true);
%             
%             t.verifyError(@indexNotWhole,'frames:assertFoundIn')
%             function indexNotWhole(), index.positionIn([40,30,20]); end
%             
%             t.verifyEqual(index.positionIn([40,50,30,20,10]),[3 5 4 3]')
%             t.verifyEqual(uniqueindex.positionIn([40,50,30,20,10]),[3 5 4]')
%             t.verifyEqual(sortedindex.positionIn([10,20,30,40,50]),[true true true false false]')
%             t.verifyEqual(sortedindex.positionIn([10,20,30,40,50]),[true true true false false]')
%             warning('on','frames:Index:notUnique')
%             
%             a = frames.TimeIndex(seconds(1):seconds(2):seconds(4));
%             t.verifyEqual(a.positionIn(seconds([5 1 3]),false),[false true true]')
%             
%             a = frames.TimeIndex(seconds(1):seconds(2):seconds(4),Unique=false);
%             t.verifyEqual(a.positionIn(seconds([5 1 3])),[2 3]')
%         end
%         
%         function unionTest(t)
%             index = frames.Index([30 10 20]);
%             uniqueindex = frames.Index([30 10 20],Unique=true);
%             sortedindex = frames.Index([10 20 30],UniqueSorted=true);
%             timeindex = frames.TimeIndex([10 20 30]);
%             
%             t.verifyWarning(@duplicate,'frames:Index:notUnique')
%             function duplicate(), index.union([2 2 30]); end
%             warning('off','frames:Index:notUnique')
%             t.verifyEqual(index.union([2 2 30]).value,[30 10 20 2 2 30]')
%             warning('on','frames:Index:notUnique')
%             t.verifyEqual(uniqueindex.union([2 2 30]).value,[30 10 20 2]')
%             t.verifyEqual(sortedindex.union([2 2 30]).value,[2 10 20 30]')
%             t.verifyEqual(timeindex.union([2 2 30]).getValue_(),[2 10 20 30]')
%   
%             durationindex = frames.TimeIndex(minutes([10 20 30]));
%             t.verifyEqual(durationindex.union(minutes([2 2 30])).getValue_(),minutes([2 10 20 30]'))
%         end
        
%         function assignmentTest(t)
%             index = frames.Index([30 10 20]);
%             uniqueindex = frames.Index([30 10 20],Unique=true);
%             sortedindex = frames.Index([10 20 30],UniqueSorted=true);
%             timeindex = frames.TimeIndex([10 20 30]);
%             durationindex = frames.TimeIndex(minutes([10 20 30]));
%             
%             t.verifyWarning(@renderDupl,'frames:Index:subsagnNotUnique')
%             function renderDupl, index.value(end+1:end+2) = [11 20]; end
%             t.verifyEqual(index.value, [30 10 20 11 20]')
%             
%             t.verifyError(@notUnique,'frames:Index:requireUniqueFail')
%             function notUnique, uniqueindex.value(1) = 10; end
%             uniqueindex.value(1:2) = [10 11]';
%             t.verifyEqual(uniqueindex.value, [10 11 20]')
%             uniqueindex.value(end+1) = 33;
%             t.verifyEqual(uniqueindex.value, [10 11 20 33]')
%             t.verifyError(@notUnique2,'frames:Index:requireUniqueFail')
%             function notUnique2, uniqueindex.value(1) = 33; end
%             
%             t.verifyError(@notSorted,'frames:Index:requireSortedFail')
%             function notSorted, sortedindex.value(2) = 100; end
%             sortedindex.value(end:end+1) = [40 50];
%             t.verifyEqual(sortedindex.value, [10 20 40 50]')
%             sortedindex.value([1 3]) = [1 22];
%             t.verifyEqual(sortedindex.value, [1 20 22 50]')
%             t.verifyError(@notSorted2,'frames:Index:requireUniqueFail')
%             function notSorted2, sortedindex.value(1) = 50; end
%             t.verifyError(@notSorted3,'frames:Index:requireSortedFail')
%             function notSorted3, sortedindex.value(1) = 33; end
%             
%             timeindex.value([2 3]) = ["16-Aug-2021" "17-Aug-2021"];
%             timeindex2 = timeindex;
%             timeindex2.value(end) = 738385;
%             t.verifyEqual(timeindex.value, timeindex2.value)
%             
%             t.verifyError(@tiNotSorted,'frames:Index:requireSortedFail')
%             function tiNotSorted, timeindex.value([3 2]) = ["16-Aug-2021" "17-Aug-2021"]; end
%             
%             t.verifyError(@tidNotSorted,'frames:Index:requireSortedFail')
%             function tidNotSorted, durationindex.value([3 2]) = hours([2 3]); end
%         end
    end
end
