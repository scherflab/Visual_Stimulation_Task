Movie Visual Stimulation Task
README Author: Daniel Elbich, MS
4/19/17

Contact scherflab@gmail.com with questions regarding the task

Please cite this publication upon any use of this task or stimuli:
Elbich, D. B., & Scherf, S. (2017). Beyond the FFA: Brain-behavior correspondences in face recognition abilities. NeuroImage, 147, 409-422. doi.org/10.1016/j.neuroimage.2016.12.04

Instructions to run:
1. Add the folder & subfolders to the MATLAB path. Run the “runLocalizer.m” file to run the task. A menu will pop-up after execution - select “Dynamic”, then “Movies” to continue.

2. Program will prompt for a Subject ID as well as the date (date should already be populated).

3. Program will prompt for TR of EPI sequence as well as number of volumes to be ignored for subsequent analysis (default is a 2000 ms TR with first 4 volumes dropped in preprocessing)

4. Program will prompt whether trigger sequence from scanner console is available. “Yes” will accept trigger response from console in the form of the character ‘c’. “No” will allow user to trigger start of program on keyboard press with a delay of 4.75 seconds for discarded acquisitions (DISAQS). Should consult center or scanner technologist for appropriate values for your scanner

5. Data will output to the “data” folder which will include: a CSV file of the order, a protocol file of conditions and associated TRs (formatted for BrainVoyager), and a backup folder containing .mat files of program variables and timing in case of unexpected crash or data loss.