TODO
====

## Basic interface stuff

Write default settings to the interface on startup  <-- done

Try to get all the common interfaces on one page



## Musical

Test things like really rapid playback

Pitch-shifting (tuned and untuned)

LFO Modulate the filter <-- done

LFO Modulate the granulator settings

Separate panel for input effects: distort and overdrive

Sync timining of granule playback to buffer length / speed

Timing based on beat detection


## Advanced interface

Save current patch / load patch  <-- Done

Save the current buffer! - if this is incorporated with current settings, it's a way to save how the granulator is playing, and then resume. Which is good for live stuff and also for overdubbing

SuperCollider seems to have the ability to read and write files, but not scan directories, so the patch-saver will have to maintain its own index file

patch = file with settings, including a link to the buffer sample