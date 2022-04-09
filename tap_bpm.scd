OSCdef.freeAll


(

~touchosc = TouchOSC("192.168.0.209", 9000);

~touchosc.button('/grains/bpm', "~", {});

~tapper = TapBeats();

~touchosc.button('/grains/tap', 0, { | v, t |
	if( v > 0, {
		~tapper.tap(t);
		if( ~tapper.bpm.isNil.not, {
			~touchosc.v_('/grains/bpm', ~tapper.bpm.round(1));
		})
	})
});

)


v =0.23234324
1.49.round(1)