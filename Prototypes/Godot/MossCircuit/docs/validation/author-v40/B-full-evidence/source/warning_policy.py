"""Exact known legacy warning exception; never removes or rewrites stored stderr."""
def classify(stderr, policy):
    if policy is None:
        return {'accepted': stderr == b'', 'warning_count': 0}
    expected = policy['block'].encode('utf-8') * policy['count']
    accepted = type(policy['count']) is int and policy['count'] == 48 and stderr == expected
    return {'accepted': accepted, 'warning_count': 48 if accepted else 0}
