function celltext = read_textfile_to_var(filnam)
    fid = fopen(filnam, 'r');
    celltext = textscan(fid,'%s','delimiter','\n');
    fclose(fid);
end