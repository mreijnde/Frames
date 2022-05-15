classdef multiIndexTest < AbstractFramesTests
    
    methods(Test)
        function constructorTest(t)
            %warning('off','frames:Index:notUnique');
            
            t.verifyWarning(@duplicate,'frames:MultiIndex:notUnique')
            function duplicate(), frames.MultiIndex({[1,1],["a","a"]}); end
            
            t.verifyError(@badsorted,'frames:MultiIndex:requireSortedFail')
            function badsorted(), frames.MultiIndex({[1,1],["b","a"],[3,4]},UniqueSorted=true); end
            
            t.verifyError(@duplicateError,'frames:MultiIndex:requireUniqueFail')
            function duplicateError(), frames.MultiIndex({[1,1],["a","a"]},Unique=true); end                        
            
            % specify dimension arrays
            warning('off','frames:Index:notUnique');
            t.verifyEqual( frames.MultiIndex({[1,1],["a","b"]}), ...
                           frames.MultiIndex({frames.Index([1,1]),frames.Index(["a","b"])},name=["dim1","dim2"])); 
            warning('on','frames:Index:notUnique');
            
            % specify multi index rows
            warning('off','frames:Index:notUnique');
            t.verifyEqual( frames.MultiIndex({{1,"a"},{1,"b"}}), ...
                           frames.MultiIndex({frames.Index([1,1]),frames.Index(["a","b"])},name=["dim1","dim2"]));
            warning('on','frames:Index:notUnique');
                                   
            % specify single dimension array
            t.verifyEqual( frames.MultiIndex([1;2;3;4;5],name="test"), ...
                           frames.MultiIndex(frames.Index(1:5),name="test") );             
                       
            timeindex = frames.TimeIndex(["24*06*2021","25*06*2021"],Format="dd*MM*yyyy");            
            t.verifyEqual(frames.MultiIndex(timeindex), frames.MultiIndex({timeindex}) ) %single index can be without {}
            
            mi = frames.MultiIndex({[2,3],timeindex,["a","b"]});            
            t.verifyEqual(mi.name,["dim1","Time","dim3"])
            t.verifyEqual(mi.getValue_(), ...
                         {frames.Index([2,3],name="dim1",warningNonUnique=false), ...
                         frames.TimeIndex(["24*06*2021","25*06*2021"],Format="dd*MM*yyyy", ...
                                 Unique=false, warningNonUnique=false), ...                         
                         frames.Index(["a","b"],name="dim3",warningNonUnique=false) } )           
            %warning('on','frames:Index:notUnique');
        end
        
         function indexGetterTest(t)
             multiindex = frames.MultiIndex({[1,2,3],frames.Index([5,6,7],name="test"),["aa","bb","cc"]});
             t.verifyEqual(multiindex.value,{{1,5,"aa"};{2,6,"bb"};{3,7,"cc"}})
             t.verifyEqual(multiindex.value(:,:),{1,5,"aa";2,6,"bb";3,7,"cc"})
             t.verifyEqual(multiindex.value(:,2),[5,6,7]')
             t.verifyEqual(multiindex.value(2:3,"test"),[6,7]')
             t.verifyEqual(multiindex.value([true false true],"test"),[5,7]')
             t.verifyEqual(multiindex.name,["dim1","test","dim3"])
             
             multiindex = frames.MultiIndex({[1,2],frames.Index([5,6],name="test"),["aa","bb"]},name=["","B","C"]);
             t.verifyEqual(multiindex.name,["dim1","B","C"])
         end
        
        function positionOfTest(t)
            %warning('off','frames:Index:notUnique')
            warning('off','frames:MultiIndex:notUnique')
            index = frames.MultiIndex({[30 10 20 30 30],[1 2 1 2 1]});            
            t.verifyEqual(index.positionOf({[30,20],1}),[1 5 3]')
            t.verifyEqual(index.positionOf({[30,20],[false true true true false]}),[4 3]')
            t.verifyEqual(index.positionOf({[30,20],[false true true]}),3)
            t.verifyEqual(index.positionOf({20,1}),3)
            t.verifyEqual(index.positionOf({[20,30],':'}),[3 1 4 5]')
            t.verifyEqual(index.positionOf({{10,2},{30,2}}),[2 4]') %multiple selector sets
            warning('on','frames:MultiIndex:notUnique')
             
            uniqueindex = frames.MultiIndex({[30 10 20],[1 2 1]},Unique=true);
            t.verifyEqual(uniqueindex.positionOf({[20,30],[1]}),[3 1]')
            t.verifyError(@nocellselector,'frames:MultiIndex:getSelector:cellselectorrequired');
            function nocellselector(), uniqueindex.positionOf([20,30]); end
            
            t.verifyError(@notallnestedcellselector,'frames:MultiIndex:getSelector:notallnestedcells');
            function notallnestedcellselector(), uniqueindex.positionOf({{10,2},[30,20]}); end        
            
            %warning('off','frames:Index:notUnique')                        
        end
        
        
        function positionInTest(t)
            %warning('off','frames:Index:notUnique')
            warning('off','frames:MultiIndex:notUnique')
            
            % 1D examples
            index = frames.MultiIndex([30 10 20 30]');
            uniqueindex = frames.MultiIndex([30 10 20]',Unique=true);
            sortedindex = frames.MultiIndex([10 20 30]',UniqueSorted=true);
            
            t.verifyError(@indexWrongDims,'frames:MultiIndex:positionIn:unequalDim')
            function indexWrongDims(), index.positionIn([40,30,20]); end
            
            t.verifyError(@indexNotWhole,'frames:assertFoundIn')
            function indexNotWhole(), index.positionIn([40,30,20]'); end
                        
            t.verifyEqual(index.positionIn([40,50,30,20,10]'),[3 5 4 3]')
            t.verifyEqual(uniqueindex.positionIn([40,50,30,20,10]'),[3 5 4]')
            t.verifyEqual(sortedindex.positionIn([10,20,30,40,50]'),[true true true false false]')            
            
            a = frames.MultiIndex(frames.TimeIndex(seconds(1):seconds(2):seconds(4)),UniqueSorted=true);
            t.verifyEqual(a.positionIn(seconds([5 1 3])',false),[false true true]')
             
            a = frames.MultiIndex(frames.TimeIndex(seconds(1):seconds(2):seconds(4),Unique=false));
            t.verifyEqual(a.positionIn(seconds([5 1 3])'),[2 3]')
             
             % 2D examples
             multiindex = frames.MultiIndex({[1,2,3],frames.Index([5,6,7],name="test"),["aa","bb","cc"]});
             t.verifyEqual( multiindex.positionIn({{2,6,"bb"},{1,5,"aa"},{3,7,"dd"},{3,7,"cc"}}), [2,1,4]');
             t.verifyError( @index2DNotAllInTarget, 'frames:assertFoundIn');
             function index2DNotAllInTarget(), multiindex.positionIn({{2,6,"bb"},{2,5,"aa"},{3,7,"cc"}}), end
             
            %warning('on','frames:Index:notUnique')
            warning('on','frames:MultiIndex:notUnique')              
        end
%         
        function unionTest(t)
            % 1D examples
            index = frames.MultiIndex([30 10 20]');
            uniqueindex = frames.MultiIndex([30 10 20]',Unique=true);
            sortedindex = frames.MultiIndex([10 20 30]',UniqueSorted=true);
            timeindex = frames.MultiIndex(frames.TimeIndex([10 20 30]),UniqueSorted=true);
            
            t.verifyWarning(@duplicate,'frames:Index:notUnique')
            function duplicate(), index.union([2 2 30]'); end
            warning('off','frames:Index:notUnique') % warning with 'frames:Index' raised instead of 'frames:MultiIndex'
            t.verifyEqual(index.union([2 2 30]').value, {{30} {10} {20} {2} {2} {30}}')
            warning('on','frames:Index:notUnique') 
            t.verifyEqual(uniqueindex.union([2 2 30]').value,{{30} {10} {20} {2}}')
           
            t.verifyEqual(sortedindex.union([2 2 30]').value,{{2} {10} {20} {30}}')
            t.verifyEqual(timeindex.union([2 2 30]').getValue(),{{2} {10} {20} {30}}')
  
           durationindex = frames.MultiIndex(frames.TimeIndex(minutes([10 20 30])),UniqueSorted=true);           
           t.verifyEqual(durationindex.union(minutes([2 2 30]')).getValue(), ...
               { {minutes(2)} {minutes(10)} {minutes(20)} {minutes(30)}}');           
        end
        
        function assignmentTest(t)
            % 1D examples
            index = frames.MultiIndex([30;10;20]);
            uniqueindex = frames.MultiIndex([30;10;20],Unique=true);
            sortedindex = frames.MultiIndex([10;20;30],UniqueSorted=true);
       
            t.verifyWarning(@renderDupl,'frames:MultiIndex:notUnique')
            function renderDupl, index.value(end+1:end+2) = [11 20]; end
            t.verifyEqual(index.value,    {{30} {10} {20} {11} {20}}')
            t.verifyEqual(index.value(:), {{30} {10} {20} {11} {20}}')
            t.verifyEqual(index.value(:), {{30} {10} {20} {11} {20}}')
            
            %warning('off','frames:Index:subsagnNotUnique');
            
            t.verifyError(@notUnique,'frames:MultiIndex:requireUniqueFail')
            function notUnique, uniqueindex.value(1) = 10; end
            uniqueindex.value(1:2) = [10 11]';
            t.verifyEqual(uniqueindex.value(:,1), [10 11 20]')
            uniqueindex.value(end+1) = 33;
            t.verifyEqual(uniqueindex.value(:,1), [10 11 20 33]')
            t.verifyError(@notUnique2,'frames:MultiIndex:requireUniqueFail')
            function notUnique2, uniqueindex.value(1) = 33; end
            
            t.verifyError(@notSorted,'frames:MultiIndex:requireSortedFail')
            function notSorted, sortedindex.value(2) = 100; end
            sortedindex.value(end:end+1) = [40 50];
            t.verifyEqual(sortedindex.value(:,1), [10 20 40 50]')
            sortedindex.value([1 3]) = [1 22];
            t.verifyEqual(sortedindex.value(:,1), [1 20 22 50]')
            t.verifyError(@notSorted2,'frames:MultiIndex:requireUniqueFail')
            function notSorted2, sortedindex.value(1) = 50; end
            t.verifyError(@notSorted3,'frames:MultiIndex:requireSortedFail')
            function notSorted3, sortedindex.value(1) = 33; end
            
            %warning('on','frames:Index:subsagnNotUnique');
            
            % 2D examples
            index = frames.MultiIndex({1:3,["a","b","c"],[10 11 12]});                                    
            % assign single row
            value_expected = {{1,"a",10}; {22,"B",99}; {3,"c",12}};
            index_mod=index; index_mod.value(2) = {22,"B",99};
            t.verifyEqual(index_mod.value, value_expected)
            index_mod=index; index_mod.value(2,:) = {22,"B",99};
            t.verifyEqual(index_mod.value, value_expected)            
            index_mod=index; index_mod.value(2) = {{22,"B",99}};
            t.verifyEqual(index_mod.value, value_expected)       
            
            % assign multiple rows
            value_expected = {{1,"a",10}; {22,"B",99}; {33,"C",88}};
            index_mod=index; index_mod.value([2,3]) = {{22,"B",99},{33,"C",88}};
            t.verifyEqual(index_mod.value, value_expected )
            index_mod=index; index_mod.value([2,3]) = {22,"B",99 ; 33,"C",88};
            t.verifyEqual(index_mod.value, value_expected)
            
            % assign single dimension
            value_expected = {{1,"a",111}; {2,"b",222}; {3,"c",333}};
            index_mod=index; index_mod.value(:,3) = [111 222 333];
            t.verifyEqual(index_mod.value, value_expected )
            index_mod=index; index_mod.value(:,3) = [111 222 333]';
            t.verifyEqual(index_mod.value, value_expected )
            index_mod=index; index_mod.value(:,3) = {111 222 333};
            t.verifyEqual(index_mod.value, value_expected )
            index_mod=index; index_mod.value(:,3) = {111 222 333}';            
            t.verifyEqual(index_mod.value, value_expected )
            index_mod=index; index_mod.value(:,3) = {[111 222 333]};
            t.verifyEqual(index_mod.value, value_expected )
            index_mod=index; index_mod.value(:,"dim3") = [111 222 333];
            t.verifyEqual(index_mod.value, value_expected )
            
            % 1d timeindex
            timeindex = frames.MultiIndex(frames.TimeIndex([10 20 30]) ,uniqueSorted=true );             
            timeindex.value([2 3]) = ["16-Aug-2021" "17-Aug-2021"];
            timeindex2 = timeindex;
            timeindex2.value(end) = 738385;
            t.verifyEqual(timeindex.value, timeindex2.value)           
            t.verifyError(@tiNotSorted,'frames:MultiIndex:requireSortedFail')
            function tiNotSorted, timeindex.value([3 2]) = ["16-Aug-2021" "17-Aug-2021"]; end                        
        end   
    
        
        function alignTest(t)
            warning('off','frames:Index:notUnique');
            ind1 = frames.Index([1 2 3 3]);
            ind2 = frames.Index([2 3 4 1]);
            ind3 = frames.Index([2 4 3 3]);           
            ind4 = frames.Index([3 4 1 2]);            
            inds = frames.Index(missing,singleton=true);            
            warning('on','frames:Index:notUnique');

            % index objects (duplicates + singleton)
            ref0 = [1 4 2 1; 2 2 NaN 1;3 1 3 1; 4 NaN 4 1; NaN 3 1 1];
            [ind, ref] = align(ind3, ind4, ind1, inds, alignMethod="full", duplicateOption="duplicates");
            t.verifyEqual(ind.value, [ind3.value;1]);            
            t.verifyEqual(ref, ref0);
            
            [ind, ref] = align(ind3, ind4, ind1, inds, alignMethod="left", duplicateOption="duplicates");
            t.verifyEqual(ind.value, ind3.value);            
            t.verifyEqual(ref, ref0(1:4,:));
            
            [ind, ref] = align(ind3, ind4, ind1, inds, alignMethod="inner", duplicateOption="duplicates");
            t.verifyEqual(ind.value, ind3.value([1 3]));            
            t.verifyEqual(ref, ref0([1 3],:));
            
            [ind, ref] = align(ind3, ind4, ind1, inds, alignMethod="full", duplicateOption="unique");
            t.verifyEqual(ind.value, [2;4;3;1]);            
            t.verifyEqual(ref, ref0([1 2 3 5],:));
                      
            t.verifyError(@() align(ind3, ind4, ind1, inds, alignMethod="strict", duplicateOption="duplicates"), ...
                 'frames:Index:align:unequalIndex')
             
            t.verifyError(@() align(ind3, ind4, ind1, inds, alignMethod="full", duplicateOption="duplicatesstrict"), ...
                 'frames:Index:align:notUnique')
             
            % index objects, start with singleton
            [ind, ref] = align(inds, inds, ind2, alignMethod="full", duplicateOption="duplicates");
            t.verifyEqual(ind.value, ind2.value);            
            t.verifyEqual(ref, [1 1 1; 1 1 2; 1 1 3;1 1 4]);
            
            % expand
            [ind, ref] = align(ind3, ind1, alignMethod="full", duplicateOption="expand");
            t.verifyEqual(ind.value, [2;4;3;3;3;3;1]);            
            t.verifyEqual(ref, [1 2;2 NaN; 3 3; 3 4; 4 3; 4 4;NaN 1]);
            
            [ind, ref] = align(ind3, inds, alignMethod="full", duplicateOption="expand");
            t.verifyEqual(ind.value, ind3.value);            
            t.verifyEqual(ref, [1 1;2 1;3 1;4 1]);

            t.verifyError(@() align(ind3, ind1, ind2, alignMethod="full", duplicateOption="expand"), ...
                 'frames:Index:align:expandtoomany')
             
            % MultiIndex 1D mixed
            warning('off','frames:MultiIndex:notUnique');
            ind1M = frames.MultiIndex(ind1);
            ind3M = frames.MultiIndex(ind3);
            ind4M = frames.MultiIndex(ind4);
            indsM = frames.MultiIndex(missing,singleton=true);
            warning('on','frames:MultiIndex:notUnique');            
            
            [ind, ref] = align(ind3M, ind4M, ind1M, indsM, alignMethod="full", duplicateOption="duplicates");
            t.verifyEqual(ind.value(:,1), [ind3.value;1]);            
            t.verifyEqual(ref, ref0);
            
            [ind, ref] = align(ind3M, ind4, ind1, indsM, alignMethod="full", duplicateOption="duplicates");
            t.verifyEqual(ind.value(:,1), [ind3.value;1]);            
            t.verifyEqual(ref, ref0);
            
            % MultiIndex 2D mixed (2 same dimensions)
            warning('off','frames:MultiIndex:notUnique');
            ind1MM = frames.MultiIndex({ind1 ind1});
            ind3MM = frames.MultiIndex({ind3 ind3});
            ind4MM = frames.MultiIndex({ind4 ind4});
            indsMM = frames.MultiIndex(missing,singleton=true);
            warning('on','frames:MultiIndex:notUnique');
            
            [ind, ref] = align(ind3MM, ind4MM, ind1MM, indsMM, alignMethod="full", duplicateOption="duplicates");
            t.verifyEqual(ind.value(:,1), [ind3.value;1]);            
            t.verifyEqual(ind.value(:,1), ind.value(:,2));            
            t.verifyEqual(ref, ref0);
            
            % <todo: add multiIndex dim expansion test cases>
            
        end    

    end        
    
end
