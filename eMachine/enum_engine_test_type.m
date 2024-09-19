classdef enum_engine_test_type
    %ENUM_ENGINE_TEST_TYPE Summary of this class goes here
    %   Detailed explanation goes here
    enumeration
       steady_state_averaged
       steady_state_continuous
       high_load
        
        
    end
    
    methods
       
        function tf = is_ss(obj)
           tf = obj == enum_engine_test_type.steady_state_averaged || obj == enum_engine_test_type.steady_state_continuous;
        end
            
        function tf = is_continuous(obj)
           tf = obj == enum_engine_test_type.high_load || obj == enum_engine_test_type.steady_state_continuous;
        end    
        
    end
    
end

