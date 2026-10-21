# Pre-model design review v03

UTC review before final v03 model creation.

The v02 cargo eye-height preview and root visual review identified intermittent dark webbing at the shoulder. Only this local defect is changed: the existing cloth vertex positions are retained but explicit triangulation is fixed; each 74 mm-wide replacement band is clipped from the actual corresponding cloth triangles, not sampled from a separate analytic surface. Its supported base is 1 mm above that surface and its outward thickness is 6 mm. Side-to-crown gores use their own outward normals. No map layout, old geometry, ground levels, terminal positions, colours or lighting are changed.

Reviewed the regenerated same-scale front/right/top cargo reference and the region plans; the dark bands are continuous across the shoulder in the engineering views. All three module families and both region reference sets are regenerated from the v03 specification before modelling. V02 references remain immutable. Prior v02 model files are archived outside the deliverable tree and all target model paths are absent at freeze. The v02 independent static checks remain historical evidence; v03 will receive new static and same-camera visual checks.
