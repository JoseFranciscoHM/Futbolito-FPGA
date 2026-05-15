%
%  BMP2RLE.M    "bit-mapped files to run-length encoded"
%
%			 Copyright 2000 M.D. Furman, all rights reserved.
%
%  Matlab program to convert simple .bmp files to run-length encoded
%         files that can be integrated into ALTERA video images.
%			 Matlab was used due to the easy access to the color table.
%         This program also automatically computes the closest color
%         table to the given image based on the capabilities of the
%         Altera board to generate colors.
%
%  Sample run (at a Matlab prompt):
%			 bmp2rle
%			 Enter filename (.bmp): image.bmp
%			 Enter output filename: out.txt
%
%  Complex images cannot be handled due to the limitation on the number
%  of encoded run lengths. If the image has too many run lengths, then
%  the image will be truncated when displayed with Altera. Run lengths
%  start from the upper left of the image and move left-to-right, top-
%  to-bottom. One contiguous "run" until the color changes is one 
%  run length. It may or may not cross lines.
%
%  The last line before END in the "out.txt" file should not exceed
%  3FF in the first column (See below). If it does, the image will be 
%  clipped. The program will eventually accommodate larger chips.
%
%			  3FF :    7a3;
%          ^^^
%

filename    = input ('Enter filename (.bmp): ', 's');
fileout     = input ('Enter output filename: ', 's' );
[ A, map ]  = imread( filename, 'bmp' );

fid = fopen( fileout, 'w' );

semicolon = 59;   	   % Ascii = semicolon
percent   = 37;   	   % Ascii = percent

fprintf( fid, 'Depth = 1024%c\n',        semicolon );
fprintf( fid, 'Width = 12%c\n',          semicolon );
fprintf( fid, 'Address_radix = hex%c\n', semicolon );
fprintf( fid, 'Data_radix = hex%c\n',    semicolon );
fprintf( fid, '%c Graphics Format ROM Data %c\n', percent, percent );
fprintf( fid, '%c 8 bits length - 4 bits to select color from color map %c\n', ...
   				percent, percent );
fprintf( fid, '%c Color Map is the following: %c\n', percent, percent );

A2 = double( A ) + 1;	% 0 - 15 => 1 - 16 for index

map3 = floor( map * 2.99 );
mapx = zeros( 16, 2 );
offset = [ 4, 2, 1 ];

% Computer appropriate color map for image

for i = 1 : 16,
   for j = 1 : 3,
      if ( map3( i, j ) == 2 )
         mapx( i, 1 ) = mapx( i, 1 ) + offset( j );
         mapx( i, 2 ) = mapx( i, 2 ) + offset( j );
      elseif ( map3( i, j ) == 1 )
         if ( mapx( i, 1 ) > 0 )
            mapx( i, 2 ) = mapx( i, 2 ) + offset( j );
         else
            mapx( i, 1 ) = mapx( i, 1 ) + offset( j );
         end
      end
   end
   fprintf( fid, '%c %3d %3d   %c\n', ...
        		percent, mapx( i, 1 ), mapx( i, 2 ), percent );
end

fprintf( fid, 'Content\n' );
fprintf( fid, '  Begin\n' );
fprintf( fid, '[000..3FF] : FFF%c %c background white %c\n', ...
   				semicolon, percent, percent );

rgb     = mapx( : , 1 ) * 10 + mapx( : , 2 );
val     = A2( 1, 1 );
color   = rgb( val );
count   = 0;
address = 0;
total   = 0;

% Generate address and data output

for line = 1 : 120,
   for col = 1 : 160,
      count = count + 1;      
      point = A2( line, col );
      if ( rgb( point ) ~= color )
         address = output( fid, address, count - 1, val - 1 );
         address = address + 1;
         total   = total + count - 1;
         val     = point;
         color   = rgb( val );
         count   = 1;
      end
   end
end
address = output( fid, address, 160 * 120 - total + 1, A2( 1, 1 ) - 1 );
fprintf( fid, 'END\n' );
fclose( fid );


