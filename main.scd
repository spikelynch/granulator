// Execute this before booting the server

(
Server.default.options.inDevice_("Scarlett 2i2 USB");
Server.default.options.hardwareBufferSize_(1024);
Server.default.options.outDevice_("Scarlett 2i2 USB");
//Server.default.options.outDevice_("External Headphones");
)
Server.killAll;

(
Routine.run({

	("./synths.scd").loadRelative;
	Granulator.init(s);
	s.sync;
	("./control.scd").loadRelative;
	s.sync;
	("./granulator.scd").loadRelative;
	s.sync;
	("./effects.scd").loadRelative;
	s.sync;
	("./interface.scd").loadRelative;
});
)




