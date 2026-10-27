"""Finite explicit dual-report contracts. No engine, no default permissive subset rule."""
import math

def classify(summary, full, policy):
    try:
        assert isinstance(summary, dict) and isinstance(full, dict)
        assert set(summary) == set(policy['summary_keys'])
        assert set(full) == set(policy['full_keys'])
        assert type(summary['checks']) is int and summary['checks'] == policy['checks']
        assert type(full['checks']) is int and full['checks'] == policy['checks']
        assert summary['failures'] == full['failures'] == []
        assert full['scope'] == policy['scope'] and isinstance(full['scope'], str)
        for key in policy['shared_keys']:
            assert summary[key] == full[key]
        for key, count in policy['collections'].items():
            assert isinstance(full[key], list) and len(full[key]) == count
            assert all(isinstance(value, dict) for value in full[key])
        for key, value in policy.get('exact_fields', {}).items():
            assert type(full[key]) is type(value) and full[key] == value
        if policy['kind'] == 'exact':
            assert summary == full
        elif policy['kind'] == 'mixer':
            assert type(summary['seconds']) in (float, int) and math.isfinite(summary['seconds']) and summary['seconds'] >= 0
            assert summary['seconds'] == full['seconds_since_ready']
            for key in ['master_gain_db', 'mix_rate', 'buffer_frames']:
                assert type(full[key]) in (int, float) and math.isfinite(full[key])
            assert full['mix_rate'] > 0 and full['buffer_frames'] > 0
            assert isinstance(full['engine'], dict) and len(full['engine']) == 9
            assert isinstance(full['node_gains'], dict) and len(full['node_gains']) == 2
            assert all(type(v) in (float, int) and math.isfinite(v) for v in full['node_gains'].values())
        else:
            assert policy['kind'] == 'summary_with_details'
        return {'accepted': True, 'error': None}
    except (AssertionError, KeyError, TypeError, ValueError, OverflowError) as exc:
        return {'accepted': False, 'error': type(exc).__name__}
