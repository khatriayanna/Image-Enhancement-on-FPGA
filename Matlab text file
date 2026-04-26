clc;
clear;
I = imread('pepperscolored.jpg');
% Convert to grayscale if needed
if size(I,3) == 3
   I = rgb2gray(I);
end
% Ensure 8-bit range (0–255)
I = uint8(I);
% Display for verification
figure; imshow(I); title('Grayscale Image');
% Write to text file
fid = fopen('pepperscolored.txt','w');
for i = 1:size(I,1)
   for j = 1:size(I,2)
       fprintf(fid,'%d\n', I(i,j));
   end
end
fclose(fid);
disp('Text file generated successfully');
