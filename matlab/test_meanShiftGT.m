close all
clear all
clc

% profile on

nPtsPerClust = 250;
numDim = 3;
nClust  = 4;
std_dev = 3;
bandwidth = 6;

totalNumPts = nPtsPerClust * nClust;
% m contains the centers of the clusters
m(:,1) = [5 5 5]';
m(:,2) = [-5 -5 5]';
m(:,3) = [5 -5 -5]';
m(:,4) = [12 -5 -9]';

clustMed = [];
%clustCent;


x = std_dev * randn(numDim, totalNumPts);
% build the point set
for i = 1 : nClust
    x(:, 1 + (i-1)*nPtsPerClust : (i)*nPtsPerClust) = x(:, 1 + (i-1)*nPtsPerClust : (i)*nPtsPerClust) + repmat(m(:,i),1,nPtsPerClust);   
end

tic
[clustCent,point2cluster,clustMembsCell] = meanShiftGT(x, bandwidth, 1);
toc

numClust = length(clustMembsCell);


figure(10),clf,hold on
cVec = 'bgrcmykbgrcmykbgrcmykbgrcmyk';%, cVec = [cVec cVec];
for k = 1:min(numClust,length(cVec))
    myMembers = clustMembsCell{k};
    myClustCen = clustCent(:,k);
    scatter3(x(1,myMembers),x(2,myMembers),x(3,myMembers),[cVec(k) '.'])
    scatter3(myClustCen(1),myClustCen(2),myClustCen(3), 80, [cVec(k), 'o'], 'MarkerFaceColor', 'flat', 'MarkerEdgeColor', 'k')
    view(40,35)
end
title(['no shifting, numClust:' int2str(numClust)])