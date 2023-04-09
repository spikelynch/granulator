# TODO

- quantise playback speed to rational values
- display the playback and harmonics when quantised

- multiple grain buffers - TouchOsc interface to select which to send to
- play back all buffers?

- refactor for multitrack
  - which controls are per-track and which are global? sort these out in the UI
  - encapsulate a grainstrack in an object?

- auto-mix: base the mix level on how loud the incoming signal is so that tracks don't fade out

- fancier playback:
  - intertwine different rates and directions


- rhythm controls
  - number of steps in step granulator
  - modulate grain level in time with playback
  - sync LFOs to playback

TODO list - touchosch

URL                  TO       SC
grains/buflen        Y        Y
grains/reset         Y        Y
grains/record0..3    Y        Y
grains/mode0..3      Y        Y
grains/speed0..3     Y        Y
grains/dust          Y        Y
grains/slope         Y        Y
grains/back          Y        Y
grains/trigger       Y        Y
grains/speedlock
grains/speedquant
grains/mix0          Y
grains/mix1          Y
grains/mix2          Y
grains/mix3          Y

trackselect

track/record
track/mode
track/speed
track/size
track/blur
track/mix
track/pan
track/track
track/jitter