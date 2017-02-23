function varargout = gui(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

function gui_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
handles.AxesHasAnImage = 0;
handles.ImageHasBeenSegmented = 0;
set(handles.listbox1,'enable','off');
set(handles.show_cluster_idx,'enable','off');
set(handles.figure1, 'Name', 'Image Color Segmentation Using K-Means Algorithm');
% Update handles structure
guidata(hObject, handles);

function varargout = gui_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

function select_folder_btn_Callback(hObject, eventdata, handles)
handles.output = hObject;
fn = uigetdir(cd,'Select a folder with pictures.');
cla(handles.axes1,'reset');
set(handles.listbox1,'enable','off'); %if user has selected another folder, we can't be sure that contains images this time.
set(handles.show_cluster_idx,'enable','off');
handles.ImageHasBeenSegmented = 0;
handles.AxesHasAnImage = 0;
if fn ~= 0   
    handles.picDir = fn; 
    img = [dir(fullfile(handles.picDir,'*.png')); dir(fullfile(handles.picDir,'*.jpg')); dir(fullfile(handles.picDir,'*.jpeg'))];
    successFulReadedImagesCount = 1;
    for x = 1 : length(img)
        try
            handles.I{successFulReadedImagesCount} = imread(fullfile(handles.picDir,img(x).name));
            successFulReadedImagesCount = successFulReadedImagesCount + 1;
        catch err
            fprintf('image #%i (%s) cannot be opened: %s\n',x,img(x).name,err.message);
        end
    end     
    if length(img) ~= 0
        set(handles.listbox1,'enable','on');
        handles.AxesHasAnImage = 1;
        axes(handles.axes1);
        imshow(handles.I{1}), title('Original Image');
    else
        set(handles.listbox1,'enable','off');
        warndlg('Selected Folder Does Not Contain Any Appropriate Image File. (i.e folder must contain images with fromat : png or jpg). Recursive search is not supported.')
    end
    set(handles.listbox1,'string',{img.name});    
end
guidata(hObject, handles);


function listbox1_Callback(hObject, eventdata, handles)
handles.output = hObject;
set(handles.show_cluster_idx,'value',1);
set(handles.show_cluster_idx,'enable','off');
index = get(handles.listbox1,'value');
axes(handles.axes1);
imshow(handles.I{index}), title('Original Image');
handles.ImageHasBeenSegmented = 0;
guidata(hObject, handles);

function listbox1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function pushbutton2_Callback(hObject, eventdata, handles)
handles.output = hObject;
if handles.AxesHasAnImage ~= 1 % if no image is loaded, show error & return. 
    warndlg('You have to select an image.')
    return;
end
set(handles.show_cluster_idx,'enable','off');
set(handles.show_cluster_idx,'value',1);
index = get(handles.listbox1,'value');
im = handles.I{index};
axes(handles.axes1);
imshow(im), title('Original Image');
handles.ImageHasBeenSegmented = 0;
handles.AxesHasAnImage = 1; %useful at debug stage
guidata(hObject, handles);

function pushbutton3_Callback(hObject, eventdata, handles)
handles.output = hObject;
if handles.AxesHasAnImage ~= 1 % if no image is loaded, show error & return. 
    warndlg('You have to select an image.')
    return;
end
index = get(handles.listbox1,'value');
clusterSize = get(handles.edit2,'String');
clusterSize = checkInputForValidNumber(clusterSize);
if clusterSize == -1
    warndlg('Cluster Size must be in a positive integer range.');
    return;
end
maximumIteration = get(handles.edit3,'String');
maximumIteration = checkInputForValidNumber(maximumIteration);
if maximumIteration == -1
    warndlg('Cluster Size must be in a positive integer range.');
    return;
end
handles.segmentedImages = kMeans(handles.I{index}, clusterSize, maximumIteration, handles, hObject);
handles.ImageHasBeenSegmented = 1;
guidata(hObject, handles);

function edit1_Callback(hObject, eventdata, handles)

function edit1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit2_Callback(hObject, eventdata, handles)

function edit2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit3_Callback(hObject, eventdata, handles)

function edit3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function numValue = checkInputForValidNumber(input)
val = str2num(input);
if ~isempty(val)
    numValue = val;
else
    numValue = -1;
end

function segmented_images = kMeans(img, clusterSize, maxIt, handles, hObject)
set(handles.show_cluster_idx,'value',1);
set(handles.show_cluster_idx,'enable','off');
use_lab = get(handles.use_lab, 'Value');
image_is_in_gray_scale = size(img, 3);

nrows = size(img,1);
ncols = size(img,2);
if image_is_in_gray_scale == 1
    ab = double(img(:));
    ab = reshape(ab,nrows*ncols,1);
else %if image is not on grayscale
    ab = double(img(:,:,:));
     if use_lab %if CIELAB usage is enabled
        cform = makecform('srgb2lab');
        img = applycform(img,cform);
        ab = double(img(:,:,:));
        ab = reshape(ab,nrows*ncols,3);
    else
        ab = reshape(ab,nrows*ncols,3);
     end
end

cluster_idx = kmeans(ab,clusterSize,'distance','sqEuclidean', ...
                                      'Replicates',maxIt);
pixel_labels = reshape(cluster_idx,nrows,ncols);
axes(handles.axes1);
coloredLabels = label2rgb(pixel_labels);
imshow(coloredLabels,[]), title('All Clusters');
segmented_images = cell(1, clusterSize+1); % +1 is to piggyback clusteridx
segmented_images{1} = pixel_labels;

for k = 1:clusterSize
    segmented_images{k+1} = reshape(cluster_idx==k,nrows,ncols);
end
set(handles.show_cluster_idx,'string',{'All Clusters';1:clusterSize});
set(handles.show_cluster_idx,'enable','on');
guidata(hObject, handles);

% --- Executes on selection change in show_cluster_idx.
function show_cluster_idx_Callback(hObject, eventdata, handles)
handles.output = hObject;
cluster = get(handles.show_cluster_idx, 'Value');
axes(handles.axes1);
if cluster == 1
    coloredLabels = label2rgb(pixel_labels);
    imshow(coloredLabels,[]), title('All Clusters');
else
    titleForImg = sprintf('Cluster : %d', cluster-1);
    imshow(handles.segmentedImages{cluster},[]), title(titleForImg);
end
guidata(hObject, handles);
    


% --- Executes during object creation, after setting all properties.
function show_cluster_idx_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in use_lab.
function use_lab_Callback(hObject, eventdata, handles)
