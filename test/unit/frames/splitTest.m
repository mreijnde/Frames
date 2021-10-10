classdef (SharedTestFixtures = {matlab.unittest.fixtures.PathFixture('../../../')} ) ...
        splitTest < matlab.unittest.TestCase
    
    methods(Test)
        
        function splitApplyTest(t)
            
            rowseries = frames.DataFrame(["grp2" "grp1" "grp2" "grp2"], RowSeries=true);
            g1 = frames.Groups(rowseries);
            series = frames.DataFrame([10 20 30 40], RowSeries=true);
            s1 = series.split(g1).apply(@(x) sum(x,2), 'applyToData');
            s2 = series.split(g1).apply(@sum, 2, 'applyToData');
            s3 = series.split(g1).apply(@(x) x.sum(2));
            t.verifyEqual(s1,frames.DataFrame([80 20 80 80]).asRowSeries())
            t.verifyEqual(s1,s2)
            t.verifyEqual(s1,s3)
            
            df = frames.DataFrame([1 2 3;4 5 6], [], [2 1 3]);
            gcell = {[3 1],2};
            g2 = frames.Groups(gcell);
            s4 = df.split(g2).apply(@(x) sum(x,2), 'applyToData');
            t.verifyEqual(s4,frames.DataFrame([1 5 5;4 11 11],[],[2 1 3]))

            df = frames.DataFrame([1 2 3 30;4 5 6 60]);
            gcell = frames.DataFrame([0 22 0 0;0 22 6 22]);
            g3 = frames.Groups(gcell);
            s5 = df.split(g3).apply(@(x) sum(x,2), 'applyToData');
            t.verifyEqual(s5,frames.DataFrame([34 2 34 34;4 65 6 65]))

        end
            
        function splitAggregateTest(t)
            
            rowseries = frames.DataFrame(["grp2" "grp1" "grp2" "grp2"], RowSeries=true);
            g1 = frames.Groups(rowseries);
            series = frames.DataFrame([10 20 30 40],RowSeries=true);
            s1 = series.split(g1).aggregate(@(x) sum(x,2), 'applyToData');
            s2 = series.split(g1).aggregate(@sum, 2, 'applyToData');
            s3 = series.split(g1).aggregate(@(x) x.sum(2));
            t.verifyEqual(s1,frames.DataFrame([80 20],[],["grp2" "grp1"]).asRowSeries())
            t.verifyEqual(s1,s2)
            t.verifyEqual(s1,s3)
            
            df = frames.DataFrame([1 2 3;4 5 6], [], [2 1 3]);
            gcell = {[3 1],2};
            g2 = frames.Groups(gcell);
            s4 = df.split(g2).aggregate(@(x) sum(x,2), 'applyToData');
            t.verifyEqual(s4,frames.DataFrame([5 1;11 4],[],["Group1" "Group2"]))

            df = frames.DataFrame([1 2 3 30;4 5 6 60]);
            gcell = frames.DataFrame([0 22 0 0;0 22 6 22]);
            g3 = frames.Groups(gcell);
            s5 = df.split(g3).aggregate(@(x) sum(x,2), 'applyToData');
            t.verifyEqual(s5,frames.DataFrame([34 NaN 2;4 6 65],[],[0 6 22]))
            

        end
        
    end
end
