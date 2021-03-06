% Best Response Dynamics with Fictitious Play
% many clusters, B&W
% needs get_payoff.m

close all;
clear all;
clc;

%% Parameters
img_name = 'win2.jpg'; % name of the image
t = 5;  % initial number of individuals in the population
sigma = 1000;    % standard deviation
% delta = 0.01;   % maximum distance between two probs vectors to stop the loop
num_cycles = 1000;   % number of iterations per cluster (should be automatically found!)
thr = 60;  % percentage of the highest probabilities to keep
num_clusters = 5;   % number of clusters to find (should be automatically found!)

%% Main body

img_col = imread(img_name); % acquire the image...
img = rgb2gray(img_col);    % ...and bring it in b&w

% img = img(1 : 20, 1 : 20);

% img = [ 200, 200, 200, 130;
%         200, 200, 200, 65
%         200, 200, 200, 65;
%         65, 65, 65, 65];
% img = uint8(img);

% AA = 0;
% BB = 32;
% CC = 255;
% DD = 192;
% EE = 224;
% FF = 112;
% img = [ AA, AA, AA, BB, BB, BB;
%         AA, AA, CC, BB, BB, BB;
%         CC, CC, CC, CC, CC, BB;
%         DD, CC, CC, CC, EE, EE;
%         DD, CC, DD, CC, CC, EE;
%         DD, DD, DD, CC, FF, FF];
% img = uint8(img);

[img_height, img_width] = size(img);
n = img_width * img_height; % number of pixels

% img = img(1 : img_height / 2, 1 : img_width / 2);
% [img_height, img_width] = size(img);
% n = img_width * img_height; % number of pixels

% just for debugging: try to get a 0-1 image (only 2 color levels)
% for i = 1 : img_width 
%     for j = 1 : img_height
%         if img(j, i) >= 127
%             img(j, i) = 220;
%         else
%             img(j, i) = 80;
%         end
%     end
% end

% Show the original image
figure; imshow(img); title('Original');

A = get_payoff(img, sigma); % compute the payoff matrix

% idea: qundo tolgo un pixel dall'immagine perche gia dentro un cluster,
% non voglio piu sceglierlo nelle prossime giocate: metto la riga
% corrsipondente della matrice a tutti -1 cosi non lo scgliero  mai e e
% probabilita si redisribuiranno tra i restanti pixel.

flags = ones(img_height, img_width);    % '0' pixels are already inside a cluster
cluster_colors = zeros(1, num_clusters);    % contains the colors of the clusters. Needed to assign left pixels

% Probability vector. Initially set to a uniform distribution
x = ones(n, 1) / n;
prev_x = zeros(n, 1);   % previous x vector
new_x = ones(n, 1) / n; % vector used to update x

img_mean_cluster = zeros(img_height, img_width, 'uint8');   % clustered image

cluster_color_counter = 1;

pixels_to_remove = ones(n, 1);

for cluster = 1 : num_clusters
    
    num_pixel = sum(sum(flags));    % number of non-assiged pixels
    
    %     If less than 2 pixels are left it does not make any sense to keep on
    %     clustering the image
    if num_pixel < 2
        break;
    end
    
%     x = new_x;
%     % ora questo vettore contiene una uniforme tra i pixel rimasti
%     % now new_x contains a uniform among the remaining pixels
%     new_x = ones(n, 1) / num_pixel;
    
    x = ones(n, 1) / num_pixel;
    x = x .* pixels_to_remove;
    
    %     Vorrei avere tutte le prob a zero, tranne quelle dei pixel non ancora
    %     in un cluster. Ma controllare quali pixel sono gia stati assegnati e
    %     lungo da fare. Tuttavia A ha le righe corrispondenti ai pixel ga
    %     presi tutte nulle. Nella moltiplicazione A*x e' come se la prob fosse
    %     zero, perche tanto la moltiplicazione da sempre zero!
    
%     Compute the new vector x
    can_do_better = 1;  % loop condition
    for cycle = 1 : num_cycles
%     while can_do_better      
        avg_payoffs = A * x;
        [max_value, ~] = max(avg_payoffs);    % position of the pure strategy which is a best response
        r = zeros(n, 1);  
        max_values_counter = 0;
        for i = 1 : n 
            curr_val = avg_payoffs(i);
%             if curr_val == max_value
            if abs(curr_val - max_value) < 10^-6
                if i == 189
                    dafdf = 89;
                end
                r(i) = 1;
                max_values_counter = max_values_counter + 1;
            end
        end
        r = r / max_values_counter;
        % r(index_max) = 1;
        % in this way the best strategy is a pure strategy where I play a
        % pure strategy, choosing the play with higher avg payoff. But what
        % if there are many maxima? I would choose only the first one in 
        % the vector order!
        % I could choose randomly one of the maxima getting the same
        % payoff!
        y = x + (r - x) / (t + 1);  % new population strategy
        
        t = t + 1;  % increment population
        prev_x = x; % update the "previous" population strategy
        x = y;      % update the population strategy
        
        %     update the loop condition
        
%         1) norm of diff between prob vectors
%             if norm(x - prev_x) > delta     % probabilities are still strongly changing
%                 can_do_better = 1;
%             else
%                 can_do_better = 0;
%             end
        
%         % 2) diff of highest prob
%         max_diff = max(abs(x - prev_x));
%         if max_diff > delta     % probabilities are still strongly changing
%             can_do_better = 1;
%         else
%             can_do_better = 0;
%         end
    end
    
    %% Normalize the probabilities
    min_prob = min(x);  % smallest probability. This will become zero
    x = x - min_prob;
    max_prob = max(x);  % highest probanility. This will become one
    x = x ./ max_prob;
    
    %% Find and display the cluster
    mean_cluster_color = 0;     % mean color of the current cluster
    mask = zeros(img_height, img_width);
    img_cluster = zeros(img_height, img_width); % in this image we show the current cluster
    % sum of the probabilities of the chosen pixel. Needed to calculate the
    % mean color of the cluster
    sum_high_probs = 0;
    for i = 1 : n   % for each probability in vector x
        if x(i) > 1 - thr/100    % high prob of playing this choice  
            sum_high_probs = sum_high_probs + x(i);
            
            % Track back prob position to pixel
            yy = ceil(i / img_width);
            xx = rem(i, img_width);
            if xx == 0
                xx = img_width;
            end
            
            if flags(yy, xx)    % if the pixel is not assigned to a cluster
                img_cluster(yy, xx) = 255;  % color the pixel
                mask(yy, xx) = 1;   % fill the mask
                
%                 row_index = (yy - 1) * img_width + xx;  % find the corresponding row of A
%                 A(row_index, :) = zeros(1, n);  % payoff 0 playing this pixel in the future
                pixels_to_remove(i) = 0;
                                
                mean_cluster_color = mean_cluster_color + x(i) * double(img(yy, xx));
            end
        end
    end
    
    flags = flags - mask;   % update flags matrix usin the mask
    
    mean_cluster_color = uint8(mean_cluster_color / sum_high_probs);    % avg color of the current cluster
    cluster_colors(1, cluster_color_counter) = mean_cluster_color;  % save this avg cluster color
    cluster_color_counter = cluster_color_counter + 1;  % I want to know how many clusters I have found so far
    img_mean_cluster = img_mean_cluster + mean_cluster_color * uint8(mask); % color the cluster in the mean cluster img
    
    figure; imshow(img_cluster); title('Partial cluster');
end

fprintf('Number of found clusters: %d\n', cluster_color_counter - 1);

% figure; plot(1 : num_cycles, pprob(1, :), 1 : num_cycles, pprob(2, :), 1 : num_cycles, pprob(3, :));

%% Assign the remaining pixels
% for i = 1 : img_height
%     for j = 1 : img_width
%         if flags(i, j)
%             
%             color_votes = zeros(1, num_clusters);   % contains the votes for each cluster color
%             for k = max(i - 1, 1) : min(i + 1, img_height)
%                 for l = max(j - 1, 1) : min(j + 1, img_width)
%                     col = img_mean_cluster(k, l);
%                     for m = 1 : length(cluster_colors)
%                         if col == cluster_colors(m)
%                             color_votes(m) = color_votes(m) + 1;
%                         end
%                     end
%                 end
%             end
%             
%             if sum(color_votes)
%                 [~, elected_colors] = max(color_votes);
%                 elected_color = cluster_colors(elected_colors(1));
%                 img_mean_cluster(i, j) = elected_color;
%                 flags(i, j) = 0;    % remove the pixel from the flags
%             end
%         end
%     end
% end

figure; imshow(img_mean_cluster); title('Mean clusters');