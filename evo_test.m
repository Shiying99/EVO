clear; clc; close all;

load shapes_translation_events.mat
load shapes_translation_groundtruth.mat
load shapes_translation_calib.mat

event_mat = event_mat(94799:end, :);
groundtruth_mat = groundtruth_mat(186:end, :);

%%%RANDOM NOTES OF BEN, PLEASE IGNORE THESE FEW LINES
% We need to do a sort of fake bootstrap to start the map?, so
% we can take all the images before the first keyframe
% We pretend that the first image we get is a keyframe.

%%%%%%%%%%%%%%%%%%%%%%% START VARIABLE INIT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end_time = 0;
% this is a fake kf pose to simply force the first event image to be a keyframe
first_kf_pose = -1000*ones(1,8);

kf_pose_estimate = first_kf_pose;
last_pose_estimate = first_kf_pose;

groundtruth_idx = 1;
curr_pose_estimate = groundtruth_mat(groundtruth_idx,:);

% W = 309; %Width of distortion corrected image
% H = 231; %Height of distortion corrected image

N_planes = 50;  %Depth of DSI
min_depth = 0.15;
max_depth = 1.5;

KF_scaling = [];
KF_dsi = {};
KF_depths = [];

map = [];
%%%%%%%%%%%%%%%%%%%%%%%%% END VARIABLE INIT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%% MAIN LOOP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while end_time < event_mat(end,1)
	[event_image, curr_pose_estimate, keyframe_bool] = GetEventImage(kf_pose_estimate, last_pose_estimate, curr_pose_estimate, event_mat);
	event_image = CorrectDistortion(event_image, calib);
	imshow(event_image);
    disp('event image');
    disp(norm(curr_pose_estimate(2:end)-kf_pose_estimate(2:end)));
    pause(0.5);

	if keyframe_bool
		% add old DSI points to global map and reset DSI
        disp('new keyframe');
		if groundtruth_idx ~= 1
			[depth_map] = GetClusters(KF_dsi);
			[map_points] = GetNewMapPoints(depth_map, kf_pose_estimate, KF_scaling, KF_depths);%  - origin is implied to be (0,0,0)?
			map = [map; map_points];
		end

		% Initialize new keyframe
		kf_pose_estimate = curr_pose_estimate;
		[KF_scaling, KF_homographies, KF_dsi, KF_depths] = DiscretizeKeyframe(event_image, min_depth, max_depth, N_planes, calib);
	else
		% update DSI
        disp(norm(curr_pose_estimate-kf_pose_estimate));
		[T_kf, T_i] = FindPoseToKfH(kf_pose_estimate, curr_pose_estimate, calib);
        
        T_kf = eye(4);
        R_eul = eul2rotm([0,0.3,0]);
        T_i =   [R_eul, zeros(3,1);
                 0 0 0 1];
        event_image = zeros(229,307);
        event_image(110:120, 150:160) = 1;
             
       [KF_dsi] =  UpdateDSI(KF_dsi, event_image, T_kf, T_i, KF_homographies, KF_depths, calib);
	end

	groundtruth_idx = groundtruth_idx + 1;
	last_pose_estimate = curr_pose_estimate;
	curr_pose_estimate = groundtruth_mat(groundtruth_idx,:);
end