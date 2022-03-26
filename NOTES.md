TODO

- Convert the granulator (including the buffer stuff) to a class

- Convert the TouchOSC interface library to a class

These will involve some disintermingling of code

Ideally I want to be able to use the granulator, TouchOSC and the
midi controller as part of the same session, so do stuff like


t = TouchOSC("192.168.0.30")

g = Granulator()

k = MidiKnobs();

t.bind('/grain', 0, 1, 0.5, { |self| g.set("amp", self.v) });

t.bind(