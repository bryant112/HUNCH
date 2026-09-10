"""Packaging and evidence-tool failure cases, not a second implementation of perception."""
import contextlib
import io
from pathlib import Path
import struct
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from build import ROOT, guard, read_pbo, texture
import analyze_benchmark

class ToolTests(unittest.TestCase):
    def test_guard_rejects_external_destination(self):
        with self.assertRaises(ValueError): guard(ROOT.parent/'another-project')

    def test_truncated_pbo_rejected(self):
        with tempfile.TemporaryDirectory(dir=guard(ROOT/'build')) as tmp:
            path=Path(tmp)/'bad.pbo'; path.write_bytes(b'broken')
            with self.assertRaises(ValueError): read_pbo(path)

    def test_original_mask_has_transparent_edge(self):
        with tempfile.TemporaryDirectory(dir=guard(ROOT/'build')) as tmp:
            path=Path(tmp)/'mask.tga'; texture(path)
            data=path.read_bytes()
            self.assertEqual(len(data),18+256*256*4)
            self.assertEqual(data[18+3],0)
            self.assertGreater(data[18+(128*256+128)*4+3],250)

    def test_benchmark_missing_pairs_cannot_pass(self):
        with tempfile.TemporaryDirectory(dir=guard(ROOT/'build')) as tmp:
            path=Path(tmp)/'empty.rpt'; path.write_text('No run')
            with patch.object(sys,'argv',['analyze',str(path)]), contextlib.redirect_stdout(io.StringIO()), self.assertRaises(SystemExit) as result:
                analyze_benchmark.main()
            self.assertEqual(result.exception.code,2)

    def test_benchmark_regression_fails(self):
        with tempfile.TemporaryDirectory(dir=guard(ROOT/'build')) as tmp:
            path=Path(tmp)/'samples.rpt'
            path.write_text(('\n[HUNCH_BENCH] enabled=false samples=6000 mean_ms=10 p95_ms=12 avg_fps=100\n[HUNCH_BENCH] enabled=true samples=5000 mean_ms=12 p95_ms=14 avg_fps=83.3')*3)
            with patch.object(sys,'argv',['analyze',str(path)]), contextlib.redirect_stdout(io.StringIO()), self.assertRaises(SystemExit) as result:
                analyze_benchmark.main()
            self.assertEqual(result.exception.code,1)

    def test_launcher_pack_has_safe_guards(self):
        source=(ROOT/'launcher/Launch-HUNCH-Pack.ps1').read_text()
        self.assertIn('OneDrive',source)
        self.assertIn('An Arma or map-tools session is already running',source)
        self.assertIn('CBA_A3 was not found',source)
        self.assertIn('Press Preview', (ROOT/'launcher/README.txt').read_text())

if __name__=='__main__': unittest.main()
