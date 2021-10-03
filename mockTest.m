classdef mockTest < matlab.unittest.TestCase

     methods(Test)
         function basicTest(t)
             
 t.verifyEqual(1,2)
         end

     end
 end
