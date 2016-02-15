TTT
===
Here we should find the structure necessary to submit and control
jobs remotely (TODO: locally).

The idea is to have an interface abstracting the different queueing systems:
 * PBS/Torque
 * SGE
 * ...
and a layer to get remote info abstracting SSH, for instance.

Structure:
----------
 It should be a recursive system. Every node has a job submition interface to
a set of other nodes, terminals or whatever system you want to communicate with.
 For example, suppose there is a linux cluster I connect using SSH to then
submit my jobs using the Torque/PBS queue system. At my local/personal machine
I should only say something like "there is a linux cluster at address xxx 
reachable through port 22. btw, his name is yyy"; and then, at the linux cluster
it should have anotherthing saying "there is this queue system, PBS, use it
with the settings zzz".
 I looks to me this is the best way to maintain the setup the most flexible.
Steel, there should be a mechanism of harvesting back-and-forth the information,
from submition node (e.g, my laptop) to the work node (cluster) and vice-versa.

 
Configuration:
--------------
  A "config" file should maintain a list of Host settings. Host can be a remote
 machine as well as a cloud service, doesn't matter as long as it has a well
 defined entrance point.
