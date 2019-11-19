# 3-way-autovalve
A motorized 3-way-valve to automatically supply washing machines with warm or cold water to reduce the electricity needed by the washing machine.

This project contains all the necessary files to build a motorized 3-way-valve that can supply a washing machine with first warm and then cold water during a regular washing program in order to reduce the overall electric energy needed by the washing machine.

The design is based on some underlying constraints:

- no modification of the particular washing machine
- all custom mechanical parts should be printable with a low-end 3D-printer
- parts should be easily repairable
- if something breaks, it should still be possible to operate the valve manually
- all parts used should be off-the-shelf, cheap, and easy to acquire
- programming is done using the arduino platform to keep things simple

As sole sensor the device uses a flow meter to measure the volume of water that is supplied to the washing at multiple points in time during the washing program. Based on that the code running on the arduino estimates at which stage of a typical washing program (main phase + multiple rinses) the washing machine is. It supplies warm water for the main phase and cold water for all other phases, and resets automatically when the washing program has reached its end.
