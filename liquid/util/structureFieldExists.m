function resultTF = structureFieldExists(inStruct, fieldName)
% inStruct is the name of the structure or an array of structures to search
% fieldName is the name of the field for which the function searches
    resultTF = 0;
    f = fieldnames(inStruct(1));
    for i=1:length(f)
        if(strcmp(f{i},strtrim(fieldName)))
            resultTF = 1;
            return;
        elseif isstruct(inStruct(1).(f{i}))
            resultTF = structureFieldExists(inStruct(1).(f{i}), fieldName);
            if resultTF
                return;
            end
        end
    end
end