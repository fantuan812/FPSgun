
import math,numpy as np
CUBE_FACES=[[0,3,2,1],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]]
def meshpart(p):
 t=p['type']
 if t=='mesh':return np.array(p['verts'],float),p['faces']
 if t=='box':
  x,y,z=p['d'];v=np.array([[-x,-y,-z],[x,-y,-z],[x,y,-z],[-x,y,-z],[-x,-y,z],[x,-y,z],[x,y,z],[-x,y,z]],float)/2
  a=math.radians(p.get('rz',0));rot=np.array([[math.cos(a),-math.sin(a),0],[math.sin(a),math.cos(a),0],[0,0,1]]);return v@rot.T+np.array(p['p']),CUBE_FACES
 if t=='beam':
  a,b=np.array(p['a']),np.array(p['b']);z=b-a;length=np.linalg.norm(z);z=z/length;x=np.cross(z,[0,1,0]);
  if np.linalg.norm(x)<1e-6:x=np.cross(z,[1,0,0])
  x=x/np.linalg.norm(x);y=np.cross(z,x);q={'type':'box','d':[p['width'],p['width'],length],'p':[0,0,0]};v,f=meshpart(q);return v@np.array([x,y,z])+(a+b)/2,f
 if t=='cylinder':
  n=p.get('segments',16);r=p['r'];l=p['l'];v=[]
  for z in [-l/2,l/2]:
   for i in range(n):v.append([r*math.cos(i*2*math.pi/n),r*math.sin(i*2*math.pi/n),z])
  v=np.array(v)
  if p.get('axis','Z')=='X':v=v[:,[2,0,1]]
  if p.get('axis','Z')=='Y':v=v[:,[0,2,1]]
  f=[list(range(n-1,-1,-1)),list(range(n,2*n))]+[[i,(i+1)%n,(i+1)%n+n,i+n] for i in range(n)]
  return v+np.array(p['p']),f
 if t=='tube':
  pts=np.array(p['points']);n=p.get('segments',12);v=[]
  for i,c in enumerate(pts):
   tangent=pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)];tangent/=np.linalg.norm(tangent);u=np.cross(tangent,[0,1,0]);u/=np.linalg.norm(u);w=np.cross(tangent,u)
   for k in range(n):v.append(c+p['r']*(math.cos(k*2*math.pi/n)*u+math.sin(k*2*math.pi/n)*w))
  f=[[i*n+k,i*n+(k+1)%n,(i+1)*n+(k+1)%n,(i+1)*n+k] for i in range(len(pts)-1) for k in range(n)]
  return np.array(v),f
 raise ValueError(t)
def transform(v,pos,rz):
 a=math.radians(rz);rot=np.array([[math.cos(a),-math.sin(a),0],[math.sin(a),math.cos(a),0],[0,0,1]])
 return v@rot.T+np.array(pos)
