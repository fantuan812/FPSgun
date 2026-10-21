import pathlib
P=pathlib.Path(__file__).resolve().parent
src=(P/'check_expansion.py').read_text().split("paths={'outer_loop'")[0].replace('[-.5,0,.5]','[-1,0,1]')
exec(src)
route('upper_2m_band',[(*p,6) for p in C['pedestrian_routes']['upper_link']])
(P/'bridge_2m_band.json').write_text(json.dumps(R,indent=2));print(len(R['routes']['upper_2m_band']['issues']))
