%
%
%  Installation:
%
%  - Copy this file into the XTensions folder in the Imaris installation directory
%  - You will find this function in the Image Processing menu
%
%    <CustomTools>
%      <SurpassTab>
%        <SurpassComponent name="bpSpots">
%          <Item name="Discount Overlapping Spots" icon="Matlab" tooltip="Find spots close to surface.">
%            <Command>MatlabXT::overcountspots(%i)</Command>
%          </Item>
%        </SurpassComponent>
%        <SurpassComponent name="bpSurfaces">
%          <Item name="Discount Overlapping Spots" icon="Matlab" tooltip="Find spots close to surface.">
%            <Command>MatlabXT::overcountspots(%i)</Command>
%          </Item>
%        </SurpassComponent>
%      </SurpassTab>
%    </CustomTools>
% 
%	Description:
%		Among two spots populations, counts a single spots object where spots are overlapping by a user-defined
%		distance threshold.
% 


function overcountspots(aImarisApplicationID)


% connect to Imaris interface
if ~isa(aImarisApplicationID, 'Imaris.IApplicationPrxHelper')
    javaaddpath ImarisLib.jar
    vImarisLib = ImarisLib;
    if ischar(aImarisApplicationID)
        aImarisApplicationID = round(str2double(aImarisApplicationID));
    end
    vImarisApplication = vImarisLib.GetApplication(aImarisApplicationID);
else
    vImarisApplication = aImarisApplicationID;
end

% the user has to create a scene with some spots and surface
vSurpassScene = vImarisApplication.GetSurpassScene;
if isequal(vSurpassScene, [])
    msgbox('Please create some Spots and Surface in the Surpass scene!')
    return
end

vNumChans = vImarisApplication.GetDataSet.GetSizeC;


% get the spots objects
vSpots = vImarisApplication.GetFactory.ToSpots(vImarisApplication.GetSurpassSelection);

vSpotsSelected = ~isequal(vSpots, []);

if vSpotsSelected
    vParent = vSpots.GetParent;
else
    vParent = vSurpassScene;
end

% get the spots
vSpotsSelection = 1;

vNumberOfSpots = 0;

vSpotsList = [];

vSpotsName = {};

for vIndex = 1:vParent.GetNumberOfChildren
    vItem = vParent.GetChild(vIndex-1);
    if vImarisApplication.GetFactory.IsSpots(vItem)
        vNumberOfSpots = vNumberOfSpots + 1;
        vSpotsList(vNumberOfSpots) = vIndex;
        vSpotsName{vNumberOfSpots} = char(vItem.GetName);
        
        if vSpotsSelected && isequal(vItem.GetName, vSpots.GetName)
            vSpotsSelection = vNumberOfSpots; 
        end
    end
end

if min(vNumberOfSpots) == 0
    msgbox('Please create at least two spots populations!')
    return
end

if vNumberOfSpots>1
    [vSpotsSelection1,vOk1] = listdlg('ListString',vSpotsName, ...
        'InitialValue', vSpotsSelection, 'SelectionMode','single', ...
        'ListSize',[300 300], 'Name','Counts Overlapping Spots', ...
        'PromptString',{'Please select the spots:'});
    if vOk1<1, return, end
end

if vNumberOfSpots>1
    [vSpotsSelection2,vOk2] = listdlg('ListString',vSpotsName, ...
        'InitialValue', vSpotsSelection, 'SelectionMode','single', ...
        'ListSize',[300 300], 'Name','Counts Overlapping Spots', ...
        'PromptString',{'Please select the spots:'});
    if vOk2<1, return, end
end

vAnswer = inputdlg({'Please enter the spot to spot threshold (um):'}, ...
    "Over Count Spots",1,{'5'});
if isempty(vAnswer), return, end
vThreshold = abs(str2double(vAnswer{1}));


% compute the distances and create new spots objects
vNumberOfSpotsSelected = numel(vSpotsSelection);



        vItem1 = vParent.GetChild(vSpotsList( ...
            vSpotsSelection1(1)) - 1);
        vSpots1 = vImarisApplication.GetFactory.ToSpots(vItem1);
   
		vPos1 = vSpots1.GetPositionsXYZ;
        vSpotsStats1 = vSpots1.GetStatistics;
        
		vSpotsTime1 = vSpots1.GetIndicesT;
		vSpotsRadius1 = vSpots1.GetRadiiXYZ;
        vNumberOfSpots1 = size(vPos1, 1);
        
        
        vItem2 = vParent.GetChild(vSpotsList( ...
            vSpotsSelection2(1)) - 1);
        vSpots2 = vImarisApplication.GetFactory.ToSpots(vItem2);
    
		vPos2 = vSpots2.GetPositionsXYZ;
        vSpotsStats2 = vSpots2.GetStatistics;
     
		vSpotsTime2 = vSpots2.GetIndicesT;
		vSpotsRadius2 = vSpots2.GetRadiiXYZ;
        vNumberOfSpots2 = size(vPos2, 1);
        dist = zeros(vNumberOfSpots2, 1);
        allinds = [];
        
        vNewSpotsBin = vImarisApplication.GetFactory.CreateSpots;
        vNewSpotsBin.SetName(strcat(char(vSpots1.GetName), '+', char(vSpots2.GetName)));
        for i = 1:vNumberOfSpots1
            for j = 1:vNumberOfSpots2
                xdist = vPos1(i, 1) - vPos2(j, 1);
                ydist = vPos1(i, 2) - vPos2(j, 2);
                zdist = vPos1(i, 3) - vPos2(j, 3);
                dist(j) = sqrt(xdist.^2 + ydist.^2 + zdist.^2);
                
                % loop through each Spot in pop1 and pop2
                % and create a new spots object with both spots
                % if the distance is smaller than the threshold, just take
                % one of the spots
            end
            if min(dist) > vThreshold
                allinds = [allinds, i];
            end
        end
        
        
        if vThreshold == 0
            vThreshold = 1;
        end
        
        vPos1(allinds, :);
        vNewSpotsBin.Set(vertcat(vPos1(allinds, :), vPos2), ...
            zeros(length(allinds) + length(vPos2), 1), ...
            zeros(length(allinds) + length(vPos2), 1) + vThreshold);
        vNewSpotsBin.SetColorRGBA(hex2dec('ff0000'));
        vParent.AddChild(vNewSpotsBin, -1);
         
                   

