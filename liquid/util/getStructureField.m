function fieldVal = getStructureField(inStruct, fieldName, defaultVal)
%GETSTRUCTUREFIELD extracts a field from a structure, or returns its default
%    value if the field is not present
% inStruct -    structure to examine for the selected field
% fieldName -   string variable holding the name of the selected field
% defaultVal -  a default value to assign if the desired field is not found

    if (structureFieldExists(inStruct, fieldName))
        fieldVal = inStruct.(fieldName);
    else
        fieldVal = defaultVal;
    end

end