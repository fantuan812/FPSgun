#!/usr/bin/env python3
"""Original editable geometry, not image tracing. Rebuilds the seven SVG sources."""
from pathlib import Path
ROOT=Path(__file__).resolve().parent
PAL={'ink':'#202832','shade':'#39434c','moss':'#647540','mosslight':'#91a45a','cream':'#d9d1ac','light':'#f5ebca','copper':'#b87546','copperlight':'#e8ac70','cyan':'#78e3e6','cyandark':'#2a929b','amber':'#e8b35a','amberdark':'#ae7136'}
class Art:
 def __init__(self,name,w,h): self.name=name;self.w=w;self.h=h;self.s=[]
 def group(self,name): self.s.append(f'<g id="{name}">')
 def end(self): self.s.append('</g>')
 def rect(self,x,y,w,h,c): self.s.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{PAL[c]}" data-palette="{c}"/>')
 def poly(self,pts,c): self.s.append(f'<polygon points="{pts}" fill="{PAL[c]}" data-palette="{c}"/>')
 def oct(self,x,y,w,h,c,cut=3): self.poly(f'{x+cut},{y} {x+w-cut},{y} {x+w-cut},{y+cut} {x+w},{y+cut} {x+w},{y+h-cut} {x+w-cut},{y+h-cut} {x+w-cut},{y+h} {x+cut},{y+h} {x+cut},{y+h-cut} {x},{y+h-cut} {x},{y+cut} {x+cut},{y+cut}',c)
 def bolt(self,x,y): self.rect(x,y,4,4,'ink'); self.rect(x+1,y+1,2,2,'copperlight')
 def save(self):
  p=ROOT/'svg'/f'{self.name}.svg';p.parent.mkdir(exist_ok=True)
  p.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" viewBox="0 0 {self.w} {self.h}" shape-rendering="crispEdges" role="img"><title>{self.name.replace("_"," ")}</title><desc>Original editable MossCircuit pixel geometry. No embedded raster. Palette tags are editable.</desc>'+''.join(self.s)+'</svg>\n')

def tether():
 a=Art('tether_emitter_held',128,64)
 a.group('grip-and-trigger');a.poly('26,32 42,32 42,40 36,40 32,57 20,57 20,53', 'ink');a.poly('27,37 35,39 29,53 23,53','shade');a.rect(25,43,7,3,'moss');a.rect(23,49,7,3,'mosslight');a.oct(38,31,17,15,'ink',2);a.rect(41,35,10,7,'copper');a.rect(44,35,7,5,'ink');a.end()
 a.group('power-core');a.oct(14,18,48,22,'ink',4);a.oct(17,21,42,16,'moss',3);a.rect(21,21,32,4,'cream');a.rect(22,25,14,9,'cream');a.rect(24,25,7,2,'light');a.rect(36,28,21,7,'shade');a.rect(39,30,14,3,'cyan');a.rect(12,25,5,8,'copper');a.bolt(18,31);a.bolt(54,23);a.end()
 a.group('four-beat-indicators');a.rect(31,14,29,8,'ink')
 for x in [33,40,47,54]: a.rect(x,16,4,4,'cyan');a.rect(x,16,2,1,'light')
 a.end();a.group('forked-emitter');a.rect(60,25,30,10,'ink');a.rect(62,27,23,3,'copper');a.rect(66,30,19,3,'shade');a.poly('84,21 111,21 111,19 119,19 119,29 109,29 109,31 84,31','ink');a.poly('84,34 109,34 109,36 119,36 119,46 111,46 111,44 84,44','ink');a.rect(87,23,28,4,'cream');a.rect(91,27,25,2,'cyan');a.rect(87,38,28,4,'cream');a.rect(91,36,25,2,'cyan');a.rect(86,23,4,5,'moss');a.rect(86,37,4,5,'moss');a.rect(79,25,5,10,'moss');a.end();a.save()

def drum():
 a=Art('seismic_drum_held',128,64)
 a.group('grip-and-brace');a.poly('28,32 45,32 40,43 34,57 20,57 20,53','ink');a.poly('30,37 37,39 30,53 24,53','moss');a.rect(26,46,7,3,'cream');a.poly('43,36 50,36 56,44 81,44 81,50 53,50 43,42','ink');a.poly('46,37 49,37 56,46 78,46 78,48 55,48 46,41','cream');a.end()
 a.group('short-resonator-body');a.oct(15,22,48,20,'ink',3);a.oct(18,25,38,14,'moss',2);a.rect(23,25,25,6,'cream');a.rect(25,25,18,2,'light');a.rect(25,34,20,3,'shade');a.rect(56,26,15,12,'ink');a.rect(59,28,10,8,'copper');a.bolt(18,33);a.bolt(49,25);a.rect(32,18,24,5,'ink');a.rect(35,19,18,3,'copperlight');a.end()
 a.group('drum-casing');a.oct(68,8,43,47,'ink',9);a.oct(71,11,36,41,'moss',7);a.rect(72,22,4,20,'mosslight');a.oct(79,7,38,49,'ink',8);a.oct(82,10,32,43,'cream',7);a.oct(87,13,26,37,'copper',6);a.oct(90,16,20,31,'ink',5);a.end()
 a.group('amber-diaphragm');a.oct(92,18,16,27,'amberdark',4);a.oct(94,20,12,23,'amber',3);a.rect(96,24,4,14,'light');a.rect(100,27,3,13,'copperlight');a.bolt(84,16);a.bolt(83,44);a.end();a.save()

def tether_icon():
 a=Art('tether_emitter_icon',64,64);a.group('three-quarter-grip');a.poly('24,34 35,38 29,55 19,51','ink');a.poly('25,39 30,41 26,50 22,48','moss');a.end();a.group('body');a.poly('7,26 15,18 36,24 42,34 33,44 10,36','ink');a.poly('11,27 17,22 33,27 36,34 30,39 13,33','cream');a.poly('17,22 34,26 36,30 20,27','light');a.poly('11,28 18,30 18,35 13,33','moss');a.bolt(22,31);a.end();a.group('four-beat-panel')
 for i in range(4): a.rect(17+i*5,18+i,4,5,'ink');a.rect(18+i*5,19+i,2,2,'cyan')
 a.end();a.group('forked-muzzle');a.poly('33,26 50,12 59,15 59,22 42,36 37,32','ink');a.poly('37,28 51,16 55,17 40,31','cream');a.poly('40,31 55,19 56,21 42,33','cyan');a.poly('40,37 55,26 61,28 61,35 47,46 40,43','ink');a.poly('44,38 56,29 58,30 47,40','cyan');a.poly('44,41 58,32 58,34 47,43','cream');a.end();a.save()

def drum_icon():
 a=Art('seismic_drum_icon',64,64);a.group('rear-body-and-grip');a.poly('7,25 20,17 36,25 34,42 25,45 20,57 10,54 14,42 6,37','ink');a.poly('10,27 20,21 30,26 28,38 17,39 10,34','moss');a.rect(12,26,13,5,'cream');a.rect(15,44,8,8,'moss');a.rect(16,47,5,2,'cream');a.end();a.group('thick-drum-rim');a.oct(22,8,36,45,'ink',8);a.oct(25,11,30,39,'cream',7);a.oct(29,14,24,33,'copper',6);a.oct(32,17,18,27,'ink',4);a.end();a.group('membrane');a.oct(34,19,14,23,'amber',4);a.rect(37,23,4,13,'light');a.rect(41,27,4,12,'amberdark');a.bolt(25,17);a.bolt(26,40);a.end();a.save()

def memory():
 a=Art('lock_memory',64,64);a.group('circuit-board');a.oct(12,10,40,42,'ink',4);a.oct(15,13,34,36,'moss',3);a.rect(19,17,26,26,'shade');a.rect(22,20,20,20,'ink');a.rect(27,25,10,10,'cyandark');a.rect(29,27,6,6,'cyan');a.end();a.group('retention-brackets');a.poly('20,18 29,18 29,21 23,21 23,27 20,27','cyan');a.poly('35,39 44,39 44,30 41,30 41,36 35,36','cyan');a.rect(18,33,3,10,'cream');a.rect(22,42,11,3,'cream');a.rect(37,15,9,3,'copper');a.end();a.group('four-contacts')
 for x in [19,26,33,40]: a.rect(x,49,5,8,'ink');a.rect(x+1,49,3,6,'copperlight')
 a.bolt(14,12);a.bolt(46,44);a.end();a.save()

def collar():
 a=Art('return_collar',64,64);a.group('split-collar');a.poly('23,8 41,8 41,12 49,12 49,20 55,20 55,43 49,43 49,51 41,51 41,55 23,55 23,51 15,51 15,43 9,43 9,20 15,20 15,12 23,12 23,8 27,16 21,19 17,25 17,39 22,46 28,48 37,48 44,44 47,38 47,26 42,20 36,16 27,16','ink');a.poly('24,11 40,11 40,15 47,15 47,22 52,22 52,41 46,41 46,48 39,48 39,52 24,52 24,48 18,48 18,40 12,40 12,23 18,23 18,16 24,16 24,11 28,19 23,22 20,27 20,37 24,43 29,45 36,45 41,42 44,36 44,27 39,22 35,19 28,19','copper');a.end();a.group('opposing-mechanical-fins');a.poly('12,13 26,13 26,9 35,18 26,27 26,22 12,22','ink');a.poly('16,16 28,16 28,14 31,18 28,21 28,19 16,19','cream');a.poly('52,51 38,51 38,55 29,46 38,37 38,42 52,42','ink');a.poly('48,45 36,45 36,42 33,46 36,50 36,48 48,48','cream');a.rect(16,28,3,10,'amber');a.rect(45,26,3,10,'amber');a.bolt(43,17);a.bolt(17,43);a.end();a.save()

def plate():
 a=Art('recoil_plate',64,64);a.group('outward-braces');a.poly('6,26 18,17 18,25 24,25 24,39 18,39 18,47 6,38','ink');a.poly('9,27 15,23 15,29 21,29 21,35 15,35 15,41 9,37','copper');a.poly('58,26 46,17 46,25 40,25 40,39 46,39 46,47 58,38','ink');a.poly('55,27 49,23 49,29 43,29 43,35 49,35 49,41 55,37','copper');a.end();a.group('armored-plate');a.poly('20,9 44,9 44,14 49,14 49,45 43,45 43,52 32,57 21,52 21,45 15,45 15,14 20,14','ink');a.poly('23,12 41,12 41,17 46,17 46,41 40,41 40,49 32,53 24,49 24,41 18,41 18,17 23,17','moss');a.rect(23,15,18,6,'cream');a.rect(25,15,12,2,'light');a.poly('22,39 27,39 27,46 32,49 37,46 37,39 42,39 42,48 32,54 22,48','mosslight');a.end();a.group('spring-piston');a.rect(21,24,22,14,'ink');a.rect(23,28,18,6,'copper');a.rect(24,26,3,10,'copperlight');a.rect(30,26,3,10,'cream');a.rect(36,26,3,10,'copperlight');a.bolt(19,18);a.bolt(41,18);a.end();a.save()
if __name__ == '__main__':
 for f in [tether,drum,tether_icon,drum_icon,memory,collar,plate]: f()
 print('Built seven original SVG sources')
