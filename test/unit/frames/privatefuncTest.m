% test private functions of package frames
%
% uses helper function 'getPrivateFuncHandle' to access private functions of package
%
classdef  privatefuncTest < AbstractFramesTests        
    
    methods(Test)
        function groupsummaryMatrixFastTest(t)
            % generate test data
            dat     = gallery('integerdata', 1000 ,[100,10],0);
            groupid = gallery('integerdata', 40   ,[100,1],0)+5;            
            groupid_string = string(groupid);                        
            
            % get handle to private function to test
            groupsummaryMatrixFast = frames.DataFrame.getPrivateFuncHandle('groupsummaryMatrixFast');
            
            % compare results against groupsummary() for @mean and numeric groupid
            [B,BG,BC]    = groupsummaryMatrixFast(dat,groupid, @mean);
            [B0,BG0,BC0] = groupsummary(dat,groupid, @mean);
            t.verifyEqual(B,B0);
            t.verifyEqual(BG,BG0);
            t.verifyEqual(BC,BC0);
                        
            % compare results against groupsummary() for @std and string groupid
            [B,BG,BC]    = groupsummaryMatrixFast(dat,groupid_string, @std);
            [B0,BG0,BC0] = groupsummary(dat,groupid_string, @std);
            t.verifyEqual(B,B0);
            t.verifyEqual(BG,BG0);
            t.verifyEqual(BC,BC0);
            
            % check warnings + errors
            t.verifyError(@() groupsummaryMatrixFast(dat,groupid, @mean, 2) , ...
                'groupsummaryMatrixFast:invalidInputSize' );  
            t.verifyWarning(@() groupsummaryMatrixFast(dat,groupid, @length) , ...
                'groupsummaryMatrixFast:vectorizeNotSupported' );  
            t.verifyError(@() groupsummaryMatrixFast(dat,groupid, @(x) sum(x,1), 1, 2) , ...
                'groupsummaryMatrixFast:invalidFunction' );
            t.verifyError(@() groupsummaryMatrixFast(dat,groupid, @(x) sum(x,2), 1, 1) , ...
                'groupsummaryMatrixFast:invalidFunction' );              
            
            % compare results against groupsummary() for @length and numeric groupid          
            warning('off', 'groupsummaryMatrixFast:vectorizeNotSupported');
            [B,BG,BC]    = groupsummaryMatrixFast(dat,groupid, @length);
            [B0,BG0,BC0] = groupsummary(dat,groupid, @length);
            t.verifyEqual(B,B0);
            t.verifyEqual(BG,BG0);
            t.verifyEqual(BC,BC0);
            
            % aggregate columns
            groupid_cols = gallery('integerdata', 40   ,[10,1],0)+5; 
            [B0,BG0,BC0] = groupsummaryMatrixFast(dat ,groupid_cols, @mean, 2, 1);            
            [B,BG,BC] = groupsummaryMatrixFast(dat',groupid_cols, @mean, 1, 1);
            B = B';            
            t.verifyEqual(B0,B);
            t.verifyEqual(BG0,BG);
            t.verifyEqual(BC0,BC);            
            B = groupsummaryMatrixFast(dat,groupid_cols, @(x) mean(x,2), 2, 2);
            t.verifyEqual(B0,B);            
            B = groupsummaryMatrixFast(dat,groupid_cols, @(x) mean(x,2), 2, 2, true);
            t.verifyEqual(B0,B);
            B = groupsummaryMatrixFast(dat,groupid_cols, @(x) mean(x,2), 2, 2, false);
            t.verifyEqual(B0,B);
            B = groupsummaryMatrixFast(dat,groupid_cols, @(x) mean(x,2), 2, 2, false, false);
            t.verifyEqual(B0,B);
             
            % check apply2single setting
            B0    = groupsummaryMatrixFast(dat,groupid, @mean, 1, 1, true);
            B1    = groupsummaryMatrixFast(dat,groupid, @mean, 1, 1, false);
            t.verifyEqual(B0,B1);
            B = groupsummaryMatrixFast([11 22 33 44]',[1 2 1 3], @length, 1,1, false);
            t.verifyEqual(B, [2,22,44]');            
            warning('on', 'groupsummaryMatrixFast:vectorizeNotSupported');
        end
        
        
        function mergeSortTest(t)   
           mergeSort = frames.DataFrame.getPrivateFuncHandle('mergeSort');
           rng('default'); %fixed random seed
           
           v1 = sort(randi(1e6,1,1e4));
           v2 = sort(randi(1e6,1,1e3));
           v1_strings = string(v1);
           v2_strings = string(v2);
           
           % row vectors
           [Va, inda, ind_reva] = mergeSort(v1,v2, true);
           [Vb, indb, ind_revb] = mergeSort(v1,v2, false);
           v_comb = [v1,v2];
           [Vc, indc] = sort(v_comb);
           t.verifyEqual(Va,Vb);
           t.verifyEqual(Va,Vc);
           t.verifyEqual(inda,indb);
           t.verifyEqual(inda,indc);
           t.verifyEqual(ind_reva,ind_revb);
           t.verifyEqual(Va(ind_reva),v_comb);           
                     
           % column vectors
           [Va, inda, ind_reva] = mergeSort(v1',v2', true);
           [Vb, indb, ind_revb] = mergeSort(v1',v2', false);
           v_comb = [v1';v2'];
           [Vc, indc] = sort(v_comb);
           t.verifyEqual(Va,Vb);
           t.verifyEqual(Va,Vc);
           t.verifyEqual(inda,indb);
           t.verifyEqual(inda,indc);
           t.verifyEqual(ind_reva,ind_revb);
           t.verifyEqual(Va(ind_reva),v_comb);
           
           % row vectors with string
           [Va, inda, ind_reva] = mergeSort(v1_strings,v2_strings, true);
           [Vb, indb, ind_revb] = mergeSort(v1_strings,v2_strings, false);
           [Vc, indc] = sort([v1_strings,v2_strings]);
           t.verifyEqual(Va,Vb);
           t.verifyEqual(Va,Vc);
           t.verifyEqual(inda,indb);
           t.verifyEqual(inda,indc);
           t.verifyEqual(ind_reva,ind_revb);                      
        end    
        
        
    end
end
