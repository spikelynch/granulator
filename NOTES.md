TODO

Immediate todo -

Separate out the stuff which controls playback rates from the
granulator into its own Synth - this should output a kr signal
for the rate which the granulator takes as an input

What this Synth should be able to do:

- tracking the slope of the playback lfo so that it can play grains
  backwards when the playback is reversed

- inverting playback (ie either play backwards all the time, or play
  the opposite way from the playback lfo

- detuning

- pitch shifting

- chorus






- Convert the granulator (including the buffer stuff) to a class

