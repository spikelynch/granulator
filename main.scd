// Execute this before booting the server

(
Server.default.options.inDevice_("Scarlett 2i2 USB");
Server.default.options.hardwareBufferSize_(1024);
//Server.default.options.outDevice_("Scarlett 2i2 USB");
)
Server.killAll;

(
Routine.run({

	("./synths.scd").loadRelative;
	Granulator.init(s);

	s.sync;

	"Synths loaded".postln;

	("./control.scd").loadRelative;
	("./effects.scd").loadRelative;
	("./granulator.scd").loadRelative;
	s.sync;
	("./interface.scd").loadRelative;
});
)

