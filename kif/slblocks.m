function blkStruct = slblocks
% This function specifies that the library 'kif'
% should appear in the Library Browser with the 
% name 'KIF Library'

    Browser.Library = 'kif';
    % 'mylib' is the name of the library

    Browser.Name = 'KIF Library';
    % 'KIF Library' is the library name that appears
    % in the Library Browser

    blkStruct.Browser = Browser;