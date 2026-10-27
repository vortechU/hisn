"""Source/provenance guards for the Albanian content generator."""
import copy
import json
import unittest

from tool import gen_sq_dua_overlay as generator


class AlbanianGeneratorTest(unittest.TestCase):
    def test_checked_in_overlay_is_reproducible(self):
        expected = json.dumps(generator.generate(), ensure_ascii=False, indent=2) + '\n'
        actual = (generator.ROOT / 'assets/data/duas.sq.json').read_text(encoding='utf-8')
        self.assertEqual(actual, expected)

    def test_changed_base_requires_explicit_translation_review(self):
        original = json.loads((generator.ROOT / 'assets/data/duas.json').read_text(encoding='utf-8'))
        for field in ('translation', 'arabic', 'title', 'virtue', 'instruction'):
            changed = copy.deepcopy(original)
            row = next(row for row in changed if row.get(field))
            row[field] += ' changed'
            with self.subTest(field=field), self.assertRaisesRegex(ValueError, 'Review and update'):
                generator.generate(changed)

    def test_quran_excerpts_keep_exact_source_and_balanced_surrounding_quotes(self):
        rows = generator.generate()
        for dua_id in (
            'morning_hasbiyallah', 'forgiveness_rabbana_zalamna',
            'forgiveness_rabbanaghfirlana', 'distress_hasbunallah',
            'distress_musibah', 'travel_setting_off', 'travel_returning',
        ):
            text = rows[dua_id]['translation']
            with self.subTest(dua=dua_id):
                self.assertEqual(text.count('“'), text.count('”'))
                self.assertIn(generator.QURAN_CREDIT, rows[dua_id]['reference'])
        original = generator.quran(9, 129)
        suffix = original[original.index('Më mjafton mua Perëndia'):]
        self.assertIn(suffix, rows['morning_hasbiyallah']['translation'])
        self.assertIn(generator.quran(43, 14), rows['travel_setting_off']['translation'])

    def test_reference_translation_is_single_pass_and_preserves_the_grading(self):
        self.assertEqual(generator.reference('Sahih Muslim 591'), 'Sahihu i Muslimit 591')
        self.assertEqual(generator.reference('Sunan at-Tirmidhi 3391'), 'Suneni i Tirmidhiut 3391')
        self.assertEqual(generator.reference('Ibn Hibban (graded sahih by al-Albani)'),
                         'Ibn Hibban (vlerësuar sahih nga al-Albani)')


if __name__ == '__main__':
    unittest.main()
