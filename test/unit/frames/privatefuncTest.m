% test private functions of package frames
%
% uses helper function 'getPrivateFuncHandle' to access private functions of package
%
classdef  privatefuncTest < AbstractFramesTests        
    
    methods(Test)
        function groupsummaryMatrixFastTest(t)                        
            dat     = gallery('integerdata', 1000 ,[100,10],0);
            groupid = gallery('integerdata', 40   ,[100,1],0)+5;            
            groupid_string = string(groupid);            
            
            % get handle to private function to test
            groupsummaryMatrixFast = frames.getPrivateFuncHandle('groupsummaryMatrixFast');
            
            % compare results for @mean and numeric groupid
            [B,BG,BC]    = groupsummaryMatrixFast(dat,groupid, @mean);
            [B0,BG0,BC0] = groupsummary(dat,groupid, @mean);
            t.verifyEqual(B,B0);
            t.verifyEqual(BG,BG0);
            t.verifyEqual(BC,BC0);
                        
            % compare results for @std and string groupid
            [B,BG,BC]    = groupsummaryMatrixFast(dat,groupid_string, @std);
            [B0,BG0,BC0] = groupsummary(dat,groupid_string, @std);
            t.verifyEqual(B,B0);
            t.verifyEqual(BG,BG0);
            t.verifyEqual(BC,BC0);
            
            % compare results for @length and numeric groupid
            warning('off', 'groupsummaryMatrixFast:vectorizeColsNotSupported');
            [B,BG,BC]    = groupsummaryMatrixFast(dat,groupid, @length);
            [B0,BG0,BC0] = groupsummary(dat,groupid, @length);
            t.verifyEqual(B,B0);
            t.verifyEqual(BG,BG0);
            t.verifyEqual(BC,BC0);
            warning('on', 'groupsummaryMatrixFast:vectorizeColsNotSupported');
        end
        
      
    end
end
