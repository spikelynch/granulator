// use server.record( ) and specify the bus to record with so I just get the granulator


// playback stuff

// play a count in and then the buffer





(


~infile = "/Users/mike/Music/SuperCollider Recordings/SC_211017_172706.aiff";


SynthDef("diskin", { |out, bufnum = 0|
    Out.ar(out, DiskIn.ar(2, bufnum));
}).add;

SynthDef(\tick, {
	arg out, freq=10000, atk=0.001, rel=0.4, amp=0.2;
	var env = EnvGen.kr(Env.perc(atk, rel), doneAction: Done.freeSelf);
	Out.ar(out, Pan2.ar(RLPF.ar(WhiteNoise.ar(amp), freq) * env, 0));
}).add;
)
(
r = Routine({
	var delta = 60 / ~bpm;
	s.prepareForRecord();
	b = Buffer.cueSoundFile(s, ~infile, 0, 2);
	(1..16).do({ |x| Synth(\tick, [\rel, 0.1 ]); delta.yield });
	s.record(bus: ~mixerb, numChannels: 2);
	x = { DiskIn.ar(2, b.bufnum) }.play;
});
)

r.play;


// save the buffer

~frippbuffer.write('/Users/mike/Music/SuperCollider Recordings/Grains/buf' ++ Date.getDate.stamp ++ '.aiff');


