classdef groupTest < AbstractFramesTests
    
    methods(Test)
        function columnGroupTest(t)
            
            g1 = frames.Groups({1,2});
            t.verifyEqual(g1.keys,["Group1","Group2"]);
            t.verifyEqual(g1.values,{1,2})
            
            s.key1 = [6 3 5];
            s.another = [2 4];
            g2 = frames.Groups({[6 3 5],[2 4]}).shrink([2 5 3]);
            g3 = frames.Groups(s).shrink([2 5 3]);
            g3b = frames.Groups(containers.Map({'key2','another'},{[6 3 5],[2 4]})).shrink([2 5 3]);
            t.verifyEqual(g2.keys,["Group1","Group2"])
            t.verifyEqual(g2.values,{[5 3],2})
            t.verifyEqual(g3.keys,["key1" "another"]) %changed from cell char array to string array
            t.verifyEqual(g3.values,{[5 3],2})
            t.verifyEqual(g3b.keys,["another" "key2"]) %changed from cell char array to string array
            t.verifyEqual(g3b.values,{2,[5 3]})
            
            rowseries = frames.DataFrame(["grp2" "grp1" "grp2" "grp2"], RowSeries=true);
            g4 = frames.Groups(rowseries);
            g5 = g4.shrink(["Var4" "Var2" "Var3"]);
            g6 = g4.shrink(["Var4" "Var3"]);
            t.verifyEqual(g4.keys,["grp2","grp1"])
            t.verifyEqual(g4.values,{["Var1" "Var3" "Var4"],"Var2"})
            t.verifyEqual(g5.keys,["grp2","grp1"])
            t.verifyEqual(g5.values,{["Var4" "Var3"],"Var2"})
            t.verifyEqual(g6.keys,"grp2")
            t.verifyEqual(g6.values,{["Var4" "Var3"]})
            
            rowseries.data = cellstr(rowseries.data);
            rowseries.columns = cellstr(rowseries.columns);
            g7 = frames.Groups(rowseries).shrink({'Var4' 'Var2' 'Var3'});
            t.verifyEqual(g7.keys,{'grp2' 'grp1'})
            t.verifyEqual(g7.values,{{'Var4' 'Var3'},{'Var2'}})
            
            rowseries.data = [10 2 10 10];
            g8 = frames.Groups(rowseries).select([10 2]);
            t.verifyEqual(g8.keys,[10 2])
            t.verifyEqual(g8.values,{{'Var1' 'Var3' 'Var4'},{'Var2'}})
            
            frame = frames.DataFrame(["grp2" "grp1" missing "grp2";"grp1" "new" "grp2" "new"]);
            g9 = frames.Groups(frame);
            g9x = frames.Groups({frame});
            t.verifyEqual(g9,g9x)
            g10 = g9.select(["grp2" "grp1"]);
            expVals = { sparse(logical([0 1 0 0;1 0 0 0])), sparse(logical([1 0 0 1;0 0 1 0])), sparse(logical([0 0 0 0;0 1 0 1])) };
            t.verifyEqual(g9.keys,["grp1" "grp2" "new"])
            t.verifyEqual(g9.values,expVals)
            t.verifyEqual(g9.frame.columns, frame.getColumnsObj())
            t.verifyEqual(g10.keys,["grp2" "grp1"])
            t.verifyEqual(g10.values,expVals([2 1]))
            t.verifyEqual(g10.frame.rows, frame.getRowsObj())
            
            frame2 = frames.DataFrame(string([4 5 5 5]), 2);
            [f1,f2] = frames.align(frame,frame2);
            g11 = frames.Groups({f1,f2});
            t.verifyEqual(g11.keys,["grp1 4" "grp2 5" "new 5"])
            expVals = { sparse(logical([0 0 0 0;1 0 0 0])), sparse(logical([0 0 0 0;0 0 1 0])), sparse(logical([0 0 0 0;0 1 0 1])) };
            t.verifyEqual(g11.values,expVals)
            
        end
        
        function rowGroupTest(t)
            
            g1 = frames.Groups({1,2},'rowGroups');
            t.verifyEqual(g1.keys,["Group1","Group2"]);
            t.verifyEqual(g1.values,{1,2})
            t.verifyFalse(g1.isColumnGroups)
            
            
            rowseries = frames.DataFrame(["grp2" "grp1" "grp2" "grp2"]', ColSeries=true);
            g4 = frames.Groups(rowseries,'rowGroups');
            g5 = g4.shrink([4 2 3]);
            g6 = g4.shrink([4 3]');
            t.verifyEqual(g4.keys,["grp2","grp1"])
            t.verifyEqual(g4.values,{[1 3 4],2})
            t.verifyEqual(g5.keys,["grp2","grp1"])
            t.verifyEqual(g5.values,{[4 3],2})
            t.verifyEqual(g6.keys,"grp2")
            t.verifyEqual(g6.values,{[4 3]})
            
            rowseries.data = [10 2 10 10]';
            g8 = frames.Groups(rowseries,'rowGroups').select([10 2]);
            t.verifyEqual(g8.keys,[10 2])
            t.verifyEqual(g8.values,{[1 3 4],2})
            
            frame = frames.DataFrame(["grp2" "grp1" missing "grp2";"grp1" "new" "grp2" "new"]);
            g9 = frames.Groups(frame,'rowGroups');
            g10 = g9.select(["grp2" "grp1"]);
            expVals = { sparse(logical([0 1 0 0;1 0 0 0])), sparse(logical([1 0 0 1;0 0 1 0])), sparse(logical([0 0 0 0;0 1 0 1])) };
            t.verifyEqual(g9.keys,["grp1" "grp2" "new"])
            t.verifyEqual(g9.values,expVals)
            t.verifyEqual(g9.frame.columns, frame.getColumnsObj())
            t.verifyEqual(g10.keys,["grp2" "grp1"])
            t.verifyEqual(g10.values,expVals([2 1]))
            t.verifyEqual(g10.frame.rows, frame.getRowsObj())
            
            frame2 = frames.DataFrame(string([4 5 5 5]), 2);
            [f1,f2] = frames.align(frame,frame2);
            g11 = frames.Groups({f1,f2},'rowGroups');
            t.verifyEqual(g11.keys,["grp1 4" "grp2 5" "new 5"])
            expVals = { sparse(logical([0 0 0 0;1 0 0 0])), sparse(logical([0 0 0 0;0 0 1 0])), sparse(logical([0 0 0 0;0 1 0 1])) };
            t.verifyEqual(g11.values,expVals)
            
            frame3 = frames.DataFrame(["How" "do" "you" "do"],2);
            [f1,f2,f3] = frames.align(frame,frame2,frame3);
            g11 = frames.Groups({f1,f2,f3},'rowGroups');
            t.verifyEqual(g11.keys,["grp1 4 How" "grp2 5 you" "new 5 do"])
            expVals = { sparse(logical([0 0 0 0;1 0 0 0])), sparse(logical([0 0 0 0;0 0 1 0])), sparse(logical([0 0 0 0;0 1 0 1])) };
            t.verifyEqual(g11.values,expVals)

        end
        
    end
end
