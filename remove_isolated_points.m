function [ clean_image ] = remove_isolated_points( image )
%REMOVE_ISOLATED_POINTS Summary of this function goes here
%   Detailed explanation goes here
[rows cols] = size(image);

for i=2:rows-1
    for j=2:cols-1
        cond1 = image(i-1,j-1)  == ~image(i,j) ; 
        cond2 = image(i-1,j)    == ~image(i,j) ;
        cond3 = image(i-1,j+1)  == ~image(i,j) ;
        cond4 = image(i,j-1)    == ~image(i,j) ; 
        cond6 = image(i,j+1)    == ~image(i,j) ;
        cond7 = image(i+1,j-1)  == ~image(i,j) ;
        cond8 = image(i+1,j)    == ~image(i,j) ;
        cond9 = image(i+1,j+1)  == ~image(i,j) ;
        
        conditions = cond1 + cond2 + cond3 + cond4 + cond6 + cond7 + cond8 + cond9;
        cond_left  = cond1 + cond4 + cond7;
        cond_right = cond3 + cond6 + cond9;
        cond_up    = cond1 + cond2 + cond3;
        cond_down  = cond7 + cond8 + cond9;
        
        if( (conditions  > 5) | ...
            ( (cond_up == 3) & (cond_left == 2) & (cond_right == 2) & (cond_down == 0) ) |... 
            ( (cond_right == 3) & (cond_up == 2) & (cond_down == 2) & (cond_left == 0) ) |...
            ( (cond_left == 3) & (cond_up == 2) & (cond_down == 2) & (cond_right == 0) ) |...
            ( (cond_down == 3) & (cond_left == 2) & (cond_right == 2) & (cond_up == 0) ) ...
          ) 
            image(i,j)= ~image(i,j);
        end
        
        
    end
end

clean_image = image;

end

