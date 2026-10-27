#!/usr/bin/env python3
"""Independent canonical RIFF/PCM/formula oracle. Read-only; no playback claim.
Usage: python independent_feedback_pcm.py PROJECT [OUTPUT_JSON]
"""
import hashlib, json, math, pathlib, struct, sys

SPEC = {
    'player_damage': (7056, 320.0, 140.0, .25, '34a9aa9fe8cab5273d2ea5199b127d303975df7ff088acce2441f14a922ec125', 'a738bbedcd3b01986f6cd4206303886002500b7589e5b27ee33c66deacd30118'),
    'shield_block': (5292, 720.0, 1080.0, .15, 'c4e21aa5500c8d4f01dd29c561e325a3f97173f103b29c1a291df54a6c8766f1', '7933a54e3ca54b14fc8286c3d8bfae3a8023e6a1351e2c4e9a20c3c57e3611cc'),
}
checks, failures = 0, []
def check(value, label):
    global checks
    checks += 1
    if not value: failures.append(label)
def digest(data): return hashlib.sha256(data).hexdigest()
def synthesize(n, low, high, weight):
    # This implementation does not call/import the production generator.
    envs, waves = [], []
    for i in range(n):
        seconds = i / 44100.0
        ramp_up, ramp_down = min(1., i/221.), min(1., (n-1-i)/662.)
        envelope = math.sin(math.pi*ramp_up/2)**2 * math.sin(math.pi*ramp_down/2)**2
        phase = 2*math.pi*(low*seconds+(high-low)*seconds*seconds/(2*((n-1)/44100.)))
        envs.append(envelope)
        waves.append(envelope*(math.sin(phase)+weight*math.sin(phase*2)))
    bias = sum(waves)/sum(envs)
    values = [wave-envelope*bias for wave,envelope in zip(waves,envs)]
    gain = .25/max(map(abs,values))
    integers = [max(-32768,min(32767,round(32767*x*gain))) for x in values]
    return struct.pack('<%dh'%n,*integers)
def main():
    project = pathlib.Path(sys.argv[1]); result = {'cues':{},'scope':'Independent source bytes/formula/quantized numeric bounds only. No imported engine/mixer/human listening/physical output claim.'}
    total = 0
    for cue, (n,f0,f1,weight,wav_hash,pcm_hash) in SPEC.items():
        data = (project/'assets/audio'/f'{cue}.wav').read_bytes(); total += len(data)
        check(digest(data)==wav_hash, cue+' exact canonical WAV')
        check(len(data)==44+2*n,cue+' minimal 44-byte header / no extra chunks')
        expected = (b'RIFF',36+n*2,b'WAVE',b'fmt ',16,1,1,44100,88200,2,16,b'data',n*2)
        check(struct.unpack('<4sI4s4sIHHIIHH4sI',data[:44])==expected,cue+' strict PCM format/header')
        pcm = data[44:]; ints = struct.unpack('<%dh'%n,pcm); values = [x/32768. for x in ints]
        check(digest(pcm)==pcm_hash,cue+' exact PCM')
        check(pcm==synthesize(n,f0,f1,weight),cue+' independent frozen formula reproduction')
        peak=max(map(abs,values)); rms=math.sqrt(sum(x*x for x in values)/n); mean=sum(values)/n
        check(all(math.isfinite(x) for x in values),cue+' finite decoded samples')
        check(peak<=.25,cue+' quantized peak <=0.25 under /32768')
        check(.02<=rms<=.18,cue+' RMS contract')
        check(abs(mean)<=.001,cue+' DC contract')
        check(ints[0]==ints[-1]==0,cue+' zero endpoints')
        check(any(x!=0 for x in ints),cue+' nonzero signal')
        meta=(project/'assets/audio'/f'{cue}.wav.import').read_text()
        for key,line in [('compression','compress/mode=0'),('rate','force/max_rate=false'),('8bit','force/8_bit=false'),('mono','force/mono=false'),('trim','edit/trim=false'),('normalize','edit/normalize=false'),('loop','edit/loop_mode=0')]:
            check(line in meta,cue+' import '+key)
        result['cues'][cue]={'bytes':len(data),'frames':n,'wav_sha256':digest(data),'pcm_sha256':digest(pcm),'peak':peak,'rms':rms,'mean':mean,'first':ints[0],'last':ints[-1]}
    check(total<=32768,'total canonical files <=32KiB')
    check(result['cues']['player_damage']['pcm_sha256']!=result['cues']['shield_block']['pcm_sha256'],'distinct original signals')
    result.update(checks=checks,failures=failures,total_bytes=total)
    text=json.dumps(result,indent=2,sort_keys=True)+'\n'
    if len(sys.argv)>2:pathlib.Path(sys.argv[2]).write_text(text)
    print(text,end='');return bool(failures)
if __name__=='__main__':sys.exit(main())
