Server.killAll

// Execute this before booting the server

Server.default.options.inDevice_("Scarlett 2i2 USB");

// TODO - FIXME

// [X] mode switching isn't working
// [ ] playback speed isn't working
// [ ] lfo filter modulation isn't working
// [ ] setting parameters from defaults at startup like passthrough
s.sampleRate

(

~to = TouchOSC("192.168.0.209", 9000);

~buflen = 4.0;

// trying setting the playback LFOs before the controls

// granulator playback modes
// each of these is a control bus with a synth that drives the pattern
// the granulator mode control switches between them

// more ideas for modules: scramble - do a permutation of ABCDEFGH slots

// todo - encapsulate these in a class


~grainsinb = Bus.control(s, 1);

~grainsin = SynthDef(
	\grainsin,
	{
		arg out=5, speed=1;
		Out.kr(out, 0.5 + SinOsc.kr(speed, 0, 0.5));
	}
).play(s, [\out, ~grainsinb, \speed, 1]);

~grainsawb = Bus.control(s, 1);

~grainsaw = SynthDef(
	\grainsaw,
	{
		arg out=5, speed=1;
		Out.kr(out, 0.5 + LFSaw.kr(speed, 0, 0.5));
	}
).play(s, [\out, ~grainsawb, \speed, 1]);

~grainreverseb = Bus.control(s, 1);

~grainreverse = SynthDef(
	\grainreverse,
	{
		arg out=5, speed=1;
		Out.kr(out, 0.5 - LFSaw.kr(speed, 0, 0.5));
	}
).play(s, [\out, ~grainreverseb, \speed, 1]);

~graintrib = Bus.control(s, 1);

~graintri = SynthDef(
	\graintri,
	{
		arg out=5, speed=1;
		Out.kr(out, 0.5 + LFTri.kr(speed, 0, 0.5));
	}
).play(s, [\out, ~graintrib, \speed, 1]);

~grainrandb = Bus.control(s, 1);

~grainrand = SynthDef(
	\grainrand,
	{
		arg out=5, speed=1;
		Out.kr(out, 0.5 + WhiteNoise.kr(0.5));
	}
).play(s, [\out, ~grainrandb, \speed, 1]);


~modes = [
	[ ~grainsaw, ~grainsawb, "saw" ],
	[ ~grainreverse, ~grainreverseb, "reverse", ],
	[ ~grainsin, ~grainsinb, "sine" ],
	[ ~graintri, ~graintrib, "triangle" ],
	[ ~grainrand, ~grainrandb, "random" ]
];

~playbacklfo = ~modes[0][0];

// audio buses

// recordb = input to bufrecorder
// granulatorb = output from granulator

~usbinput = 2;

~recordb = Bus.audio(s, 1);

~granulatorb = Bus.audio(s, 2);

// LFO bus and synth used to modulate the filter
// TODO - have a couple of LFOs and an interface to patch them to
// different settings

~lfob = Bus.control(s, 1);

~lfo = SynthDef(
	\lfo,
	{
		arg out=5, freq=1, amp=0;
		Out.kr(out, SinOsc.kr(freq, 0, amp));
	}
).play(s, [\out, ~lfob, \freq, 1, \amp, 0]);



// input filter chain

// ~infilter = SynthDef(
// 	\input_null,
// 	{x
// 		arg in = 2, out = 4;
// 		Out.ar(out, In.ar(in));
// 	}
// ).play(s, [\in, ~usbinput, \out, ~recordb]);


~fuzzbox = SynthDef(
	\fuzzbox,
	{
		arg in=2, out=4, distort=0.1, decay=0.999;
		var raw, cross, pf;
		raw = In.ar(in, 1).softclip;
		cross = CrossoverDistortion.ar(raw, 0.5, 0.5);
		pf = PeakFollower.ar(raw, decay);
		Out.ar(out, ((1 - distort) * raw) + (distort * pf * cross));
	}
).play(s, [\in, ~usbinput, \out, ~recordb, \distort, 0 ]);

// ~decimator = SynthDef(
// 	\decimator,
// 	{
// 		arg in=2, out=4, modb, rate=10000, smooth=0.5;
// 		var raw, mod, decimated;
// 		raw = In.ar(in, 1);
// 		mod = In.kr      (modb, 1);
// 		decimated = SmoothDecimator.ar(raw, rate + (0.2 * rate * mod), smooth);
// 		Out.ar(out, decimated);
// 	}
// ).play(s, [\in, ~usbinput, \out, ~recordb, \modb, ~lfob, \rate, 10000 ]);
//

// ~localmax = SynthDef(
// 	\localmax,
// 	{
// 		arg in=2, out=4, threshold=25;
// 		var chain;
// 		chain = FFT(LocalBuf(2048), In.ar(in, 1).distort);
// 		chain = PV_LocalMax(chain, threshold);
// 		Out.ar(out, IFFT.ar(chain));
// 	}
// ).play(s, [\in, ~usbinput, \out, ~recordb, \threshold, 25 ]);
//

// ~scramble = SynthDef(
// 	\scramble,
// 	{
// 		arg in=2, out=4, shift=1;
// 		var chain;
// 		chain = FFT(LocalBuf(2048), In.ar(in, 1).distort);
// 		chain = PV_BinScramble(chain, 0.5, 0.2, Impulse.kr(shift));
// 		Out.ar(out, IFFT.ar(chain));
// 	}
// ).play(s, [\in, ~usbinput, \out, ~recordb, \shift, 1 ]);
//


// buffer recorder

~frippbuffer = Buffer.alloc(s, s.sampleRate * ~buflen, 1);

~bufrecorder = SynthDef(
	\fripp_record,
	{
		arg in = 2, fb = 4, buffer = 0, mix = 0.25, record = 0.0, feedback = 0.0;
		var insig, fbsig;
		insig = record * In.ar(in, 1);
		fbsig = feedback * Mix.ar(In.ar(fb, 2));
		RecordBuf.ar(insig + fbsig, buffer, 0, mix, 1 - mix, loop: 1)
    }
).play(s, [\in, ~recordb, \record, 1.0, \fb, ~granulatorb, \out, 0, \buffer, ~frippbuffer], \addToTail);


// the main granulator synth

// todo - different styles of trigger

~granulator = SynthDef(
	\grainsynth,
	{
		arg out=0, modb, trate=120, size=12, rate=1, posb=5, amp=1.0, freq=10000, rq=0.3, sweep=0.25, chorus=0.0, blur=0.0, dust = 0, buffer;
		var dur, blen, clk, chor, pos, pan, grains, filtfreq;
		dur = size / trate;
		clk = (Impulse.kr(trate) * (1 - dust)) + (Dust.kr(trate) * dust);
		chor = chorus * 2.pow((LFNoise0.kr(trate) + 0.5).floor) + (1 - chorus);
		blen = BufDur.kr(buffer);
		pos = Wrap.kr(In.kr(posb, 1) + WhiteNoise.kr(blur), 0, 1);
		pan = WhiteNoise.kr(1 - sweep) + (2 * sweep * (pos - 1));
		filtfreq = (In.kr(modb, 1) * freq * 0.5) + freq;
		grains = TGrains.ar(2, clk, buffer, chor * rate, pos * blen, dur, pan, amp);
		Out.ar(out, RLPF.ar(grains, freq, rq)); // note that I've turned off freq lfo mod here
	}
).play(s, [\out, ~granulatorb, \buffer, ~frippbuffer, \posb, ~grainsawb, \modb, ~lfob]);

~mixerb = Bus.audio(s, 2); // this is what we will record from

~mixer = SynthDef(
	\mixer_synth,
	{
		arg in = 2, gbus = 4, out = 0, amp = 1.0, passthrough = 0.0;
		//Out.ar(out, In.ar(gbus, 2));
		Out.ar(out, (amp * In.ar(gbus, 2)) + (passthrough * In.ar(~recordb, 1) ! 2));
	}
).play(s, [\in, 2, \out, ~mixerb, \gbus, ~granulatorb, \amp, 1.0, \passthrough, 0.0], \addToTail);


~monitor = SynthDef(
	\monitor_synth,
	{
		arg in=2, out=0;
		Out.ar(out, In.ar(in, 2))
	}
).play(s, [\in, ~mixerb, \out, 0 ], \addToTail);

// sync the server so that all the synths are ready for the touchosc stuff
)

s.sync(); // this needs to be done in a routine because it calls yield
// sidebar -

~to

(
~to.button('/record', 1, { | v | ~bufrecorder.set(\record, v) });


~to.button('/reset', 0, { | v |
	if( v > 0, {
		var sp = ~to.v('/grains/speed')[0];
		~buflen = ~to.v('/grains/buflen');
		[ "resetting buffer to", ~buflen ].postln;
		~newbuffer = Buffer.alloc(s, s.sampleRate * ~buflen, 1);
		~granulator.set(\buffer, ~newbuffer);
		~bufrecorder.set(\buffer, ~newbuffer);
		if( ~frippbuffer.isNil.not, { ~frippbuffer.free });
		~frippbuffer = ~newbuffer;
		~playbacklfo.set(\speed, sp / ~buflen);
	});
});


~to.slider('/mix', 0.25, TouchOSCScale(0, 1),        { |v| ~bufrecorder.set(\mix, v) } );
~to.slider('/grainamp', 0.5, TouchOSCScale(0, 1),    { |v| ~granulator.set(\amp, v) } );
~to.slider('/passthrough', 0.5, TouchOSCScale(0, 1), { |v| ~mixer.set(\passthrough, v) } );

~to.slider('/feedback',  0, TouchOSCScale(0, 0.25), { |v|
	~bufrecorder.set(\feedback, v) } );

~to.button('/grains/bpm', "~", {});

~tapper = TapBeats();

~to.button('/grains/tap', 0, { | v, t |
	if( v > 0, {
		~tapper.tap(t);
		if( ~tapper.bpm.isNil.not, {
			~to.v_('/grains/bpm', ~tapper.bpm.round(1));
		})
	})
});

// note: ~buflen is the variable for buffer length, which only gets set to
// ~to.v('/grains/buflen') when the buffer is reset with the clear button

~to.slider('/grains/buflen', ~buflen, TouchOSCScale(0.1, 10.0), {});



~to.xy('/grains/speed', [ 1, 40 ], TouchOSCScale(0, 2), TouchOSCScale(0, 120), { | v |
	~playbacklfo.set(\speed, v[0] / ~buflen);
	~granulator.set(\trate, v[1] / ~buflen);
});

~to.button('/grains/mode', 0, { |v|
	var mode = ~modes[v];
	[ "trying to set mode to", v ].postln;
	[ "mode is ", mode].postln;
	mode.isNil.postln;
	if( mode.isNil.not, {
		~granulator.set(\posb, mode[1]);
		~playbacklfo = mode[0];
		~playbacklfo.set(\speed, ~to.v('/grains/speed')[0]);
	}, {
		[ "Bad mode index", v ].postln;
	});
});


// todo vvv quantise speed should be swappable

// var trate, qspeed;
// qspeed = 2.pow(v[0].floor);
// ~playbacklfo.set(\speed, qspeed / ~buflen);
// [ "speed", v[0], qspeed, qspeed / ~buflen ].postln;
// trate = 2.pow(v[1].floor) / ~buflen;
// ~granulator.set(\trate, trate);



~to.slider('/grains/size', 12, TouchOSCScale(0, 20),{ |v| ~granulator.set(\size, v) });

// Page 2: grainfx

~to.slider('/grainfx/blur',   0, TouchOSCScale(0, 1), { |v| ~granulator.set(\blur, v) });
~to.button('/grainfx/back',   1, { |v| ~granulator.set(\rate, if( v > 0, { -1 }, { 1}))});
~to.button('/grainfx/chorus', 0, { |v| ~granulator.set(\chorus, v) });
~to.button('/grainfx/dust',   0, { |v| ~granulator.set(\dust, v) });

// pitch gets quantised to octaves from 3 below to 3 above.
// NOTE: the pitch TouchOSC control is -1 to 1, not 0 to 1
// min/max gets ignored because I'm overloading the ctrlset/get

// TODO: fixme,

// ~to.slider('/grainfx/pitch', -1, 1, 1,
// 	{ |self| ~granulator.set("rate", self.v) },
// 	{ |self, ctrlv | self.v = 2.pow((ctrlv * 3).floor) },
// 	{ |self|         self.v.log2.floor / 3; }
// );



~to.slider('/fx/freq',  10000, TouchOSCScale(200, 10000), { |v| ~granulator.set(\freq, v) } );
~to.slider('/fx/rq',      0.3, TouchOSCScale(0.1, 1),     { |v| ~granulator.set(\res, v) } );
~to.slider('/fx/lfofreq',  0.5,TouchOSCScale(0.001, 4),   { |v| ~lfo.set(\freq, v) } );
~to.slider('/fx/lfoamp',  0,   TouchOSCScale(0, 1),       { |v| ~lfo.set(\amp, v) });
~to.slider('/fx/fuzz',    0,   TouchOSCScale(0, 1),       { |v| ~fuzzbox.set(\distort, v) });






)


