

// Execute this before booting the server

Server.default.options.inDevice_("Scarlett 2i2 USB");


// 3c:06:30:16:c1:50  192.168.0.11

(

~bpm = 140;   // hack for buffer sync and recording
~buflen = 240 / ~bpm;

// IP address of whatever your TouchOSC surface is on - put here so it
// doesn't get lost;

~touchoscip = "192.168.0.2";




~touchosc = NetAddr(~touchoscip, 9000);

~patchdir = "~/Music/SuperCollider/Patches/granulator/";


// instrument settings

// ~sets is a dictionary with all of the settings
// ~mset adds a setting to ~sets
// a setting has a max, min, default, value, and an apply method
// apply takes the current v and applies it to the synth(s)
// converting between control values and real values is
// done in the touchOSC section, below


~sets = ();

// The following two functions are the default methods for going from
// touchOSC control settings (0-1) to setting values as defined by min,max.
// Default uses linlin - for linexp or fancier stuff, override them.
// It's up to you to make sure they're mathematically inverse.



~ctrlset = { | self, msg | self.v = msg[1].linlin(0, 1, self.min, self.max); };

~ctrlget = { | self |        self.v.linlin(self.min, self.max, 0, 1) };

~ctrlexpset = { | self, msg | self.v = msg[1].linexp(0, 1, self.min, self.max); };

~ctrlexpget = { | self |        self.v.linlin(self.min, self.max, 0, 1) };


// getter and setter for an x-y control - the default, max and min are arrays
// of [ x, y ] pairs

// note: msg is what we get from the OSC and x = 1, y = 2

~ctrlxyset = {
	| self, msg |
	self.v[0] = msg[1].linlin(0, 1, self.min[0], self.max[0]);
	self.v[1] = msg[2].linlin(0, 1, self.min[1], self.max[1]);
};

~ctrlxyget = {
	| self |
	var vals = [ 0, 0 ];
	vals[0] = self.v[0].linlin(self.min[0], self.max[0], 0, 1);
	vals[1] = self.v[1].linlin(self.min[1], self.max[1], 0, 1);
	vals;
};


// ~ctrlsend sends the current self.v back to the TouchOSC control,
// for when we send the defaults or load a patch

~ctrlsend = {
	| self |
	var ctrlval = self.ctrlget();
	[ "ctrlsend", self.oscurl, ctrlval ].postln;
	~touchosc.sendMsg(self.oscurl, ctrlval);
};

// TODO: each of these needs to be able to write its value back
// to its TouchOSC control - this should be a fairly simple
// method like ~ctrlset and ~ctrlget

// then call all of those on an iterator at startup to write the
// defaults to the controller

~mset = {
	| name, oscurl, min, max, default, apply=({}), ctrlset=(~ctrlset), ctrlget=(~ctrlget), ctrlsend=(~ctrlsend) |
	~sets.put(name, (
		name: name,
		oscurl: oscurl,
		default: default,
		min: min,
		max: max,
		v: default,
		ctrlset: ctrlset,
		ctrlget: ctrlget,
		ctrlsend: ctrlsend,
		apply: apply
	));
	OSCdef.new(
		'osc' ++ name,
		{ | msg |
			[ 'touchosc', msg ].postln;
			~sets.at(name).ctrlset(msg);
			~sets.at(name).apply() },
		oscurl
	);
};


// sidebar controls

~mset.value(\record,   '/record',   0,  1, 1, { |self| ~bufrecorder.set("record", self.v) });
~mset.value(\mix, '/mix',         0, 1, 0.25,    { |self| ~bufrecorder.set("mix", self.v) } );

// clear buffer is special so it gets its own OSCDef

OSCdef.new(
	\bufferclear,
	{
		| msg |
		var bl = ~sets.at(\buflength).v, sp = ~sets.at(\grainrate).v[0];
		bl = ~buflen;
		~bufclear = msg[1];
		~newbuffer = Buffer.alloc(s, s.sampleRate * bl, 1);
		~granulator.set("buffer", ~newbuffer);
		~bufrecorder.set("buffer", ~newbuffer);
		~frippbuffer.free;
		~frippbuffer = ~newbuffer;
		~currentpos.set("speed", sp / bl);
	},
	'/clear'
);

~mset.value(\grainamp,     '/gain',      0, 1, 0.5,     { |self| ~granulator.set("amp", self.v) } );
~mset.value(\passthrough,  '/passthrough', 0, 1, 0.5,     { |self| ~mixer.set("passthrough", self.v) } );

// page 1: grains

// special setter for the granulator mode buttond
~setmode = {
	| value, test, ctrlsynth, ctrlbus |
	if( value > 0.0, {
		[ "setmode", test ].postln;
		~granulator.set("posb", ctrlbus);
		~currentpos = ctrlsynth;
		~currentpos.set("speed", ~sets.at(\speed).v);
	});
};


~mset.value(\modesaw,     '/grains/mode/5/1', 0, 1, 1, { |self| ~setmode.value(self.v, "saw", ~grainsaw, ~grainsawb) } );
~mset.value(\modereverse, '/grains/mode/4/1', 0, 1, 0, { |self| ~setmode.value(self.v, "reverse", ~grainreverse, ~grainreverseb) } );
~mset.value(\modesine,    '/grains/mode/3/1', 0, 1, 0, { |self| ~setmode.value(self.v, "sin", ~grainsin, ~grainsinb) } );
~mset.value(\modetri,     '/grains/mode/2/1', 0, 1, 0, { |self| ~setmode.value(self.v, "tri", ~graintri, ~graintrib) } );
~mset.value(\moderand,    '/grains/mode/1/1', 0, 1, 0, { |self| ~setmode.value(self.v, "rand", ~grainrand, ~grainrandb) } );


~mset.value(\buflength,    '/grains/length', 0.1, 10, 4.0);

// ~mset.value(\trigger,      '/grains/trigger', 0, 10, 4, {
// 	|self|
// 	var trate = 2.pow(self.v.floor) / ~buflen;
// 	trate.postln;
// 	~granulator.set("trate", trate)
// });
// ~mset.value(\speed,        '/grains/speed',   -4, 4, 0, {
// 	|self|
// 	var qspeed = 2.pow(self.v.floor);
// 	qspeed.postln;
// 	~currentpos.set("speed", qspeed / ~buflen)
// });

~mset.value(\grainrate,   '/grains/rate',  [ -4, 0 ], [  4, 10 ], [ 0, 4 ], {
	| self |
	var trate, qspeed;
	qspeed = 2.pow(self.v[0].floor);
 	qspeed.postln;
 	~currentpos.set("speed", qspeed / ~buflen)
	[ "grainrate", self.v ].postln;
	trate = 2.pow(self.v[1].floor) / ~buflen;
 	trate.postln;
	~granulator.set("trate", trate);

}, ~ctrlxyset, ~ctrlxyget);

~mset.value(\size,         '/grains/size', 0, 20, 12, { |self| ~granulator.set("size", self.v) });


// Page 2: grainfx

~mset.value(\blur,         '/grainfx/blur', 0, 1.0, 0, { |self| ~granulator.set("blur", self.v) });


~mset.value(\back,   '/grainfx/back',   1, -1, 0, { |self| ~granulator.set("rate", self.v) });
~mset.value(\chorus, '/grainfx/chorus', 0,  1, 0, { |self| ~granulator.set("chorus", self.v) });
~mset.value(\dust,   '/grainfx/dust',   0,  1, 0, { |self| ~granulator.set("dust", self.v) });


// pitch gets quantised to octaves from 3 below to 3 above.
// NOTE: the pitch TouchOSC control is -1 to 1, not 0 to 1
// min/max gets ignored because I'm overloading the ctrlset/get

// TODO: fixme,

~mset.value(\pitch, '/grainfx/pitch', -1, 1, 1,
	{ |self| ~granulator.set("rate", self.v) },
	{ |self, ctrlv | self.v = 2.pow((ctrlv * 3).floor) },
	{ |self|         self.v.log2.floor / 3; }
);



~mset.value(\feedback,     '/fx/feedback',    0, 0.25, 0,    { |self| ~bufrecorder.set("feedback", self.v) } );
~mset.value(\filterfreq,   '/fx/freq',        200, 10000, 10000, { |self| ~granulator.set("freq", self.v) } );
~mset.value(\filterres,    '/fx/rq',         0.1, 1, 0.3,        { |self| ~granulator.set("res", self.v) } );
~mset.value(\lfofreq,      '/fx/lfofreq',  0.001, 1, 0.5,        { |self| ~lfo.set("freq", self.v) } );
~mset.value(\lfoamp,       '/fx/lfoamp',  0,   1, 0,             { |self| ~lfo.set("amp", self.v) });

~mset.value(\fuzz,         '/fx/fuzz',  1000,   6000, 6000,             { |self| self.v.postln });


// send defaults of the normal settings to the controller

~sets.do({|s|
	[ "control send for", s.name ].postln;
	s.ctrlsend()
});







// Now the actual sound synthesis part


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

~infilter = SynthDef(
	\input_null,
	{
		arg in = 2, out = 4;
		Out.ar(out, In.ar(in));
	}
).play(s, [\in, ~usbinput, \out, ~recordb]);


// ~fuzzbox = SynthDef(
// 	\fuzzbox,
// 	{
// 		arg in=2, out=4, distort=0.1, decay=0.999;
// 		var raw, cross, pf;
// 		raw = In.ar(in, 1).softclip;
// 		cross = CrossoverDistortion.ar(raw, 0.5, 0.5);
// 		pf = PeakFollower.ar(raw, decay);
// 		Out.ar(out, ((1 - distort) * raw) + (distort * pf * cross));
// 	}
// ).play(s, [\in, ~usbinput, \out, ~recordb, \distort, 0 ]);


// ~decimator = SynthDef(
// 	\decimator,
// 	{
// 		arg in=2, out=4, modb, rate=10000, smooth=0.5;
// 		var raw, mod, decimated;
// 		raw = In.ar(in, 1);
// 		mod = In.kr(modb, 1);
// 		decimated = SmoothDecimator.ar(raw, rate + (0.2 * rate * mod), smooth);
// 		Out.ar(out, decimated);
// 	}
// ).play(s, [\in, ~usbinput, \out, ~recordb, \modb, ~lfob, \rate, 10000 ]);


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




// buffer recorder

~frippbuffer = Buffer.alloc(s, s.sampleRate * ~sets.at(\buflength).v, 1);

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



// granulator playback modes
// each of these is a control bus with a synth that drives the pattern
// the granulator mode control switches between them

// more ideas for modules: scramble - do a permutation of ABCDEFGH slots


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
	\grainsin,
	{
		arg out=5, speed=1;
		Out.kr(out, 0.5 + WhiteNoise.kr(0.5));
	}
).play(s, [\out, ~grainrandb, \speed, 1]);



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


//

~monitor = SynthDef(
	\monitor_synth,
	{
		arg in=2, out=0;
		Out.ar(out, In.ar(in, 2))
	}
).play(s, [\in, ~mixerb, \out, 0 ], \addToTail);


// controls for saving and loading patches




~savepatch = {
	| name |
 	var fname = ~patchdir ++ name ++ '.txt', fhandle;
	fhandle = File(fname.standardizePath, "w");
	~sets.do({
		|set|
		fhandle.write(set.name ++ "," ++ set.v ++ "\n");
	});
	fhandle.close;
	[ "Wrote patch to", fname ].postln;
 };

// note: fname is a PathName because that's what comes back from
// the patch menu widget

~loadpatch = {
	| fname |
 	var vals;

	[ "Loading patch from", fname ].postln;

	vals = CSVFileReader.read(fname.fullPath, true, true);

	vals.do({
		| val |
		var sn = val[0].asSymbol;
		if(~sets.includesKey(sn),
			{
				var set = ~sets.at(sn);
				set.v = val[1].asFloat;
				set.ctrlsend();
			},
			{[ "Unknown patch setting", val[0] ].postln; }
		);
	});
};



// controls for naming and saving patches

~alphabet = "_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

~cursor = "|";

~curpos = 0;
~curlet = 0;

~nametext = List.new(0);

// this takes a string and inserts a '|' at a position
// seems to take a lot to do this in sclang

~substr = {
	| str, l, start=0 |
	String.newFrom(str[start + Array.iota(l)]);
};

~putcursor = {
	| str, i |
	var front, back;
	if( i > 0,
		{ if( i <= str.size, {
			front = ~substr.value(str, i);
			back = ~substr.value(str, str.size - i, i);
			front ++ ~cursor ++ back;
		}, { str ++ ~cursor }) },
		{ ~cursor ++ str }
	);
};

~sendSave = {
	| text, pos |
	var str = String.newFrom(text.asArray), sendText = ~putcursor.value(str, pos);
	~touchosc.sendMsg('/patch/saveName', sendText);
};


~sendSave.value(~nametext, ~curpos);

~movecursor = {
	| dir |
	~curpos = ~curpos + dir;
	~curpos = if( ~curpos < 0, { 0 }, { ~curpos });
	~curpos = if( ~curpos > ~nametext.size, {
		~nametext.add(~alphabet.at(0));
		~curpos;
	}, { ~curpos });
	~sendSave.value(~nametext, ~curpos);
};

~backspace = {
	if( (~curpos > 0) && (~nametext.size > 0), {
		~nametext.removeAt(~curpos - 1);
		~curpos = ~curpos - 1;
		~sendSave.value(~nametext, ~curpos);
	});
};

~changelet = {
	| dir |
	var i, asize = ~alphabet.size - 1;
	if( ~curpos > 0, {
		i = ~alphabet.find(~nametext.at(~curpos - 1));
		i = if( dir < 0, { i - 1 }, { i + 1 });
		i = if( i < 0, { asize }, { i });
		i = if( i > asize, { 0 }, { i });
		~nametext.put(~curpos - 1, ~alphabet.at(i));
		~sendSave.value(~nametext, ~curpos);
	});
};

OSCdef.new(\patchsavel, { ~movecursor.value(-1) }, '/patch/saveL');
OSCdef.new(\patchsaver, { ~movecursor.value(1) }, '/patch/saveR');

OSCdef.new(\patchsaved, { ~changelet.value(-1) }, '/patch/saveD');
OSCdef.new(\patchsaveu, { ~changelet.value(1) }, '/patch/saveU');

OSCdef.new(\patchbacks, { ~backspace.value() }, '/patch/backspace');

OSCdef.new(\patchsave,  {
	if( ~nametext.size > 0, {
		~savepatch.value(String.newFrom(~nametext.asArray));
		~patchmenu = PathName.new(~patchdir).files;
	})
}, '/patch/save');


// controls for loading patches

~sendLoad = {
	| menu, pos |
	var str = menu.at(pos).fileNameWithoutExtension;
	~touchosc.sendMsg('/patch/loadName', str);
};

~patchmenu = PathName.new(~patchdir).files;

[ "loaded patches", ~patchmenu ].postln;

~patchmenupos = 0;

~sendLoad.value(~patchmenu, ~patchmenupos);

~menuMove = {
	| dir |
	~patchmenupos = ~patchmenupos + dir;
	~patchmenupos = if( ~patchmenupos < 0, { ~patchmenu.size - 1 }, { ~patchmenupos });
	~patchmenupos = if( ~patchmenupos > (~patchmenu.size - 1), { 0 }, { ~patchmenupos });
	~sendLoad.value(~patchmenu, ~patchmenupos);
};

OSCdef.new(\patchloadd, { ~menuMove.value(1); }, '/patch/loadD');
OSCdef.new(\patchloadu, { ~menuMove.value(-1); }, '/patch/loadU');

OSCdef.new(\patchload, {
	if( ~patchmenu.size > 0, {
		~loadpatch.value(~patchmenu.at(~patchmenupos));
		~nametext = ~patchmenu.at(~patchmenupos).fileNameWithoutExtension;
		~curpos = 0;
		~sendsave.value(~nametext, ~curpos);

	});
}, '/patch/load');

)


