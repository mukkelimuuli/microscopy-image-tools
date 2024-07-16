# microscopy-image-tools

Here you can find overall explanations of the tools in microscopy-image-tools repository, more specific explanation of used methods and code can be found from the files.


# twoDparticleTracking version 2.0


General comments:

-THE ONLY FILE WHICH NEEDS TO BE RUN IS twoDparticleTracking.m, other files only need to be on the MATLAB path.
-The bfmatlab folder contains a MATLAB package which is needed for opening the microscopy files. 
-2DparticleTrack folder contains 2 dimensional particle tracking algorithm for microscopy image series i.e. 2D particle tracking in time dimension. The folder is a combination of algorithms (developed by professionals) I found suitable for the purpose and algorithms made by me.
-startup.m file needs to be moved to the MATLAB root folder, since its sole purpose is to direct the files in the 2DparticleTrack directory into the MATLAB path so the user doesn't need to worry about that. Startup.m is then run every time the user starts MATLAB and thus the files are always on the path i.e. MATLAB can run them when they are needed.

Adjustable parameters in the tool by files:

twoDparticleTracking.m 
*Channel which is extracted (row 21)
*Timepoints which are extracted (row 31)
*Intensity threshold (row 50)
*c i.e. the coefficient which determines the window size (row 81)

automatic_particle_tracking.m
*max linking distance of adjacent tracking points (row 20)
*false can be turned into true --> shows clustering for each timepoint done by dbscan clustering algorithm (row 32 inside the function call)
*foldername (row 121)

dbscan_clustering.m
*eps i.e. the epsilon value of dbscan clustering alorithm, determines the distance from the calculated point
*minpts, minimum points, which need to be inside the distance determined by eps for the "point cloud" to be defined as a cluster 



Version 2.0 can only read .oir files


# Other tools (incoming)