# HackBeamStageBuilder
Stage builder application to convert the grid input into the .txt file required to load the stage on the application HackBeam.


To do:
  - Add interface to control map allowed borders.
  - Improve interface design and allignment.



Instructions:
  - TO PROPERLY SAVE FILES YOU NEED TO SPECIFY WHERE YOU WANT TO SAVE, BY ASSIGNING THE PATH TO THE CONSTANT FILEPATH, USING: #define FILEPATH "*PATH HERE*"
  - Drag and move objects on the grid. Once they are there, you can click on them to remove if desired.
  - The first pair of arrows add/remove lines on grid, the second add/remove collumns on grid. The remaining arrow is for now a button to create the .TXT file.
  - Remember to link the portals! To do so click and hold from one portal to another, creating a line that represents the link. Trying to create links with already linked portals will result in deleting their previous link.
  - The white rectangle above the grid is where you NEED to enter the NAME your file will have.
  - The smaller white rectangle to the right of the grid is where you enter how many times the projectile can be divided.
  - After setting everything above, just click on the earlier mentioned arrow to generate the file.
