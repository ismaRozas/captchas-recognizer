function [ angle ] = equilibrated_word( image )

%EQUILIBRATE_WORDS Angle difference between last and first letters
%   Taking the height of first and last word we can calculate the angle or
%   inclination in the current word
%   Parameters:
%   - input  --> image matrix
%   - output --> measured relative distance representing angle between letters

[rows cols] = size(image);

%divide the image in four parts, take the border ones
left_image = image(:,1:(cols/4));
[left_rows left_cols] = size(left_image);

right_image = image(:,(3*cols/4): cols);
[right_rows right_cols] = size(right_image);

%find the highest point in each part ...
left_sum=sum(left_image');
%... by suming the rows. If the row sum is equal to the number of cols,
%this means that each column has a "1" (a white pixel), being therefore a
%white row
left_top  = min(find(left_sum  < (left_cols-2))) -1;

%the same proccess in the right image
right_sum=sum(right_image');
right_top = min(find(right_sum < (right_cols-2))) -1;

angle = abs(left_top - right_top);

end

