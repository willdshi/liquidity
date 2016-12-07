function is_newer = is_file_newer(testfile, benchmarkfile)
%IS_NEWER tests whether the given file is newer than a benchmark file
% Parameters
%   testfile -      The full path (w/filename) of the file to test
%   benchmarkfile - The full path (w/filename) of the benchmark file
%
% Returns
%   is_newer -      Boolean indicating whether testfile is newer

    [benchpath, benchname, benchext] = fileparts(benchmarkfile);
    benchmark = dir(strcat([benchpath filesep], [benchname benchext]));
    
    [testpath, testname, testext] = fileparts(testfile);
    testfiles = dir(strcat([testpath filesep], [testname testext]));
    
    is_newer = (testfiles.datenum > benchmark.datenum);
        
end