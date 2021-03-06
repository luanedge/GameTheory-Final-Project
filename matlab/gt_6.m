% Replicator Dynamics
% many clusters, B&W
% Needs get_payoff.m

close all;
clear all;
clc;

%% Parameters
sigma = 1000000;    % standard deviation
num_cycles = 10;   % number of iterations per cluster
img_name = 'chess.jpg'; % name of the image
thr = 20;  % percentage of the highest probabilities to keep
num_clusters = 2;   % number of clusters to find (should be automatically found!)
C = 10^(-5);    % constant to avoid zero denominators

%%
img_col = imread(img_name);
img = rgb2gray(img_col);
% 
% img = [ 200, 200, 200, 130;
%     200, 200, 200, 65% img = img(1 : end - 5, 1 : end - 5);
% 
% img = 200 * ones(40, 40, 'uint8');
% inn1 = 65 * ones(10, 40, 'uint8');
% inn2 = 65 * ones(20, 10, 'uint8');
% inn3 = 130 * ones(10, 10, 'uint8');
% img(31 : 40, :) = inn1;
% img(11 : 30, 31 : end) = inn2;
% img(1 : 10, 31 : 40) = inn3;
% ;
%     200, 200, 200, 65;
%     65, 65, 65, 65];

[img_height, img_width] = size(img);
n = img_width * img_height;

figure;
imshow(img);

A = get_payoff(img, sigma);

% idea: qundo tolgo un pixel dall'immagine perche gia dentro un cluster,
% non voglio piu sceglierlo nelle prossime giocate: metto la riga
% corrsipondente della matrice a tutti -1 cosi non lo scgliero  mai e e
% probabilita si redisribuiranno tra i restanti pixel.

flags = ones(img_height, img_width);    % '0' pixels are already inside a cluster
cluster_colors = zeros(1, num_clusters);    % contains the colors of the clusters

x = ones(n, 1) / n; % (uniform) mixed strategy vector
new_x = ones(n, 1) / n;    % vector used to update x

img_mean_cluster = zeros(img_height, img_width, 'uint8');

cluster_color_counter = 1;

for cluster = 1 : num_clusters
    
    num_pixel = sum(sum(flags));    % number of non-assiged pixels
    
%     If less than 2 pixels are left it does not make any sense to keep on
%     clustering the image
    if num_pixel < 2
        break;
    end
    
%     ora questo vettore contiene una uniforme tra i pixel rimasti
    x = new_x; 
    new_x = ones(n, 1) / num_pixel;
%     Vorrei avere tutte le prob a zero, tranne quelle dei pixel non ancora
%     in un cluster. Ma controllare quali pixel sono gia stati assegnati e'
%     lungo da fare. Tuttavia A ha le righe corrispondenti ai pixel gia'
%     presi tutte nulle. Nella moltiplicazione e' come se la prob fosse
%     zero, perche tanto la moltiplicazione da' sempre zero!
    
    for cycle = 1 : num_cycles
        y = zeros(n, 1);
        pure_payoffs = A * x;
        den = x' * A * x;
        for i = 1 : n
%             fare cosi non falsa i risultati? se ho payoff molto piccoli
%             rischio di avere una frazione uguale a uno! Voglio C
%             infinnitesimo!!
%             y(i) = x(i) * (pure_payoffs(i) + C) / (den + C);
            y(i) = x(i) * (pure_payoffs(i) + C) / (den + C);
        end
        x = y;
    end
    
    %% Normalize the probabilities
    min_prob = min(x);  % smallest probability. This will become zero
    x = x - min_prob;
    max_prob = max(x);
    x = x ./ max_prob;
    
    %% Find and display the cluster
    mean_cluster_color = 0;     % mean color of the current cluster
    mask = zeros(img_height, img_width);
    img_cluster = zeros(img_height, img_width); % in this image we show the current cluster
%     sum of the probabilities of the chosen pixel. Needed to calculate the
%     mean color of the cluster
    sum_high_probs = 0; 
    for i = 1 : n   % for each probability in vector x
        if x(i) > 1 - thr/100    % high prob of playing this choice
            
            sum_high_probs = sum_high_probs + x(i);
            
            yy = ceil(i / img_width);
            xx = rem(i, img_width);
            if xx == 0
                xx = img_width;
            end
            
            if flags(yy, xx)    % if the pixel is not assigned to a cluster
                img_cluster(yy, xx) = 255;  % color the pixel
                mask(yy, xx) = 1;
                
                row_index = (yy - 1) * img_width + xx;  % find the corresponding row of A
                A(row_index, :) = zeros(1, n);  % payoff -1 playing this pixel in future
                
                mean_cluster_color = mean_cluster_color + x(i) * double(img(yy, xx));
            end
        end
    end
    
    flags = flags - mask;
    
    mean_cluster_color = uint8(mean_cluster_color / sum_high_probs);
    cluster_colors(1, cluster_color_counter) = mean_cluster_color;
    cluster_color_counter = cluster_color_counter + 1;
    img_mean_cluster = img_mean_cluster + mean_cluster_color * uint8(mask);
    
    figure
    imshow(img_cluster)
end

%% Assign the remaining pixels
for i = 1 : img_height
    for j = 1 : img_width
        if flags(i, j)
            
            color_votes = zeros(1, num_clusters);   % contains the votes for each cluster color
            for k = max(i - 1, 1) : min(i + 1, img_height)
                for l = max(j - 1, 1) : min(j + 1, img_width)
                    col = img_mean_cluster(k, l);
                    for m = 1 : length(cluster_colors)
                        if col == cluster_colors(m)
                            color_votes(m) = color_votes(m) + 1;
                        end
                    end
                end
            end
            
            if sum(color_votes)
                [~, elected_colors] = max(color_votes);
                elected_color = cluster_colors(elected_colors(1));
                img_mean_cluster(i, j) = elected_color;
                flags(i, j) = 0;    % remove the pixel from the flags
            end
        end
    end
end

figure
imshow(img_mean_cluster);
