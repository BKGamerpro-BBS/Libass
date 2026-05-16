"""
LIBASS TestingAgent -- Automated QA for the Multi-Agent Pipeline
Run: python test_agents.py
"""
import json
import sys
import os
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from ai_engine import VisionAgent, StyleRaterAgent, ImprovementAgent, OrchestratorAgent, classify_body_shape


def test_body_shape_classifier():
    print("--- Test: Body Shape Classifier ---")
    cases = [
        (90, 75, 70, 90, "hourglass"),
        (80, 70, 75, 100, "pear"),
        (110, 85, 80, 85, "inverted_triangle"),
        (90, 90, 90, 90, "rectangle"),
        (85, 80, 95, 85, "apple"),
    ]
    passed = 0
    for chest, hw, waist, hip, expected in cases:
        result = classify_body_shape(chest, hw, waist, hip)
        status = "PASS" if result == expected else "FAIL"
        if result == expected: passed += 1
        print(f"  [{status}] chest={chest}, waist={waist}, hip={hip} -> {result} (expected: {expected})")
    print(f"  {passed}/{len(cases)} passed\n")
    return passed == len(cases)


def test_style_rater():
    print("--- Test: StyleRaterAgent ---")
    combo = [
        {"id": "1", "name": "White Shirt", "category": "top", "color": "white", "pattern": "solid", "fit": "slim"},
        {"id": "2", "name": "Dark Jeans", "category": "bottom", "color": "blue", "pattern": "solid", "fit": "regular"}
    ]
    score, reasoning = StyleRaterAgent.rate(combo, 'summer', 'casual')
    ok = 1 <= score <= 10 and len(reasoning) > 0
    print(f"  [{'PASS' if ok else 'FAIL'}] Score: {score}/10 -- {reasoning}")

    clash_combo = [
        {"id": "3", "name": "Plaid Shirt", "category": "top", "color": "red", "pattern": "plaid", "fit": "regular"},
        {"id": "4", "name": "Striped Pants", "category": "bottom", "color": "navy", "pattern": "striped", "fit": "regular"}
    ]
    score2, reasoning2 = StyleRaterAgent.rate(clash_combo, 'summer', 'casual')
    print(f"  [{'PASS' if score2 < score else 'FAIL'}] Clash test: {score2}/10 (should be lower than {score})")
    print()
    return ok


def test_improvement_agent():
    print("--- Test: ImprovementAgent ---")
    combo = [
        {"id": "1", "name": "Black Shirt", "category": "top", "color": "black", "pattern": "solid", "fit": "slim"},
        {"id": "2", "name": "Black Pants", "category": "bottom", "color": "black", "pattern": "solid", "fit": "slim"}
    ]
    suggestions = ImprovementAgent.suggest(combo, 6.0)
    ok = len(suggestions) > 0 and all('title' in s and 'detail' in s for s in suggestions)
    for s in suggestions:
        print(f"  [TIP] {s['title']}: {s['detail']}")
    print(f"  [{'PASS' if ok else 'FAIL'}] Got {len(suggestions)} suggestions\n")
    return ok


def test_orchestrator():
    print("--- Test: OrchestratorAgent (Full Pipeline) ---")
    profile = {"body_shape": "rectangle"}
    wardrobe = [
        {"id": "a", "image_path": "/uploads/a.png", "name": "Tee", "category": "top", "color": "white", "pattern": "solid", "fit": "regular"},
        {"id": "b", "image_path": "/uploads/b.png", "name": "Jeans", "category": "bottom", "color": "blue", "pattern": "solid", "fit": "slim"},
        {"id": "c", "image_path": "/uploads/c.png", "name": "Blazer", "category": "top", "color": "navy", "pattern": "solid", "fit": "slim"},
    ]
    results = OrchestratorAgent.generate_suggestions(profile, wardrobe, {}, 'summer', 'casual')
    ok = len(results) > 0 and all('body_shape_score' in r for r in results)
    for r in results[:3]:
        items = ", ".join([i['name'] for i in r['items']])
        print(f"  [HIT] [{r['body_shape_score']}/10] {items} -- {r['reasoning'][:60]}...")
    print(f"  [{'PASS' if ok else 'FAIL'}] Generated {len(results)} suggestions\n")
    return ok


def test_input_validation():
    print("--- Test: Input Validation ---")
    cases = [
        (None, 70, 65, 90, None),
        ("abc", 70, 65, 90, None),
        (10, 70, 65, 90, None),
        (300, 70, 65, 90, None),
    ]
    passed = 0
    for chest, hw, waist, hip, expected in cases:
        result = classify_body_shape(chest, hw, waist, hip)
        ok = result == expected
        if ok: passed += 1
        print(f"  [{'PASS' if ok else 'FAIL'}] classify({chest}, {hw}, {waist}, {hip}) -> {result}")
    print(f"  {passed}/{len(cases)} passed\n")
    return passed == len(cases)


if __name__ == '__main__':
    print("=" * 43)
    print("  LIBASS TestingAgent -- Automated QA Suite")
    print("=" * 43 + "\n")

    results = [
        test_body_shape_classifier(),
        test_style_rater(),
        test_improvement_agent(),
        test_orchestrator(),
        test_input_validation(),
    ]

    total = len(results)
    passed = sum(results)
    print("=" * 43)
    print(f"  RESULTS: {passed}/{total} test suites passed")
    if passed == total:
        print("  All tests PASSED -- Ready for manual testing!")
    else:
        print("  Some tests FAILED -- Review output above.")
    print("=" * 43)
    sys.exit(0 if passed == total else 1)
