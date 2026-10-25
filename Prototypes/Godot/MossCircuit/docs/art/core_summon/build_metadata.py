"""Measure the original PNG, never rewrite its pixels. Emit deterministic atlas metadata.

Usage: python build_metadata.py --project <project-or-patch-root> --output <outside-directory>
"""
from pathlib import Path
from PIL import Image
import argparse
import hashlib
import json

parser = argparse.ArgumentParser()
parser.add_argument('--project', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
root, output = args.project.resolve(), args.output.resolve()
if output == root or root in output.parents:
    parser.error('Keep analysis output outside the input project.')
output.mkdir(parents=True, exist_ok=True)
name = 'boss_core_summon'
relative = Path('assets/actions/boss_core') / (name + '.png')
png = root / relative
original = png.read_bytes()
im = Image.open(png)
assert im.mode == 'RGBA' and im.size == (1312, 1199)
alpha = im.getchannel('A')
mask = alpha.point(lambda value: 255 if value >= 8 else 0)
# Actual source is not square and not an equal 4x4 grid. Row gutters below
# leave all root tips intact; alpha must never select a neighboring pose.
xs = [[0, 328, 656, 984, 1312]] * 4
ys = [0, 320, 622, 910, 1199]
# Keep the upper-ring/orb registration fixed across rows, not the lowest root.
# Source armor tops are 44, 338, 639, 921: subtract layout row displacement.
row_baselines = [290, 584, 885, 1167]
row_translation = [320 - value for value in row_baselines]
canvas = [512, 400]
registration_x = -6
frames, facts = [], []
covered = 0
for i in range(16):
    row, column = divmod(i, 4)
    cell = (xs[row][column], ys[row], xs[row][column + 1], ys[row + 1])
    bounds = mask.crop(cell).getbbox()
    assert bounds, i
    x, y, right, bottom = (cell[0] + bounds[0], cell[1] + bounds[1],
                           cell[0] + bounds[2], cell[1] + bounds[3])
    # Four true source pixels of transparent guard; no destructive image edit.
    left_guard = min(4, x - cell[0])
    top_guard = min(4, y - cell[1])
    right_guard = min(4, cell[2] - right)
    bottom_guard = min(4, cell[3] - bottom)
    assert min(left_guard, top_guard, right_guard, bottom_guard) >= 1
    region = [x - left_guard, y - top_guard,
              right - x + left_guard + right_guard,
              bottom - y + top_guard + bottom_guard]
    center_x = im.width / 4 * (column + 0.5)
    dx = round(canvas[0] / 2 - center_x) + registration_x
    dy = row_translation[row]
    margin = [region[0] + dx, region[1] + dy,
              canvas[0] - region[2], canvas[1] - region[3]]
    box = [x + dx, y + dy, right - x, bottom - y]
    assert 0 <= margin[0] <= margin[2] and 0 <= margin[1] <= margin[3]
    clip_count = sum(value > 0 for value in mask.crop(cell).tobytes())
    covered += clip_count
    rec = {'region': region, 'margin': margin, 'alpha_bbox': box, 'source_pose_index': i}
    frames.append(rec)
    facts.append({'source_pose_index': i, 'source_partition': list(cell),
                  'source_alpha_bbox': [x, y, right - x, bottom - y],
                  'translation': [dx, dy], 'source_guard_ltrb': [left_guard, top_guard, right_guard, bottom_guard],
                  'logical_alpha_bbox': box, 'visible_bottom': bottom + dy,
                  'alpha_threshold_pixels': clip_count,
                  'pixel_sha256': hashlib.sha256(im.crop((x, y, right, bottom)).tobytes()).hexdigest()})
assert covered == sum(value > 0 for value in mask.tobytes())
assert len({fact['pixel_sha256'] for fact in facts}) == 16
assert png.read_bytes() == original
asset = {'path': 'res://' + str(relative), 'frames': frames,
         'anchor': [.5, .8], 'reference_height': facts[0]['source_alpha_bbox'][3],
         'release_frame': 7, 'loop': False, 'facing': 'left',
         'phase_frames': {'warning': [0, 6], 'attack': [7, 7], 'recover': [7, 15]},
         'source_sha256': hashlib.sha256(original).hexdigest(),
         'action_registration_offset_x': registration_x,
         'source_row_translation_y': row_translation,
         'source': 'Built-in image_gen; original PNG preserved, no resize/repaint/mask.'}
manifest = {'schema_version': 1, 'alpha_threshold': 8, 'actions': {name: asset}}
qa = {'name': name, 'size': list(im.size), 'mode': im.mode, 'bytes': len(original),
      'sha256': hashlib.sha256(original).hexdigest(),
      'git_blob_sha1': hashlib.sha1(f'blob {len(original)}\0'.encode() + original).hexdigest(),
      'frame_count': 16, 'unique_pose_hashes': 16, 'complete_threshold_alpha_coverage': True,
      'alpha_zero_pixels': alpha.tobytes().count(0), 'alpha_threshold_pixels': covered,
      'logical_canvas': canvas, 'fixed_anchor': [.5, .8], 'reference_height': asset['reference_height'],
      'source_pose_order': list(range(16)), 'source_row_baselines': row_baselines,
      'source_partition_x_by_row': xs, 'source_partition_y': ys,
      'logical_visible_bottom_trajectory': [fact['visible_bottom'] for fact in facts],
      'logical_upper_edge_trajectory': [fact['logical_alpha_bbox'][1] for fact in facts],
      'registration_policy': 'One constant X offset calibrated from neutral orb, one fixed source-row translation using upper armor/orb, NOT tail-bottom alignment. No per-frame scaling/recentering.',
      'frames': facts}
(output / 'attack_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
(output / 'source-analysis.json').write_text(json.dumps(qa, indent=2) + '\n')
print(json.dumps({key: qa[key] for key in ['sha256', 'frame_count', 'unique_pose_hashes', 'complete_threshold_alpha_coverage', 'logical_visible_bottom_trajectory']}, indent=2))
