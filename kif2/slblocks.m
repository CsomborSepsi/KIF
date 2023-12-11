function blkStruct = slblocks
% This function specifies that the library 'kif2'
% should appear in the Library Browser with the 
% name 'KIF2 Library'

    Browser.Library = 'kif2';
    % 'kif2' is the name of the library

    Browser.Name = 'KIF2 Library';
    % 'KIF2 Library' is the library name that appears
    % in the Library Browser

    blkStruct.Browser = Browser;